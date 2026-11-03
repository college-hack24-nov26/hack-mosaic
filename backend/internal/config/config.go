package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

// Config holds all environment-driven configuration for the PashuVani backend.
type Config struct {
	Env               string
	Port              string
	LogLevel          string
	CORSOrigins       []string
	JWTSecret         string
	AccessTTLSeconds  int
	RefreshTTLSeconds int
	DatabaseURL       string
	DBDriver          string // "postgres" (default) or "memory"
	MaxOpenConns      int32
	UploadDir         string
	MaxUploadBytes    int64
	MigrationsDir     string
	AutoMigrate       bool
	AutoSeed          bool
	MLServiceURL      string
}

// Load reads environment variables with sensible defaults for local development.
func Load() *Config {
	env := getEnv("ENV", "development")
	port := getEnv("PORT", "8080")
	logLevel := getEnv("LOG_LEVEL", "info")

	corsRaw := getEnv("CORS_ALLOWED_ORIGINS", "http://localhost:3000,http://localhost:5173,http://127.0.0.1:5173,http://127.0.0.1:3000,*")
	var origins []string
	for _, o := range strings.Split(corsRaw, ",") {
		trimmed := strings.TrimSpace(o)
		if trimmed != "" {
			origins = append(origins, trimmed)
		}
	}

	jwtSecret := getEnv("JWT_SECRET", "pashuvani-dev-jwt-secret-key-2026-change-in-production")
	accessTTL := getEnvInt("JWT_ACCESS_TTL_SECONDS", 3600)
	refreshTTL := getEnvInt("JWT_REFRESH_TTL_SECONDS", 2592000)

	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbHost := getEnv("DB_HOST", "localhost")
		dbPort := getEnv("DB_PORT", "5432")
		dbUser := getEnv("DB_USER", "pashuvani")
		dbPass := getEnv("DB_PASSWORD", "pashuvani_password")
		dbName := getEnv("DB_NAME", "pashuvani_db")
		dbSSL := getEnv("DB_SSLMODE", "disable")
		dbURL = fmt.Sprintf("postgres://%s:%s@%s:%s/%s?sslmode=%s", dbUser, dbPass, dbHost, dbPort, dbName, dbSSL)
	}

	return &Config{
		Env:               env,
		Port:              port,
		LogLevel:          logLevel,
		CORSOrigins:       origins,
		JWTSecret:         jwtSecret,
		AccessTTLSeconds:  accessTTL,
		RefreshTTLSeconds: refreshTTL,
		DatabaseURL:       dbURL,
		DBDriver:          getEnv("DB_DRIVER", "postgres"),
		MaxOpenConns:      int32(getEnvInt("DB_MAX_OPEN_CONNS", 25)),
		UploadDir:         getEnv("STORAGE_LOCAL_DIR", "./data/uploads"),
		MaxUploadBytes:    int64(getEnvInt("STORAGE_MAX_UPLOAD_SIZE_BYTES", 5242880)),
		MigrationsDir:     getEnv("MIGRATIONS_DIR", "./migrations"),
		AutoMigrate:       getEnvBool("AUTO_MIGRATE", true),
		AutoSeed:          getEnvBool("AUTO_SEED", true),
		MLServiceURL:      getEnv("ML_SERVICE_URL", "http://localhost:8001"),
	}
}

func getEnv(key, fallback string) string {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		return v
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return fallback
}

func getEnvBool(key string, fallback bool) bool {
	if v := strings.TrimSpace(os.Getenv(key)); v != "" {
		if b, err := strconv.ParseBool(v); err == nil {
			return b
		}
	}
	return fallback
}
