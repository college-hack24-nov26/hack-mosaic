package database

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"pashuvani/backend/internal/config"
	"pashuvani/backend/internal/repositories"
)

// Connect initializes the database store (PostgreSQL 16 + PostGIS or InMemoryStore fallback).
func Connect(ctx context.Context, cfg *config.Config) (repositories.Store, func(), error) {
	if cfg.DBDriver == "memory" {
		slog.Info("database_initialized", slog.String("driver", "memory"))
		return repositories.NewInMemoryStore(), func() {}, nil
	}

	poolCfg, err := pgxpool.ParseConfig(cfg.DatabaseURL)
	if err != nil {
		return nil, nil, fmt.Errorf("parse database url: %w", err)
	}
	if cfg.MaxOpenConns > 0 {
		poolCfg.MaxConns = cfg.MaxOpenConns
	}
	poolCfg.MaxConnLifetime = 30 * time.Minute
	poolCfg.MaxConnIdleTime = 5 * time.Minute

	connCtx, cancel := context.WithTimeout(ctx, 8*time.Second)
	defer cancel()

	pool, err := pgxpool.NewWithConfig(connCtx, poolCfg)
	if err != nil {
		if cfg.Env == "development" {
			slog.Warn("postgres_unreachable_using_seeded_memory_store", slog.String("error", err.Error()))
			return repositories.NewInMemoryStore(), func() {}, nil
		}
		return nil, nil, fmt.Errorf("connect postgres: %w", err)
	}

	if err := pool.Ping(connCtx); err != nil {
		pool.Close()
		if cfg.Env == "development" {
			slog.Warn("postgres_ping_failed_using_seeded_memory_store", slog.String("error", err.Error()))
			return repositories.NewInMemoryStore(), func() {}, nil
		}
		return nil, nil, fmt.Errorf("ping postgres: %w", err)
	}

	if cfg.AutoMigrate {
		if err := RunMigrations(ctx, pool, cfg.MigrationsDir, cfg.AutoSeed); err != nil {
			pool.Close()
			return nil, nil, fmt.Errorf("run migrations: %w", err)
		}
	}

	slog.Info("database_initialized", slog.String("driver", "postgres+postgis"))
	return repositories.NewPostgresStore(pool), func() { pool.Close() }, nil
}

// RunMigrations executes the SQL migration and seed files against PostgreSQL.
func RunMigrations(ctx context.Context, pool *pgxpool.Pool, migrationsDir string, includeSeed bool) error {
	schemaPath := filepath.Join(migrationsDir, "000001_init_schema.up.sql")
	schemaSQL, err := os.ReadFile(schemaPath)
	if err != nil {
		return fmt.Errorf("read %s: %w", schemaPath, err)
	}
	if _, err := pool.Exec(ctx, string(schemaSQL)); err != nil {
		return fmt.Errorf("exec 000001_init_schema.up.sql: %w", err)
	}
	slog.Info("migration_applied", slog.String("file", "000001_init_schema.up.sql"))

	if includeSeed {
		seedPath := filepath.Join(migrationsDir, "000002_seed_reference_and_demo.up.sql")
		if seedSQL, err := os.ReadFile(seedPath); err == nil {
			if _, err := pool.Exec(ctx, string(seedSQL)); err != nil {
				return fmt.Errorf("exec 000002_seed_reference_and_demo.up.sql: %w", err)
			}
			slog.Info("migration_applied", slog.String("file", "000002_seed_reference_and_demo.up.sql"))
		}
	}
	return nil
}

