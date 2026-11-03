package handlers

import (
	"crypto/ed25519"
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"errors"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"pashuvani/backend/internal/middleware"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/internal/validators"
	"pashuvani/backend/pkg/response"
)

// AnimalHandler serves animal registration, clinical records, vaccinations, treatments, and QR payloads (API_CONTRACTS.md §5).
type AnimalHandler struct {
	store     repositories.Store
	qrPrivKey ed25519.PrivateKey
	qrPubKey  ed25519.PublicKey
}

func NewAnimalHandler(store repositories.Store) *AnimalHandler {
	pub, priv, _ := ed25519.GenerateKey(rand.Reader)
	return &AnimalHandler{
		store:     store,
		qrPrivKey: priv,
		qrPubKey:  pub,
	}
}

type createAnimalRequest struct {
	ID              string  `json:"id"`
	SpeciesCode     string  `json:"species_code"`
	BreedCode       *string `json:"breed_code"`
	TagNumber       *string `json:"tag_number"`
	Name            *string `json:"name"`
	Sex             string  `json:"sex"`
	BirthDate       *string `json:"birth_date"`
	ApproxAgeMonths *int16  `json:"approx_age_months"`
	Markings        *string `json:"markings"`
	ClientCreatedAt *string `json:"client_created_at"`
}

func (h *AnimalHandler) Create(c *gin.Context) {
	var req createAnimalRequest
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
	if strings.TrimSpace(req.SpeciesCode) == "" {
		details = append(details, response.FieldError{Field: "species_code", Issue: "required"})
	}
	if len(details) > 0 {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal fields.", details)
		return
	}

	clientCreatedAt := time.Now().UTC()
	if req.ClientCreatedAt != nil && *req.ClientCreatedAt != "" {
		if t, err := time.Parse(time.RFC3339, *req.ClientCreatedAt); err == nil {
			clientCreatedAt = t.UTC()
		}
	}

	farmerID := middleware.GetUserID(c)
	animal, created, err := h.store.CreateOrGetAnimal(c.Request.Context(), repositories.CreateAnimalParams{
		ID:              req.ID,
		FarmerUserID:    farmerID,
		SpeciesCode:     strings.TrimSpace(req.SpeciesCode),
		BreedCode:       req.BreedCode,
		TagNumber:       req.TagNumber,
		Name:            req.Name,
		Sex:             strings.TrimSpace(req.Sex),
		BirthDate:       req.BirthDate,
		ApproxAgeMonths: req.ApproxAgeMonths,
		Markings:        req.Markings,
		ClientCreatedAt: clientCreatedAt,
	})
	if err != nil {
		if errors.Is(err, repositories.ErrForbidden) {
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "Animal ID belongs to another farmer.", nil)
			return
		}
		if errors.Is(err, repositories.ErrInvalidReference) {
			response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Unknown species_code or breed_code.", []response.FieldError{
				{Field: "species_code", Issue: "unknown_reference"},
			})
			return
		}
		if errors.Is(err, repositories.ErrConflict) {
			response.Error(c, http.StatusConflict, "CONFLICT", "Tag number already registered for this farmer.", nil)
			return
		}
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to register animal.", nil)
		return
	}

	if created {
		response.Created(c, animal)
	} else {
		response.OK(c, animal)
	}
}

func (h *AnimalHandler) List(c *gin.Context) {
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "20"))
	if page < 1 {
		page = 1
	}
	if pageSize < 1 || pageSize > 100 {
		pageSize = 20
	}

	farmerID := middleware.GetUserID(c)
	items, total, err := h.store.ListAnimals(c.Request.Context(), farmerID, page, pageSize)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list animals.", nil)
		return
	}
	response.List(c, items, page, pageSize, total)
}

func (h *AnimalHandler) Get(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	animal, err := h.store.GetAnimalByID(c.Request.Context(), animalID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
		return
	}
	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	if role == "farmer" && animal.FarmerUserID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only access your own animals.", nil)
		return
	}
	response.OK(c, animal)
}

type updateAnimalRequest struct {
	Name      *string `json:"name"`
	TagNumber *string `json:"tag_number"`
	Markings  *string `json:"markings"`
	IsActive  *bool   `json:"is_active"`
}

func (h *AnimalHandler) Update(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	existing, err := h.store.GetAnimalByID(c.Request.Context(), animalID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
		return
	}
	if existing.FarmerUserID != middleware.GetUserID(c) {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only modify your own animals.", nil)
		return
	}

	var req updateAnimalRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}
	updated, err := h.store.UpdateAnimal(c.Request.Context(), animalID, req.Name, req.TagNumber, req.Markings, req.IsActive)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update animal.", nil)
		return
	}
	response.OK(c, updated)
}

func (h *AnimalHandler) GetRecord(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	record, err := h.store.GetAnimalRecord(c.Request.Context(), animalID)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
			return
		}
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load animal health record.", nil)
		return
	}
	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	if role == "farmer" && record.Animal.FarmerUserID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only view records of your own animals.", nil)
		return
	}
	response.OK(c, record)
}

func (h *AnimalHandler) GetQRPayload(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	record, err := h.store.GetAnimalRecord(c.Request.Context(), animalID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
		return
	}
	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	if role == "farmer" && record.Animal.FarmerUserID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only generate QR payloads for your own animals.", nil)
		return
	}

	snapshot := gin.H{
		"v":          1,
		"animal_id":  record.Animal.ID,
		"species":    record.Animal.SpeciesCode,
		"breed":      record.Animal.BreedCode,
		"tag":        record.Animal.TagNumber,
		"name":       record.Animal.Name,
		"issued_at":  time.Now().UTC().Format(time.RFC3339),
		"vacc_count": len(record.Vaccinations),
	}
	rawBytes, _ := json.Marshal(snapshot)
	sig := ed25519.Sign(h.qrPrivKey, rawBytes)

	response.OK(c, gin.H{
		"animal_id":  record.Animal.ID,
		"payload":    base64.RawURLEncoding.EncodeToString(rawBytes),
		"signature":  base64.RawURLEncoding.EncodeToString(sig),
		"public_key": base64.RawURLEncoding.EncodeToString(h.qrPubKey),
		"snapshot":   snapshot,
	})
}

type addHealthRecordRequest struct {
	SourceReportID *string        `json:"source_report_id"`
	RecordType     string         `json:"record_type"`
	Summary        string         `json:"summary"`
	WeightKg       *float64       `json:"weight_kg"`
	TemperatureC   *float64       `json:"temperature_c"`
	RecordedAt     *string        `json:"recorded_at"`
	Data           map[string]any `json:"data"`
}

func (h *AnimalHandler) AddHealthRecord(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	animal, err := h.store.GetAnimalByID(c.Request.Context(), animalID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
		return
	}

	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	if role == "farmer" && animal.FarmerUserID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only add health records to your own animals.", nil)
		return
	}

	var req addHealthRecordRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.Summary) == "" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "summary is required.", []response.FieldError{
			{Field: "summary", Issue: "required"},
		})
		return
	}

	// Extract optional temperature_c and weight_kg from nested data map if sent by VetRepository
	if req.Data != nil {
		if req.TemperatureC == nil {
			if v, ok := req.Data["temperature_c"].(float64); ok {
				req.TemperatureC = &v
			}
		}
		if req.WeightKg == nil {
			if v, ok := req.Data["weight_kg"].(float64); ok {
				req.WeightKg = &v
			}
		}
	}

	recordedAt := time.Now().UTC()
	if req.RecordedAt != nil && *req.RecordedAt != "" {
		if t, err := time.Parse(time.RFC3339, *req.RecordedAt); err == nil {
			recordedAt = t.UTC()
		}
	}

	hr, err := h.store.AddHealthRecord(c.Request.Context(), repositories.CreateHealthRecordParams{
		AnimalID:         animalID,
		RecordedByUserID: userID,
		SourceReportID:   req.SourceReportID,
		RecordType:       strings.TrimSpace(req.RecordType),
		Summary:          strings.TrimSpace(req.Summary),
		WeightKg:         req.WeightKg,
		TemperatureC:     req.TemperatureC,
		Data:             req.Data,
		RecordedAt:       recordedAt,
	})
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to save health record.", nil)
		return
	}
	response.Created(c, hr)
}

type addVaccinationRequest struct {
	DiseaseCode    *string `json:"disease_code"`
	VaccineName    string  `json:"vaccine_name"`
	BatchNumber    *string `json:"batch_number"`
	DoseNumber     int16   `json:"dose_number"`
	AdministeredOn string  `json:"administered_on"`
	NextDueOn      *string `json:"next_due_on"`
	Notes          *string `json:"notes"`
}

func (h *AnimalHandler) AddVaccination(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	animal, err := h.store.GetAnimalByID(c.Request.Context(), animalID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
		return
	}

	role := middleware.GetUserRole(c)
	userID := middleware.GetUserID(c)
	if role == "farmer" && animal.FarmerUserID != userID {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "You can only add vaccinations to your own animals.", nil)
		return
	}

	var req addVaccinationRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.VaccineName) == "" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "vaccine_name is required.", []response.FieldError{
			{Field: "vaccine_name", Issue: "required"},
		})
		return
	}
	if req.DoseNumber <= 0 {
		req.DoseNumber = 1
	}
	if strings.TrimSpace(req.AdministeredOn) == "" {
		req.AdministeredOn = time.Now().UTC().Format("2006-01-02")
	}

	vac, err := h.store.AddVaccination(c.Request.Context(), repositories.CreateVaccinationParams{
		AnimalID:             animalID,
		DiseaseCode:          req.DiseaseCode,
		VaccineName:          strings.TrimSpace(req.VaccineName),
		BatchNumber:          req.BatchNumber,
		DoseNumber:           req.DoseNumber,
		AdministeredOn:       req.AdministeredOn,
		NextDueOn:            req.NextDueOn,
		AdministeredByUserID: &userID,
		Notes:                req.Notes,
	})
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to save vaccination record.", nil)
		return
	}
	response.Created(c, vac)
}

type addTreatmentRequest struct {
	ReportID       *string `json:"report_id"`
	MedicationName string  `json:"medication_name"`
	TreatmentName  string  `json:"treatment_name"`
	Dosage         *string `json:"dosage"`
	DurationDays   *int16  `json:"duration_days"`
	Instructions   *string `json:"instructions"`
	Notes          *string `json:"notes"`
	StartedOn      string  `json:"started_on"`
	EndedOn        *string `json:"ended_on"`
	OutcomeNotes   *string `json:"outcome_notes"`
}

func (h *AnimalHandler) AddTreatment(c *gin.Context) {
	animalID := c.Param("id")
	if !validators.ValidateUUID(animalID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid animal UUID.", nil)
		return
	}
	if _, err := h.store.GetAnimalByID(c.Request.Context(), animalID); err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Animal not found.", nil)
		return
	}

	var req addTreatmentRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}

	medName := strings.TrimSpace(req.MedicationName)
	if medName == "" {
		medName = strings.TrimSpace(req.TreatmentName)
	}
	if medName == "" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "medication_name or treatment_name is required.", []response.FieldError{
			{Field: "medication_name", Issue: "required"},
		})
		return
	}

	dosage := "Standard clinical dose"
	if req.Dosage != nil && strings.TrimSpace(*req.Dosage) != "" {
		dosage = strings.TrimSpace(*req.Dosage)
	}
	instructions := req.Instructions
	if instructions == nil {
		instructions = req.Notes
	}
	startedOn := strings.TrimSpace(req.StartedOn)
	if startedOn == "" {
		startedOn = time.Now().UTC().Format("2006-01-02")
	}

	userID := middleware.GetUserID(c)
	trt, err := h.store.AddTreatment(c.Request.Context(), repositories.CreateTreatmentParams{
		AnimalID:          animalID,
		ReportID:          req.ReportID,
		PrescribedByVetID: userID,
		MedicationName:    medName,
		Dosage:            dosage,
		DurationDays:      req.DurationDays,
		Instructions:      instructions,
		StartedOn:         startedOn,
		EndedOn:           req.EndedOn,
		OutcomeNotes:      req.OutcomeNotes,
	})
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to save treatment record.", nil)
		return
	}
	response.Created(c, trt)
}
