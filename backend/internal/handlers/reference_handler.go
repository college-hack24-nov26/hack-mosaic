package handlers

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/pkg/response"
)

// ReferenceHandler serves public reference catalogs (API_CONTRACTS.md §4).
type ReferenceHandler struct {
	store repositories.Store
}

func NewReferenceHandler(store repositories.Store) *ReferenceHandler {
	return &ReferenceHandler{store: store}
}

func (h *ReferenceHandler) Locations(c *gin.Context) {
	level := strings.TrimSpace(c.Query("level"))
	parentID := strings.TrimSpace(c.Query("parent_id"))
	items, err := h.store.GetLocations(c.Request.Context(), level, parentID)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load locations.", nil)
		return
	}
	response.OK(c, items)
}

func (h *ReferenceHandler) Species(c *gin.Context) {
	items, err := h.store.GetSpecies(c.Request.Context())
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load species.", nil)
		return
	}
	response.OK(c, items)
}

func (h *ReferenceHandler) Breeds(c *gin.Context) {
	speciesCode := strings.TrimSpace(c.Query("species_code"))
	items, err := h.store.GetBreeds(c.Request.Context(), speciesCode)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load breeds.", nil)
		return
	}
	response.OK(c, items)
}

func (h *ReferenceHandler) Diseases(c *gin.Context) {
	items, err := h.store.GetDiseases(c.Request.Context())
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load diseases.", nil)
		return
	}
	response.OK(c, items)
}

func (h *ReferenceHandler) Symptoms(c *gin.Context) {
	items, err := h.store.GetSymptoms(c.Request.Context())
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to load symptoms.", nil)
		return
	}
	response.OK(c, items)
}

