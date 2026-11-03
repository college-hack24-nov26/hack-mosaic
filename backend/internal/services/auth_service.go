package services

import (
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"pashuvani/backend/internal/models"
)

const bcryptCost = 10

// Claims represents the JWT access token claims per SECURITY.md §2.
type Claims struct {
	UserID        string `json:"sub"`
	Role          string `json:"role"`
	ScopeID       string `json:"scope_id,omitempty"`
	IsVerified    bool   `json:"is_verified"`
	AccountStatus string `json:"account_status"`
	jwt.RegisteredClaims
}

// AuthService manages bcrypt password hashing and JWT / Refresh tokens.
type AuthService struct {
	jwtSecret  []byte
	accessTTL  time.Duration
	refreshTTL time.Duration
}

// NewAuthService creates a new AuthService.
func NewAuthService(secret string, accessTTLSeconds, refreshTTLSeconds int) *AuthService {
	if accessTTLSeconds <= 0 {
		accessTTLSeconds = 3600
	}
	if refreshTTLSeconds <= 0 {
		refreshTTLSeconds = 2592000
	}
	return &AuthService{
		jwtSecret:  []byte(secret),
		accessTTL:  time.Duration(accessTTLSeconds) * time.Second,
		refreshTTL: time.Duration(refreshTTLSeconds) * time.Second,
	}
}

// AccessTTLSeconds returns the configured access token TTL in seconds.
func (s *AuthService) AccessTTLSeconds() int {
	return int(s.accessTTL.Seconds())
}

// RefreshTTLDuration returns the configured refresh token TTL duration.
func (s *AuthService) RefreshTTLDuration() time.Duration {
	return s.refreshTTL
}

// HashPassword hashes a plaintext password with bcrypt cost 10.
func (s *AuthService) HashPassword(password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcryptCost)
	if err != nil {
		return "", err
	}
	return string(hash), nil
}

// CheckPassword compares a bcrypt hash with a plaintext candidate.
func (s *AuthService) CheckPassword(hash, password string) bool {
	return bcrypt.CompareHashAndPassword([]byte(hash), []byte(password)) == nil
}

// GenerateAccessToken signs a new JWT access token for a user.
func (s *AuthService) GenerateAccessToken(u *models.UserDTO) (string, error) {
	now := time.Now().UTC()
	scopeID := ""
	isVerified := true

	if u.Profile != nil {
		if u.Profile.Farmer != nil {
			scopeID = u.Profile.Farmer.DistrictID
		} else if u.Profile.Vet != nil {
			scopeID = u.Profile.Vet.DistrictID
			isVerified = u.Profile.Vet.IsVerified
		} else if u.Profile.Officer != nil {
			scopeID = u.Profile.Officer.ScopeLocationID
		}
	}

	claims := Claims{
		UserID:        u.ID,
		Role:          u.Role,
		ScopeID:       scopeID,
		IsVerified:    isVerified,
		AccountStatus: u.AccountStatus,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   u.ID,
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(now.Add(s.accessTTL)),
			Issuer:    "pashuvani-api",
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString(s.jwtSecret)
}

// ValidateAccessToken verifies and parses a JWT access token.
func (s *AuthService) ValidateAccessToken(tokenString string) (*Claims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (any, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return s.jwtSecret, nil
	})
	if err != nil {
		return nil, err
	}
	claims, ok := token.Claims.(*Claims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token claims")
	}
	return claims, nil
}

// GenerateRefreshToken produces a random opaque token and its SHA-256 hex digest.
func (s *AuthService) GenerateRefreshToken() (rawToken string, tokenHash string, expiresAt time.Time, err error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", "", time.Time{}, err
	}
	rawToken = "rt_" + hex.EncodeToString(buf)
	tokenHash = HashToken(rawToken)
	expiresAt = time.Now().UTC().Add(s.refreshTTL)
	return rawToken, tokenHash, expiresAt, nil
}

// HashToken returns the SHA-256 hex digest of an opaque token.
func HashToken(raw string) string {
	sum := sha256.Sum256([]byte(raw))
	return hex.EncodeToString(sum[:])
}

