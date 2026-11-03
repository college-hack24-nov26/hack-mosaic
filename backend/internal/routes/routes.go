package routes

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"pashuvani/backend/internal/config"
	"pashuvani/backend/internal/handlers"
	"pashuvani/backend/internal/middleware"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/internal/services"
	"pashuvani/backend/pkg/response"
)

// NewRouter constructs the Gin engine with all middleware and API v1 routes registered.
func NewRouter(cfg *config.Config, store repositories.Store, authSvc *services.AuthService) *gin.Engine {
	if cfg.Env == "production" {
		gin.SetMode(gin.ReleaseMode)
	}

	r := gin.New()
	r.Use(middleware.RequestID())
	r.Use(middleware.StructuredLogger())
	r.Use(middleware.Recovery())
	r.Use(middleware.CORS(cfg.CORSOrigins))

	healthH := handlers.NewHealthHandler(store)
	refH := handlers.NewReferenceHandler(store)
	authH := handlers.NewAuthHandler(store, authSvc)
	animalH := handlers.NewAnimalHandler(store)
	reportH := handlers.NewReportHandler(store, cfg)
	vetH := handlers.NewVetHandler(store)
	dashH := handlers.NewDashboardHandler(store)

	// Top-level health checks
	r.GET("/health", healthH.Check)
	r.GET("/healthz", healthH.Check)

	v1 := r.Group("/api/v1")
	{
		v1.GET("/healthz", healthH.Check)
		v1.GET("/health", healthH.Check)

		// Public Reference Catalogs (API_CONTRACTS.md §4)
		ref := v1.Group("/reference")
		{
			ref.GET("/locations", refH.Locations)
			ref.GET("/species", refH.Species)
			ref.GET("/breeds", refH.Breeds)
			ref.GET("/diseases", refH.Diseases)
			ref.GET("/symptoms", refH.Symptoms)
		}

		// Nearby Veterinarians (PostGIS spatial query)
		v1.GET("/veterinarians/nearby", vetH.NearbyVeterinarians)

		// Authentication (API_CONTRACTS.md §3)
		auth := v1.Group("/auth")
		{
			auth.POST("/register", authH.Register)
			auth.POST("/login", authH.Login)
			auth.POST("/refresh", authH.Refresh)
		}

		// Protected API v1 routes
		authed := v1.Group("")
		authed.Use(middleware.RequireAuth(authSvc))
		{
			authed.POST("/auth/logout", authH.Logout)
			authed.GET("/me", authH.Me)
			authed.GET("/auth/me", authH.Me)
			authed.PATCH("/me", authH.UpdateMe)

			// Animals & Clinical Records (API_CONTRACTS.md §5)
			authed.POST("/animals", middleware.RequireRoles("farmer"), animalH.Create)
			authed.GET("/animals", middleware.RequireRoles("farmer"), animalH.List)
			authed.GET("/animals/:id", middleware.RequireRoles("farmer", "vet", "officer", "admin"), animalH.Get)
			authed.PATCH("/animals/:id", middleware.RequireRoles("farmer"), animalH.Update)
			authed.GET("/animals/:id/record", middleware.RequireRoles("farmer", "vet", "officer", "admin"), animalH.GetRecord)
			authed.GET("/animals/:id/qr-payload", middleware.RequireRoles("farmer", "vet", "admin"), animalH.GetQRPayload)
			authed.POST("/animals/:id/health-records", middleware.RequireRoles("farmer", "vet", "admin"), animalH.AddHealthRecord)
			authed.POST("/animals/:id/vaccinations", middleware.RequireRoles("farmer", "vet", "admin"), animalH.AddVaccination)
			authed.POST("/animals/:id/treatments", middleware.RequireRoles("vet", "admin"), animalH.AddTreatment)

			// Disease Reports & Images (API_CONTRACTS.md §6.1–6.5)
			authed.POST("/reports", middleware.RequireRoles("farmer"), reportH.Create)
			authed.POST("/reports/:id/images", middleware.RequireRoles("farmer"), reportH.UploadImage)
			authed.GET("/reports", middleware.RequireRoles("farmer", "vet", "officer", "admin"), reportH.List)
			authed.GET("/reports/:id", middleware.RequireRoles("farmer", "vet", "officer", "admin"), reportH.Get)
			authed.GET("/reports/:id/images/:image_id", middleware.RequireRoles("farmer", "vet", "officer", "admin"), reportH.GetImage)

			// Veterinarian Claim & Verification (API_CONTRACTS.md §6.6)
			authed.POST("/reports/:id/claim", middleware.RequireRoles("vet", "admin"), vetH.ClaimReport)
			authed.POST("/reports/:id/verifications", middleware.RequireRoles("vet", "admin"), vetH.VerifyReport)

			// Surveillance Dashboard, Map, Outbreaks & Alerts (API_CONTRACTS.md §7–§8)
			authed.GET("/dashboard/summary", middleware.RequireRoles("vet", "officer", "admin"), dashH.Summary)
			authed.GET("/dashboard/stats", middleware.RequireRoles("vet", "officer", "admin"), dashH.Summary)
			authed.GET("/dashboard/timeseries", middleware.RequireRoles("vet", "officer", "admin"), dashH.Timeseries)
			authed.GET("/dashboard/map-data", middleware.RequireRoles("vet", "officer", "admin"), dashH.MapPins)
			authed.GET("/dashboard/clusters", middleware.RequireRoles("vet", "officer", "admin"), dashH.ListOutbreaks)

			authed.GET("/map/cases", middleware.RequireRoles("farmer", "vet", "officer", "admin"), dashH.MapCases)
			authed.GET("/outbreaks", middleware.RequireRoles("farmer", "vet", "officer", "admin"), dashH.ListOutbreaks)
			authed.GET("/outbreaks/:id", middleware.RequireRoles("farmer", "vet", "officer", "admin"), dashH.GetOutbreak)
			authed.PATCH("/outbreaks/:id", middleware.RequireRoles("officer", "admin"), dashH.UpdateOutbreak)
			authed.POST("/outbreaks/recompute", middleware.RequireRoles("officer", "admin"), dashH.RecomputeOutbreaks)

			authed.GET("/alerts", middleware.RequireRoles("farmer", "vet", "officer", "admin"), dashH.ListAlerts)
			authed.POST("/alerts", middleware.RequireRoles("officer", "admin"), dashH.CreateAlert)
			authed.POST("/alerts/:id/send", middleware.RequireRoles("officer", "admin"), dashH.SendAlert)

			authed.GET("/notifications", middleware.RequireRoles("farmer", "vet", "officer", "admin"), dashH.ListNotifications)
			authed.POST("/notifications/:id/read", middleware.RequireRoles("farmer", "vet", "officer", "admin"), dashH.MarkNotificationRead)
		}
	}

	r.NoRoute(func(c *gin.Context) {
		response.Error(c, http.StatusNotFound, "NOT_FOUND", "Endpoint not found.", nil)
	})

	return r
}

