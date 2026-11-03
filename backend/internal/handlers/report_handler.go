package handlers

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"pashuvani/backend/internal/config"
	"pashuvani/backend/internal/middleware"
	"pashuvani/backend/internal/models"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/internal/validators"
	"pashuvani/backend/pkg/response"
)

// ReportHandler serves disease report submission, image upload/streaming, and listing (API_CONTRACTS.md §6.1–6.5).
type ReportHandler struct {
	store repositories.Store
	cfg   *config.Config
}

func NewReportHandler(store repositories.Store, cfg *config.Config) *ReportHandler {
	return &ReportHandler{store: store, cfg: cfg}
}

type createReportLocationInput struct {
	Lat       float64  `json:"lat"`
	Lng       float64  `json:"lng"`
	AccuracyM *float64 `json:"accuracy_m"`
}

type createReportScreeningInput struct {
	ModelVersion  string                  `json:"model_version"`
	TopLabel      string                  `json:"top_label"`
	TopConfidence *float64                `json:"top_confidence"`
	Inconclusive  bool                    `json:"inconclusive"`
	Scores        []models.ScreeningScore `json:"scores"`
	RanAt         *string                 `json:"ran_at"`
}

type createReportRequest struct {
	ID                  string                      `json:"id"`
	AnimalID            string                      `json:"animal_id"`
	ReportedAt          *string                     `json:"reported_at"`
	Description         *string                     `json:"description"`
	DescriptionLanguage string                      `json:"description_language"`
	SymptomCodes        []string                    `json:"symptom_codes"`
	Location            *createReportLocationInput  `json:"location"`
	Latitude            *float64                    `json:"latitude"`
	Longitude           *float64                    `json:"longitude"`
	VillageID           *string                     `json:"village_id"`
	ExpectedImageCount  int16                       `json:"expected_image_count"`
	Screening           *createReportScreeningInput `json:"screening"`
}

func (h *ReportHandler) Create(c *gin.Context) {
	var req createReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}

	if strings.TrimSpace(req.ID) == "" {
		req.ID = uuid.NewString()
	}

	var details []response.FieldError
	if !validators.ValidateUUID(req.ID) {
		details = append(details, response.FieldError{Field: "id", Issue: "invalid_uuid"})
	}
	if !validators.ValidateUUID(req.AnimalID) {
		details = append(details, response.FieldError{Field: "animal_id", Issue: "invalid_uuid"})
	}
	if len(req.SymptomCodes) == 0 {
		details = append(details, response.FieldError{Field: "symptom_codes", Issue: "at_least_one_required"})
	}

	var lat, lng, accM *float64
	if req.Location != nil {
		if !validators.ValidateCoordinates(req.Location.Lat, req.Location.Lng) {
			details = append(details, response.FieldError{Field: "location", Issue: "invalid_coordinates"})
		} else {
			lat = &req.Location.Lat
			lng = &req.Location.Lng
			accM = req.Location.AccuracyM
		}
	} else if req.Latitude != nil && req.Longitude != nil {
		if !validators.ValidateCoordinates(*req.Latitude, *req.Longitude) {
			details = append(details, response.FieldError{Field: "latitude", Issue: "invalid_coordinates"})
		} else {
			lat = req.Latitude
			lng = req.Longitude
		}
	}

	if req.Screening != nil && req.Screening.TopConfidence != nil {
		tc := *req.Screening.TopConfidence
		if tc < 0.0 || tc > 1.0 {
			details = append(details, response.FieldError{Field: "screening.top_confidence", Issue: "must_be_between_0_and_1"})
		}
	}

	if len(details) > 0 {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid disease report fields.", details)
		return
	}

	reportedAt := time.Now().UTC()
	if req.ReportedAt != nil && *req.ReportedAt != "" {
		if t, err := time.Parse(time.RFC3339, *req.ReportedAt); err == nil {
			reportedAt = t.UTC()
		}
	}

	var scr *models.ReportScreeningEmbed
	if req.Screening != nil {
		ranAt := reportedAt
		if req.Screening.RanAt != nil && *req.Screening.RanAt != "" {
			if t, err := time.Parse(time.RFC3339, *req.Screening.RanAt); err == nil {
				ranAt = t.UTC()
			}
		}
		scr = &models.ReportScreeningEmbed{
			ModelVersion:  req.Screening.ModelVersion,
			TopLabel:      req.Screening.TopLabel,
			TopConfidence: req.Screening.TopConfidence,
			Inconclusive:  req.Screening.Inconclusive,
			Scores:        req.Screening.Scores,
			RanAt:         ranAt,
			Disclaimer:    "preliminary_screening_not_a_diagnosis",
		}
	}

	reporterID := middleware.GetUserID(c)
	rep, created, err := h.store.CreateOrGetReport(c.Request.Context(), repositories.CreateReportParams{
		ID:                  req.ID,
		AnimalID:            req.AnimalID,
		ReporterUserID:      reporterID,
		ReportedAt:          reportedAt,
		Description:         req.Description,
		DescriptionLanguage: validators.ValidateLanguage(req.DescriptionLanguage),
		SymptomCodes:        req.SymptomCodes,
		Lat:                 lat,
		Lng:                 lng,
		AccuracyM:           accM,
		VillageID:           req.VillageID,
		ExpectedImageCount:  req.ExpectedImageCount,
		Screening:           scr,
	})
	if err != nil {
		if errors.Is(err, repositories.ErrForbidden) {
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only report illness for your own animals.", nil)
			return
		}
		if errors.Is(err, repositories.ErrInvalidReference) {
			response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal_id, symptom_codes, or village_id.", []response.FieldError{
				{Field: "symptom_codes", Issue: "unknown_reference"},
			})
			return
		}
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to save disease report.", nil)
		return
	}

	if created {
		response.Created(c, rep)
	} else {
		response.OK(c, rep)
	}
}

func (h *ReportHandler) UploadImage(c *gin.Context) {
	reportID := c.Param("id")
	if !validators.ValidateUUID(reportID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid report UUID.", nil)
		return
	}

	rep, err := h.store.GetReportByID(c.Request.Context(), reportID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Disease report not found.", nil)
		return
	}

	userID := middleware.GetUserID(c)
	if rep.FarmerID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only upload images to your own disease reports.", nil)
		return
	}

	c.Request.Body = http.MaxBytesReader(c.Writer, c.Request.Body, h.cfg.MaxUploadBytes+1024*64)
	fileHeader, err := c.FormFile("file")
	if err != nil {
		response.Error(c, http.StatusBadRequest, "VALIDATION_ERROR", "Multipart field 'file' is required.", []response.FieldError{
			{Field: "file", Issue: "required"},
		})
		return
	}
	if fileHeader.Size <= 0 || fileHeader.Size > h.cfg.MaxUploadBytes {
		response.Error(c, http.StatusRequestEntityTooLarge, "PAYLOAD_TOO_LARGE", "Image file must be <= 5 MB.", nil)
		return
	}

	imageID := strings.TrimSpace(c.PostForm("id"))
	if imageID == "" {
		imageID = uuid.NewString()
	}
	if !validators.ValidateUUID(imageID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid image id UUID.", []response.FieldError{
			{Field: "id", Issue: "invalid_uuid"},
		})
		return
	}

	src, err := fileHeader.Open()
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to open uploaded file.", nil)
		return
	}
	defer src.Close()

	data, err := io.ReadAll(io.LimitReader(src, h.cfg.MaxUploadBytes+1))
	if err != nil || int64(len(data)) > h.cfg.MaxUploadBytes {
		response.Error(c, http.StatusRequestEntityTooLarge, "PAYLOAD_TOO_LARGE", "Image exceeds maximum size limit (5 MB).", nil)
		return
	}

	mimeType, ext, ok := validators.DetectAllowedImageMime(data)
	if !ok {
		response.Error(c, http.StatusUnsupportedMediaType, "UNSUPPORTED_MEDIA_TYPE", "Only JPEG, PNG, and WebP images are allowed.", nil)
		return
	}

	sum := sha256.Sum256(data)
	shaHex := hex.EncodeToString(sum[:])

	if expSha := strings.TrimSpace(c.PostForm("sha256_hex")); expSha != "" && !strings.EqualFold(expSha, shaHex) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "sha256_hex mismatch.", []response.FieldError{
			{Field: "sha256_hex", Issue: "digest_mismatch"},
		})
		return
	}

	// Safe server-generated storage key (never uses client filename)
	relKey := filepath.Join("reports", reportID, imageID+ext)
	absPath := filepath.Join(h.cfg.UploadDir, relKey)
	if err := os.MkdirAll(filepath.Dir(absPath), 0o755); err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to prepare upload storage.", nil)
		return
	}
	if err := os.WriteFile(absPath, data, 0o644); err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to write uploaded image.", nil)
		return
	}

	var capturedAt *time.Time
	if capStr := strings.TrimSpace(c.PostForm("captured_at")); capStr != "" {
		if t, err := time.Parse(time.RFC3339, capStr); err == nil {
			ut := t.UTC()
			capturedAt = &ut
		}
	}

	savedImg, err := h.store.AddReportImage(c.Request.Context(), models.ReportImageDTO{
		ID:         imageID,
		ReportID:   reportID,
		StorageKey: relKey,
		MimeType:   mimeType,
		ByteSize:   len(data),
		Sha256Hex:  shaHex,
		CapturedAt: capturedAt,
	})
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to record uploaded image.", nil)
		return
	}
	response.Created(c, savedImg)
}

func (h *ReportHandler) GetImage(c *gin.Context) {
	reportID := c.Param("id")
	imageID := c.Param("image_id")
	if !validators.ValidateUUID(reportID) || !validators.ValidateUUID(imageID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid report or image UUID.", nil)
		return
	}

	rep, err := h.store.GetReportByID(c.Request.Context(), reportID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Report not found.", nil)
		return
	}

	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	if role == "farmer" && rep.FarmerID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "Access denied to this report image.", nil)
		return
	}

	img, err := h.store.GetReportImage(c.Request.Context(), reportID, imageID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Report image not found.", nil)
		return
	}

	absPath := filepath.Join(h.cfg.UploadDir, img.StorageKey)
	c.Header("Content-Type", img.MimeType)
	c.File(absPath)
}

func (h *ReportHandler) List(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	scopeID := middleware.GetUserScopeID(c)

	filter := repositories.ReportFilter{
		Status:      strings.TrimSpace(c.Query("status")),
		TalukaID:    strings.TrimSpace(c.Query("taluka_id")),
		DistrictID:  strings.TrimSpace(c.Query("district_id")),
		DiseaseCode: strings.TrimSpace(c.Query("disease_code")),
		Page:        page,
		PageSize:    pageSize,
	}
	if filter.DistrictID == "" {
		filter.DistrictID = strings.TrimSpace(c.Query("district"))
	}

	// Enforce role-based scoping per API_CONTRACTS.md §6.3
	switch role {
	case "farmer":
		filter.ReporterUserID = userID
	case "vet":
		if !middleware.GetUserVerified(c) {
			response.Error(c, http.StatusForbidden, "VET_NOT_VERIFIED", "Veterinarian account is pending verification.", nil)
			return
		}
		if scopeID != "" {
			filter.DistrictID = scopeID
		}
	case "officer":
		if scopeID != "" && filter.DistrictID == "" {
			filter.DistrictID = scopeID
		}
	}

	items, total, err := h.store.ListReports(c.Request.Context(), filter)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list disease reports.", nil)
		return
	}
	response.List(c, items, page, pageSize, total)
}

func (h *ReportHandler) Get(c *gin.Context) {
	reportID := c.Param("id")
	if !validators.ValidateUUID(reportID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid report UUID.", nil)
		return
	}

	rep, err := h.store.GetReportByID(c.Request.Context(), reportID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Disease report not found.", nil)
		return
	}

	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	scopeID := middleware.GetUserScopeID(c)

	if role == "farmer" && rep.FarmerID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only view your own disease reports.", nil)
		return
	}
	if role == "vet" {
		if !middleware.GetUserVerified(c) {
			response.Error(c, http.StatusForbidden, "VET_NOT_VERIFIED", "Veterinarian account is pending verification.", nil)
			return
		}
		if scopeID != "" && rep.DistrictID != scopeID {
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "Report is outside your assigned district.", nil)
			return
		}
	}

	response.OK(c, rep)
}

