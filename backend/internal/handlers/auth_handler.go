package handlers

import (
	"errors"
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"pashuvani/backend/internal/middleware"
	"pashuvani/backend/internal/models"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/internal/services"
	"pashuvani/backend/internal/validators"
	"pashuvani/backend/pkg/response"
)

// AuthHandler serves authentication and user profile endpoints (API_CONTRACTS.md §3).
type AuthHandler struct {
	store   repositories.Store
	authSvc *services.AuthService
}

func NewAuthHandler(store repositories.Store, authSvc *services.AuthService) *AuthHandler {
	return &AuthHandler{store: store, authSvc: authSvc}
}

type registerRequest struct {
	Phone             string  `json:"phone"`
	Password          string  `json:"password"`
	FullName          string  `json:"full_name"`
	PreferredLanguage string  `json:"preferred_language"`
	DistrictID        string  `json:"district_id"`
	TalukaID          string  `json:"taluka_id"`
	VillageID         *string `json:"village_id"`
	ConsentAlerts     *bool   `json:"consent_alerts"`
}

func (h *AuthHandler) Register(c *gin.Context) {
	var req registerRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}

	var details []response.FieldError
	normPhone, ok := validators.NormalizePhone(req.Phone)
	if !ok {
		details = append(details, response.FieldError{Field: "phone", Issue: "invalid_e164_phone"})
	}
	if !validators.ValidatePassword(req.Password) {
		details = append(details, response.FieldError{Field: "password", Issue: "min_length_8"})
	}
	fullName := strings.TrimSpace(req.FullName)
	if len(fullName) < 2 || len(fullName) > 120 {
		details = append(details, response.FieldError{Field: "full_name", Issue: "length_between_2_and_120"})
	}
	if !validators.ValidateUUID(req.DistrictID) {
		details = append(details, response.FieldError{Field: "district_id", Issue: "invalid_uuid"})
	}
	if !validators.ValidateUUID(req.TalukaID) {
		details = append(details, response.FieldError{Field: "taluka_id", Issue: "invalid_uuid"})
	}
	if req.VillageID != nil && *req.VillageID != "" && !validators.ValidateUUID(*req.VillageID) {
		details = append(details, response.FieldError{Field: "village_id", Issue: "invalid_uuid"})
	}
	if len(details) > 0 {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "One or more fields are invalid.", details)
		return
	}

	pwHash, err := h.authSvc.HashPassword(req.Password)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to secure password.", nil)
		return
	}

	consent := true
	if req.ConsentAlerts != nil {
		consent = *req.ConsentAlerts
	}

	user, err := h.store.CreateFarmerUser(c.Request.Context(), repositories.CreateFarmerParams{
		Phone:             normPhone,
		PasswordHash:      pwHash,
		FullName:          fullName,
		PreferredLanguage: validators.ValidateLanguage(req.PreferredLanguage),
		DistrictID:        req.DistrictID,
		TalukaID:          req.TalukaID,
		VillageID:         req.VillageID,
		ConsentAlerts:     consent,
	})
	if err != nil {
		if errors.Is(err, repositories.ErrConflict) {
			response.Error(c, http.StatusConflict, "CONFLICT", "Phone number is already registered.", []response.FieldError{
				{Field: "phone", Issue: "already_registered"},
			})
			return
		}
		if errors.Is(err, repositories.ErrInvalidReference) {
			response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid location reference.", []response.FieldError{
				{Field: "taluka_id", Issue: "location_not_found_or_mismatch"},
			})
			return
		}
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to create farmer account.", nil)
		return
	}

	accessToken, refreshToken, err := h.issueTokenPair(c, user)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to issue tokens.", nil)
		return
	}

	response.Created(c, gin.H{
		"user":          user,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"expires_in":    h.authSvc.AccessTTLSeconds(),
	})
}

type loginRequest struct {
	Phone       string `json:"phone"`
	PhoneNumber string `json:"phone_number"`
	Email       string `json:"email"`
	Password    string `json:"password"`
}

func (h *AuthHandler) Login(c *gin.Context) {
	var req loginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}

	identifier := strings.TrimSpace(req.Phone)
	if identifier == "" {
		identifier = strings.TrimSpace(req.PhoneNumber)
	}
	if identifier == "" {
		identifier = strings.TrimSpace(req.Email)
	}
	if identifier == "" || strings.TrimSpace(req.Password) == "" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Phone/email and password are required.", []response.FieldError{
			{Field: "phone", Issue: "required"},
		})
		return
	}

	if !strings.Contains(identifier, "@") {
		if norm, ok := validators.NormalizePhone(identifier); ok {
			identifier = norm
		}
	}

	user, err := h.store.GetUserByPhoneOrEmail(c.Request.Context(), identifier)
	if err != nil || !h.authSvc.CheckPassword(user.PasswordHash, req.Password) {
		response.Error(c, http.StatusUnauthorized, "INVALID_CREDENTIALS", "Invalid phone/email or password.", nil)
		return
	}

	if !user.IsActive || user.AccountStatus == "disabled" || user.AccountStatus == "rejected" {
		response.Error(c, http.StatusForbidden, "FORBIDDEN", "This account has been disabled or restricted.", nil)
		return
	}

	accessToken, refreshToken, err := h.issueTokenPair(c, user)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to issue session tokens.", nil)
		return
	}

	response.OK(c, gin.H{
		"user":          user,
		"access_token":  accessToken,
		"refresh_token": refreshToken,
		"expires_in":    h.authSvc.AccessTTLSeconds(),
	})
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

func (h *AuthHandler) Refresh(c *gin.Context) {
	var req refreshRequest
	if err := c.ShouldBindJSON(&req); err != nil || strings.TrimSpace(req.RefreshToken) == "" {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "refresh_token is required.", []response.FieldError{
			{Field: "refresh_token", Issue: "required"},
		})
		return
	}

	tokenHash := services.HashToken(strings.TrimSpace(req.RefreshToken))
	userID, err := h.store.ConsumeRefreshToken(c.Request.Context(), tokenHash)
	if err != nil {
		response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "Invalid, expired, or revoked refresh token.", nil)
		return
	}

	user, err := h.store.GetUserByID(c.Request.Context(), userID)
	if err != nil || !user.IsActive {
		response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "User account is no longer active.", nil)
		return
	}

	accessToken, newRefreshToken, err := h.issueTokenPair(c, user)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to rotate tokens.", nil)
		return
	}

	response.OK(c, gin.H{
		"access_token":  accessToken,
		"refresh_token": newRefreshToken,
		"expires_in":    h.authSvc.AccessTTLSeconds(),
	})
}

func (h *AuthHandler) Logout(c *gin.Context) {
	var req refreshRequest
	_ = c.ShouldBindJSON(&req)
	if strings.TrimSpace(req.RefreshToken) != "" {
		tokenHash := services.HashToken(strings.TrimSpace(req.RefreshToken))
		_ = h.store.RevokeRefreshToken(c.Request.Context(), tokenHash)
	}
	c.Status(http.StatusNoContent)
}

func (h *AuthHandler) Me(c *gin.Context) {
	userID := middleware.GetUserID(c)
	user, err := h.store.GetUserByID(c.Request.Context(), userID)
	if err != nil {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "User profile not found.", nil)
		return
	}
	response.OK(c, user)
}

type updateMeRequest struct {
	FullName          *string `json:"full_name"`
	PreferredLanguage *string `json:"preferred_language"`
	VillageID         *string `json:"village_id"`
	ConsentAlerts     *bool   `json:"consent_alerts"`
}

func (h *AuthHandler) UpdateMe(c *gin.Context) {
	userID := middleware.GetUserID(c)
	var req updateMeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		response.Error(c, http.StatusUnprocessableEntity, "VALIDATION_ERROR", "Invalid request body.", nil)
		return
	}
	if req.PreferredLanguage != nil {
		lang := validators.ValidateLanguage(*req.PreferredLanguage)
		req.PreferredLanguage = &lang
	}
	user, err := h.store.UpdateUserMe(c.Request.Context(), userID, req.FullName, req.PreferredLanguage, req.VillageID, req.ConsentAlerts)
	if err != nil {
		response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "Failed to update profile.", nil)
		return
	}
	response.OK(c, user)
}

func (h *AuthHandler) issueTokenPair(c *gin.Context, user *models.UserDTO) (string, string, error) {
	accessToken, err := h.authSvc.GenerateAccessToken(user)
	if err != nil {
		return "", "", err
	}
	rawRefresh, tokenHash, expiresAt, err := h.authSvc.GenerateRefreshToken()
	if err != nil {
		return "", "", err
	}
	if err := h.store.SaveRefreshToken(c.Request.Context(), user.ID, tokenHash, expiresAt); err != nil {
		return "", "", err
	}
	return accessToken, rawRefresh, nil
}
