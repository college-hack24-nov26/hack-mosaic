package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"pashuvani/backend/internal/config"
	"pashuvani/backend/internal/database"
	"pashuvani/backend/internal/routes"
	"pashuvani/backend/internal/services"
)

func main() {
	logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelInfo,
	}))
	slog.SetDefault(logger)

	cfg := config.Load()

	ctx := context.Background()
	store, closeDB, err := database.Connect(ctx, cfg)
	if err != nil {
		slog.Error("startup_database_error", slog.String("error", err.Error()))
		os.Exit(1)
	}
	defer closeDB()

	authSvc := services.NewAuthService(cfg.JWTSecret, cfg.AccessTTLSeconds, cfg.RefreshTTLSeconds)
	router := routes.NewRouter(cfg, store, authSvc)

	srv := &http.Server{
		Addr:         ":" + cfg.Port,
		Handler:      router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 30 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	go func() {
		slog.Info("pashuvani_server_listening",
			slog.String("port", cfg.Port),
			slog.String("env", cfg.Env),
		)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("server_listen_error", slog.String("error", err.Error()))
			os.Exit(1)
		}
	}()

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	slog.Info("pashuvani_server_shutting_down")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_ = srv.Shutdown(shutdownCtx)
}
