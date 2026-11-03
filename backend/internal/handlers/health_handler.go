package handlers

import (
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/pkg/response"
)

// HealthHandler serves GET /health and GET /api/v1/healthz.
type HealthHandler struct {
	store repositories.Store
}

func NewHealthHandler(store repositories.Store) *HealthHandler {
	return &HealthHandler{store: store}
}

func (h *HealthHandler) Check(c *gin.Context) {
	dbOK, postgisOK, driver, err := h.store.Ping(c.Request.Context())
	if err != nil || !dbOK {
		response.Error(c, http.StatusServiceUnavailable, "SERVICE_UNAVAILABLE", "Database connection failed.", nil)
		return
	}

	response.OK(c, gin.H{
		"status":  "ok",
		"service": "pashuvani-api",
		"version": "1.0.0",
		"driver":  driver,
		"db":      "ok",
		"postgis": map[bool]string{true: "ok", false: "unavailable"}[postgisOK],
		"time":    time.Now().UTC().Format(time.RFC3339),
	})
}

