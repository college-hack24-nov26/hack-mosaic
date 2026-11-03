package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"pashuvani/backend/internal/services"
	"pashuvani/backend/pkg/response"
)

const (
	ContextUserIDKey        = "auth_user_id"
	ContextUserRoleKey      = "auth_user_role"
	ContextUserScopeIDKey   = "auth_user_scope_id"
	ContextUserVerifiedKey  = "auth_user_is_verified"
	ContextAccountStatusKey = "auth_account_status"
)

// RequireAuth validates the Bearer JWT token on protected routes.
func RequireAuth(authSvc *services.AuthService) gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := strings.TrimSpace(c.GetHeader("Authorization"))
		if authHeader == "" || !strings.HasPrefix(strings.ToLower(authHeader), "bearer ") {
			response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "Missing or invalid Authorization header.", nil)
			return
		}
		rawToken := strings.TrimSpace(authHeader[7:])
		if rawToken == "" {
			response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "Missing bearer token.", nil)
			return
		}

		claims, err := authSvc.ValidateAccessToken(rawToken)
		if err != nil {
			response.Error(c, http.StatusUnauthorized, "UNAUTHORIZED", "Invalid or expired access token.", nil)
			return
		}

		if claims.AccountStatus == "disabled" || claims.AccountStatus == "rejected" {
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "Account access is restricted.", nil)
			return
		}

		c.Set(ContextUserIDKey, claims.UserID)
		c.Set(ContextUserRoleKey, claims.Role)
		c.Set(ContextUserScopeIDKey, claims.ScopeID)
		c.Set(ContextUserVerifiedKey, claims.IsVerified)
		c.Set(ContextAccountStatusKey, claims.AccountStatus)
		c.Next()
	}
}

// RequireRoles restricts an endpoint to specific user roles.
// If the user is a veterinarian ("vet"), it also enforces that their account is verified (is_verified == true).
func RequireRoles(allowedRoles ...string) gin.HandlerFunc {
	allowed := make(map[string]bool, len(allowedRoles))
	for _, r := range allowedRoles {
		allowed[r] = true
	}

	return func(c *gin.Context) {
		role := GetUserRole(c)
		if !allowed[role] {
			response.Error(c, http.StatusForbidden, "FORBIDDEN", "Insufficient role permissions for this action.", nil)
			return
		}
		if role == "vet" && !GetUserVerified(c) {
			response.Error(c, http.StatusForbidden, "VET_NOT_VERIFIED", "Veterinarian account is pending verification.", nil)
			return
		}
		c.Next()
	}
}

// GetUserID returns the authenticated user ID from Gin context.
func GetUserID(c *gin.Context) string {
	v, _ := c.Get(ContextUserIDKey)
	s, _ := v.(string)
	return s
}

// GetUserRole returns the authenticated user role from Gin context.
func GetUserRole(c *gin.Context) string {
	v, _ := c.Get(ContextUserRoleKey)
	s, _ := v.(string)
	return s
}

// GetUserScopeID returns the authenticated user's district/scope location ID.
func GetUserScopeID(c *gin.Context) string {
	v, _ := c.Get(ContextUserScopeIDKey)
	s, _ := v.(string)
	return s
}

// GetUserVerified returns whether the authenticated user (e.g., vet) is verified.
func GetUserVerified(c *gin.Context) bool {
	v, ok := c.Get(ContextUserVerifiedKey)
	if !ok {
		return false
	}
	b, _ := v.(bool)
	return b
}
