package response

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// RequestIDKey is the Gin context key for the request correlation ID.
const RequestIDKey = "request_id"

// Meta holds pagination metadata per API_CONTRACTS.md §1.1.
type Meta struct {
	Page     int `json:"page"`
	PageSize int `json:"page_size"`
	Total    int `json:"total"`
}

// FieldError describes a single field validation issue per API_CONTRACTS.md §1.3.
type FieldError struct {
	Field string `json:"field"`
	Issue string `json:"issue"`
}

// ErrorBody matches the canonical error envelope in API_CONTRACTS.md §1.3.
type ErrorBody struct {
	Code      string       `json:"code"`
	Message   string       `json:"message"`
	Details   []FieldError `json:"details"`
	RequestID string       `json:"request_id"`
}

// GetRequestID extracts the request ID from Gin context.
func GetRequestID(c *gin.Context) string {
	if v, ok := c.Get(RequestIDKey); ok {
		if s, ok := v.(string); ok {
			return s
		}
	}
	return "req_unknown"
}

// OK sends a 200 single-resource envelope.
// Includes "success": true alongside "data" so both API_CONTRACTS.md consumers (Flutter)
// and the React Government Dashboard client work seamlessly.
func OK(c *gin.Context, data any) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    data,
	})
}

// Created sends a 201 single-resource envelope.
func Created(c *gin.Context, data any) {
	c.JSON(http.StatusCreated, gin.H{
		"success": true,
		"data":    data,
	})
}

// List sends a 200 paginated list envelope per API_CONTRACTS.md §1.1.
func List(c *gin.Context, data any, page, pageSize, total int) {
	c.JSON(http.StatusOK, gin.H{
		"success": true,
		"data":    data,
		"meta": Meta{
			Page:     page,
			PageSize: pageSize,
			Total:    total,
		},
	})
}

// Error sends a structured error envelope per API_CONTRACTS.md §1.3.
func Error(c *gin.Context, status int, code, message string, details []FieldError) {
	if details == nil {
		details = []FieldError{}
	}
	c.AbortWithStatusJSON(status, gin.H{
		"success": false,
		"error": ErrorBody{
			Code:      code,
			Message:   message,
			Details:   details,
			RequestID: GetRequestID(c),
		},
	})
}
