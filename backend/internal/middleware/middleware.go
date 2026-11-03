package middleware

import (
	"log/slog"
	"net/http"
	"strings"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"pashuvani/backend/pkg/response"
)

// RequestID attaches or propagates X-Request-Id per API_CONTRACTS.md §1.5.
func RequestID() gin.HandlerFunc {
	return func(c *gin.Context) {
		reqID := strings.TrimSpace(c.GetHeader("X-Request-Id"))
		if reqID == "" {
			reqID = "req_" + strings.ReplaceAll(uuid.NewString()[:12], "-", "")
		}
		c.Set(response.RequestIDKey, reqID)
		c.Header("X-Request-Id", reqID)
		c.Next()
	}
}

// StructuredLogger logs every HTTP request as structured JSON via slog without leaking secrets.
func StructuredLogger() gin.HandlerFunc {
	return func(c *gin.Context) {
		start := time.Now()
		path := c.Request.URL.Path
		query := c.Request.URL.RawQuery

		c.Next()

		latency := time.Since(start)
		status := c.Writer.Status()
		reqID := response.GetRequestID(c)

		attrs := []any{
			slog.String("request_id", reqID),
			slog.String("method", c.Request.Method),
			slog.String("path", path),
			slog.Int("status", status),
			slog.Duration("latency_ms", latency),
			slog.String("client_ip", c.ClientIP()),
		}
		if query != "" {
			attrs = append(attrs, slog.String("query", query))
		}
		if userID, ok := c.Get(ContextUserIDKey); ok {
			attrs = append(attrs, slog.Any("user_id", userID))
		}

		if status >= 500 {
			slog.Error("http_request", attrs...)
		} else if status >= 400 {
			slog.Warn("http_request", attrs...)
		} else {
			slog.Info("http_request", attrs...)
		}
	}
}

// Recovery catches panics and returns a canonical 500 INTERNAL_ERROR JSON response.
func Recovery() gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if rec := recover(); rec != nil {
				slog.Error("panic_recovered",
					slog.String("request_id", response.GetRequestID(c)),
					slog.Any("panic", rec),
				)
				response.Error(c, http.StatusInternalServerError, "INTERNAL_ERROR", "An unexpected internal error occurred.", nil)
			}
		}()
		c.Next()
	}
}

// CORS configures Cross-Origin Resource Sharing for Soham's React Government Dashboard and local clients.
func CORS(allowedOrigins []string) gin.HandlerFunc {
	allowAll := false
	originMap := make(map[string]bool, len(allowedOrigins))
	for _, o := range allowedOrigins {
		if o == "*" {
			allowAll = true
		}
		originMap[o] = true
	}

	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if origin != "" && (allowAll || originMap[origin]) {
			c.Header("Access-Control-Allow-Origin", origin)
		} else if allowAll {
			c.Header("Access-Control-Allow-Origin", "*")
		}
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Origin, Content-Type, Accept, Authorization, X-Request-Id, Idempotency-Key")
		c.Header("Access-Control-Expose-Headers", "X-Request-Id")
		c.Header("Access-Control-Allow-Credentials", "true")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}
