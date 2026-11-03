package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"strings"

	"github.com/gin-gonic/gin"
	"pashuvani/backend/internal/middleware"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/internal/validators"
	"pashuvani/backend/pkg/response"
)

// VetHandler serves veterinarian claim, clinical verification, and nearby veterinarian queries.
type VetHandler struct {
	store repositories.Store
}

func NewVetHandler(store repositories.Store) *VetHandler {
	return &VetHandler{store: store}
}

func (h *VetHandler) ClaimReport(c *gin.Context) {
	reportID := c.Param("id")
	if !validators.ValidateUUID(reportID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid report UUID.", nil)
		return
	}

	userID := middleware.GetUserID(c)
	role := middleware.GetUserRole(c)
	scopeID := middleware.GetUserScopeID(c)

	rep, err := h.store.ClaimReport(c.Request.Context(), reportID, userID, scopeID, role == "admin")
	if err != nil {
		switch {
		case errors.Is(err, repositories.ErrNotFound):
			response.Error(c, http.StatusNotFound, "NOT_FOUND", "Disease report not found.", nil)
		case errors.Is(err, repositories.ErrForbidden):
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "Report is outside your assigned district.", nil)
		case errors.Is(err, repositories.ErrAlreadyDecided):
			response.Error(c, http.StatusConflict, "REPORT_ALREADY_DECIDED", "Report has already been verified.", nil)
		default:
			response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to claim report.", nil)
		}
		return
	}
	response.OK(c, rep)
}

type verifyReportRequest struct {
	Decision      string  `json:"decision"`
	DiseaseCode   *string `json:"disease_code"`
	Notes         *string `json:"notes"`
	VisitRequired bool    `json:"visit_required"`
}

func (h *VetHandler) VerifyReport(c *gin.Context) {
	reportID := c.Param("id")
	if !validators.ValidateUUID(reportID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid report UUID.", nil)
		return
	}

	var req verifyReportRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}

	decision := strings.ToLower(strings.TrimSpace(req.Decision))
	var details []response.FieldError
	if decision != "confirmed" && decision != "rejected" && decision != "flagged" {
		details = append(details, response.FieldError{Field: "decision", Issue: "must_be_confirmed_rejected_or_flagged"})
	}
	if decision == "confirmed" && (req.DiseaseCode == nil || strings.TrimSpace(*req.DiseaseCode) == "") {
		details = append(details, response.FieldError{Field: "disease_code", Issue: "required_when_confirmed"})
	}
	if len(details) > 0 {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid verification payload.", details)
		return
	}

	userID := middleware.GetUserID(c)
	role := middleware.GetUserRole(c)
	scopeID := middleware.GetUserScopeID(c)

	rep, err := h.store.VerifyReport(c.Request.Context(), repositories.VerifyReportParams{
		ReportID:      reportID,
		VetUserID:     userID,
		VetDistrictID: scopeID,
		IsAdmin:       role == "admin",
		Decision:      decision,
		DiseaseCode:   req.DiseaseCode,
		Notes:         req.Notes,
		VisitRequired: req.VisitRequired,
	})
	if err != nil {
		switch {
		case errors.Is(err, repositories.ErrNotFound):
			response.Error(c, http.StatusNotFound, "NOT_FOUND", "Disease report not found.", nil)
		case errors.Is(err, repositories.ErrForbidden):
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "Report is outside your assigned district.", nil)
		case errors.Is(err, repositories.ErrInvalidReference):
			response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Unknown disease_code.", []response.FieldError{
				{Field: "disease_code", Issue: "unknown_disease_code"},
			})
		default:
			response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to record verification.", nil)
		}
		return
	}

	response.Created(c, rep)
}

func (h *VetHandler) NearbyVeterinarians(c *gin.Context) {
	lat, errLat := strconv.ParseFloat(c.DefaultQuery("lat", "17.9856"), 64)
	lng, errLng := strconv.ParseFloat(c.DefaultQuery("lng", "74.4331"), 64)
	radiusKm, errRad := strconv.ParseFloat(c.DefaultQuery("radius_km", "50"), 64)

	if errLat != nil || errLng != nil || !validators.ValidateCoordinates(lat, lng) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Valid lat and lng query parameters are required.", nil)
		return
	}
	if errRad != nil || radiusKm <= 0 || radiusKm > 500 {
		radiusKm = 50.0
	}

	vets, err := h.store.GetNearbyVeterinarians(c.Request.Context(), lat, lng, radiusKm)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to query nearby veterinarians.", nil)
		return
	}
	response.OK(c, vets)
}

