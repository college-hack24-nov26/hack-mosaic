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

// DashboardHandler serves surveillance analytics, GeoJSON case maps, outbreaks, alerts, and notifications (API_CONTRACTS.md §7–§8).
type DashboardHandler struct {
	store repositories.Store
}

func NewDashboardHandler(store repositories.Store) *DashboardHandler {
	return &DashboardHandler{store: store}
}

func (h *DashboardHandler) Summary(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district_id"))
	if districtID == "" {
		districtID = strings.TrimSpace(c.Query("district"))
	}
	summary, err := h.store.GetDashboardSummary(c.Request.Context(), districtID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to compute dashboard summary.", nil)
		return
	}
	response.OK(c, summary)
}

func (h *DashboardHandler) Timeseries(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district_id"))
	days, _ := strconv.Atoi(c.DefaultQuery("days", "14"))
	series, err := h.store.GetDashboardTimeseries(c.Request.Context(), districtID, days)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to compute timeseries.", nil)
		return
	}
	response.OK(c, gin.H{
		"bucket": "day",
		"series": series,
	})
}

// MapCases returns a GeoJSON FeatureCollection of veterinarian-confirmed cases ONLY (API_CONTRACTS.md §7.3).
// Per API_CONTRACTS.md §1.2, GeoJSON is returned directly at top-level (not wrapped in "data").
func (h *DashboardHandler) MapCases(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district_id"))
	if districtID == "" {
		districtID = strings.TrimSpace(c.Query("district"))
	}
	diseaseCode := strings.TrimSpace(c.Query("disease_code"))

	features, err := h.store.GetConfirmedMapCases(c.Request.Context(), districtID, diseaseCode)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load confirmed case map.", nil)
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"type":     "FeatureCollection",
		"features": features,
		"meta": gin.H{
			"count":     len(features),
			"truncated": len(features) >= 1000,
		},
	})
}

// MapPins serves GET /api/v1/dashboard/map-data for Soham's React Government Dashboard.
func (h *DashboardHandler) MapPins(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district"))
	diseaseCode := strings.TrimSpace(c.Query("disease_code"))
	features, err := h.store.GetConfirmedMapCases(c.Request.Context(), districtID, diseaseCode)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load map pins.", nil)
		return
	}
	var pins []any
	for _, f := range features {
		if props, ok := f["properties"]; ok {
			pins = append(pins, props)
		}
	}
	if pins == nil {
		pins = []any{}
	}
	response.OK(c, pins)
}

func (h *DashboardHandler) ListOutbreaks(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district_id"))
	status := strings.TrimSpace(c.Query("status"))
	outbreaks, err := h.store.ListOutbreaks(c.Request.Context(), districtID, status)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list outbreaks.", nil)
		return
	}
	response.List(c, outbreaks, 1, 50, len(outbreaks))
}

func (h *DashboardHandler) GetOutbreak(c *gin.Context) {
	id := c.Param("id")
	if !validators.ValidateUUID(id) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid outbreak UUID.", nil)
		return
	}
	ob, err := h.store.GetOutbreakByID(c.Request.Context(), id)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Outbreak not found.", nil)
		return
	}
	response.OK(c, ob)
}

type updateOutbreakRequest struct {
	Status string `json:"status"`
}

func (h *DashboardHandler) UpdateOutbreak(c *gin.Context) {
	id := c.Param("id")
	var req updateOutbreakRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}
	st := strings.TrimSpace(req.Status)
	if st != "active" && st != "monitoring" && st != "resolved" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "status must be active, monitoring, or resolved.", nil)
		return
	}
	ob, err := h.store.UpdateOutbreakStatus(c.Request.Context(), id, st)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Outbreak not found.", nil)
		return
	}
	response.OK(c, ob)
}

func (h *DashboardHandler) RecomputeOutbreaks(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district_id"))
	outbreaks, err := h.store.RecomputeOutbreaks(c.Request.Context(), districtID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to recompute outbreaks.", nil)
		return
	}
	response.OK(c, outbreaks)
}

func (h *DashboardHandler) ListAlerts(c *gin.Context) {
	districtID := strings.TrimSpace(c.Query("district"))
	alerts, err := h.store.ListAlerts(c.Request.Context(), districtID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list alerts.", nil)
		return
	}
	response.List(c, alerts, 1, 50, len(alerts))
}

type createAlertRequest struct {
	OutbreakID       string `json:"outbreak_id"`
	RadiusM          int    `json:"radius_m"`
	TitleEn          string `json:"title_en"`
	TitleHi          string `json:"title_hi"`
	TitleMr          string `json:"title_mr"`
	BodyEn           string `json:"body_en"`
	BodyHi           string `json:"body_hi"`
	BodyMr           string `json:"body_mr"`
	Title            string `json:"title"`
	Message          string `json:"message"`
	Severity         string `json:"severity"`
	AffectedDistrict string `json:"affected_district"`
	DiseaseName      string `json:"disease_name"`
}

func (h *DashboardHandler) CreateAlert(c *gin.Context) {
	var req createAlertRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}

	titleEn := strings.TrimSpace(req.TitleEn)
	if titleEn == "" {
		titleEn = strings.TrimSpace(req.Title)
	}
	titleMr := strings.TrimSpace(req.TitleMr)
	if titleMr == "" {
		titleMr = titleEn
	}
	bodyEn := strings.TrimSpace(req.BodyEn)
	if bodyEn == "" {
		bodyEn = strings.TrimSpace(req.Message)
	}
	bodyMr := strings.TrimSpace(req.BodyMr)
	if bodyMr == "" {
		bodyMr = bodyEn
	}

	if titleMr == "" || bodyMr == "" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "title_mr and body_mr are required.", nil)
		return
	}

	// Ensure product safety requirement: alerts must state they are based on veterinarian-confirmed cases
	if !strings.Contains(strings.ToLower(bodyEn), "veterinarian-confirmed") && !strings.Contains(bodyEn, "पशुवैद्यक") {
		bodyEn = bodyEn + " (Based on veterinarian-confirmed cases.)"
	}

	outbreakID := strings.TrimSpace(req.OutbreakID)
	if outbreakID == "" {
		outbreakID = "55555555-5555-4555-8555-555555555001"
	}
	severity := strings.TrimSpace(req.Severity)
	if severity == "" {
		severity = "high"
	}
	dist := strings.TrimSpace(req.AffectedDistrict)
	if dist == "" {
		dist = "Satara"
	}
	dis := strings.TrimSpace(req.DiseaseName)
	if dis == "" {
		dis = "Lumpy Skin Disease (LSD)"
	}

	al, err := h.store.CreateAlert(c.Request.Context(), repositories.CreateAlertParams{
		OutbreakID:       outbreakID,
		ApprovedByUserID: middleware.GetUserID(c),
		RadiusM:          req.RadiusM,
		TitleEn:          titleEn,
		TitleHi:          req.TitleHi,
		TitleMr:          titleMr,
		BodyEn:           bodyEn,
		BodyHi:           req.BodyHi,
		BodyMr:           bodyMr,
		Severity:         severity,
		AffectedDistrict: dist,
		DiseaseName:      dis,
		SendNow:          req.Title != "", // Dashboard Broadcast modal expects immediate active alert
	})
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to create alert.", nil)
		return
	}
	response.Created(c, al)
}

func (h *DashboardHandler) SendAlert(c *gin.Context) {
	alertID := c.Param("id")
	if !validators.ValidateUUID(alertID) {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid alert UUID.", nil)
		return
	}
	al, err := h.store.SendAlert(c.Request.Context(), alertID)
	if err != nil {
		if errors.Is(err, repositories.ErrNotFound) {
			response.Error(c, http.StatusNotFound, "NOT_FOUND", "Alert not found.", nil)
			return
		}
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to send alert.", nil)
		return
	}
	response.OK(c, al)
}

func (h *DashboardHandler) ListNotifications(c *gin.Context) {
	userID := middleware.GetUserID(c)
	items, err := h.store.ListNotifications(c.Request.Context(), userID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to list notifications.", nil)
		return
	}
	response.List(c, items, 1, 50, len(items))
}

func (h *DashboardHandler) MarkNotificationRead(c *gin.Context) {
	userID := middleware.GetUserID(c)
	notifID := c.Param("id")
	if err := h.store.MarkNotificationRead(c.Request.Context(), userID, notifID); err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Notification not found.", nil)
		return
	}
	c.Status(http.StatusNoContent)
}
