package validators

import (
	"bytes"
	"regexp"
	"strings"

	"github.com/google/uuid"
)

var (
	e164Regex     = regexp.MustCompile(`^\+91[6-9]\d{9}$`)
	tenDigitRegex = regexp.MustCompile(`^[6-9]\d{9}$`)
)

// NormalizePhone normalizes Indian mobile numbers to E.164 (+91XXXXXXXXXX).
// Returns the normalized phone and true if valid.
func NormalizePhone(raw string) (string, bool) {
	cleaned := strings.ReplaceAll(strings.TrimSpace(raw), " ", "")
	cleaned = strings.ReplaceAll(cleaned, "-", "")
	if e164Regex.MatchString(cleaned) {
		return cleaned, true
	}
	if tenDigitRegex.MatchString(cleaned) {
		return "+91" + cleaned, true
	}
	if strings.HasPrefix(cleaned, "91") && len(cleaned) == 12 && tenDigitRegex.MatchString(cleaned[2:]) {
		return "+" + cleaned, true
	}
	return raw, false
}

// ValidatePassword checks minimum password requirements per API_CONTRACTS.md §3.1 (>= 8 chars).
func ValidatePassword(pw string) bool {
	return len(strings.TrimSpace(pw)) >= 8
}

// ValidateUUID checks if s is a valid UUID string.
func ValidateUUID(s string) bool {
	_, err := uuid.Parse(strings.TrimSpace(s))
	return err == nil
}

// ValidateCoordinates checks latitude and longitude bounds.
func ValidateCoordinates(lat, lng float64) bool {
	return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0
}

// ValidateLanguage checks if lang is one of en, hi, mr.
func ValidateLanguage(lang string) string {
	switch strings.ToLower(strings.TrimSpace(lang)) {
	case "en", "hi", "mr":
		return strings.ToLower(strings.TrimSpace(lang))
	default:
		return "mr"
	}
}

// DetectAllowedImageMime inspects magic bytes of an uploaded file and returns
// the canonical MIME type ("image/jpeg", "image/png", "image/webp") or empty string if disallowed.
func DetectAllowedImageMime(header []byte) (mimeType string, ext string, ok bool) {
	if len(header) >= 3 && header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF {
		return "image/jpeg", ".jpg", true
	}
	if len(header) >= 8 && bytes.Equal(header[:8], []byte{0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A}) {
		return "image/png", ".png", true
	}
	if len(header) >= 12 && bytes.Equal(header[:4], []byte("RIFF")) && bytes.Equal(header[8:12], []byte("WEBP")) {
		return "image/webp", ".webp", true
	}
	return "", "", false
}

