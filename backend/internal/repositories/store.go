package repositories

import (
	"context"
	"errors"
	"math"
	"time"

	"pashuvani/backend/internal/models"
)

var (
	ErrNotFound         = errors.New("resource not found")
	ErrConflict         = errors.New("resource conflict")
	ErrForbidden        = errors.New("forbidden scope or ownership")
	ErrInvalidReference = errors.New("invalid reference code or id")
	ErrAlreadyDecided   = errors.New("report already verified")
	ErrUnverifiedVet    = errors.New("veterinarian account not verified")
)

type CreateFarmerParams struct {
	Phone             string
	PasswordHash      string
	FullName          string
	PreferredLanguage string
	DistrictID        string
	TalukaID          string
	VillageID         *string
	ConsentAlerts     bool
}

type CreateAnimalParams struct {
	ID              string
	FarmerUserID    string
	SpeciesCode     string
	BreedCode       *string
	TagNumber       *string
	Name            *string
	Sex             string
	BirthDate       *string
	ApproxAgeMonths *int16
	Markings        *string
	ClientCreatedAt time.Time
}

type CreateHealthRecordParams struct {
	AnimalID         string
	RecordedByUserID string
	SourceReportID   *string
	RecordType       string
	Summary          string
	WeightKg         *float64
	TemperatureC     *float64
	Data             map[string]any
	RecordedAt       time.Time
}

type CreateVaccinationParams struct {
	AnimalID             string
	DiseaseCode          *string
	VaccineName          string
	BatchNumber          *string
	DoseNumber           int16
	AdministeredOn       string
	NextDueOn            *string
	AdministeredByUserID *string
	Notes                *string
}

type CreateTreatmentParams struct {
	AnimalID          string
	ReportID          *string
	PrescribedByVetID string
	MedicationName    string
	Dosage            string
	DurationDays      *int16
	Instructions      *string
	StartedOn         string
	EndedOn           *string
	OutcomeNotes      *string
}

type CreateReportParams struct {
	ID                  string
	AnimalID            string
	ReporterUserID      string
	ReportedAt          time.Time
	Description         *string
	DescriptionLanguage string
	SymptomCodes        []string
	Lat                 *float64
	Lng                 *float64
	AccuracyM           *float64
	VillageID           *string
	ExpectedImageCount  int16
	Screening           *models.ReportScreeningEmbed
}

type ReportFilter struct {
	ReporterUserID string
	DistrictID     string
	TalukaID       string
	Status         string
	DiseaseCode    string
	Page           int
	PageSize       int
}

type VerifyReportParams struct {
	ReportID      string
	VetUserID     string
	VetDistrictID string
	IsAdmin       bool
	Decision      string // confirmed | rejected | flagged
	DiseaseCode   *string
	Notes         *string
	VisitRequired bool
}

type CreateAlertParams struct {
	OutbreakID       string
	ApprovedByUserID string
	RadiusM          int
	TitleEn          string
	TitleHi          string
	TitleMr          string
	BodyEn           string
	BodyHi           string
	BodyMr           string
	Severity         string
	AffectedDistrict string
	DiseaseName      string
	SendNow          bool
}

// Store defines the persistence contract implemented by PostgresStore (PostgreSQL 16 + PostGIS)
// and InMemoryStore (deterministic fallback/testing).
type Store interface {
	Ping(ctx context.Context) (dbOK bool, postgisOK bool, driver string, err error)

	// Reference
	GetLocations(ctx context.Context, level, parentID string) ([]models.LocationRef, error)
	GetLocationByID(ctx context.Context, id string) (*models.LocationRef, error)
	GetSpecies(ctx context.Context) ([]models.SpeciesRef, error)
	GetBreeds(ctx context.Context, speciesCode string) ([]models.BreedRef, error)
	GetDiseases(ctx context.Context) ([]models.DiseaseRef, error)
	GetSymptoms(ctx context.Context) ([]models.SymptomRef, error)

	// Users & Auth
	CreateFarmerUser(ctx context.Context, params CreateFarmerParams) (*models.UserDTO, error)
	GetUserByPhoneOrEmail(ctx context.Context, identifier string) (*models.UserDTO, error)
	GetUserByID(ctx context.Context, userID string) (*models.UserDTO, error)
	UpdateUserMe(ctx context.Context, userID string, fullName, preferredLang, villageID *string, consentAlerts *bool) (*models.UserDTO, error)
	SaveRefreshToken(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error
	ConsumeRefreshToken(ctx context.Context, tokenHash string) (userID string, err error)
	RevokeRefreshToken(ctx context.Context, tokenHash string) error

	// Animals & Clinical Records
	CreateOrGetAnimal(ctx context.Context, params CreateAnimalParams) (*models.AnimalDTO, bool, error)
	ListAnimals(ctx context.Context, farmerUserID string, page, pageSize int) ([]models.AnimalDTO, int, error)
	GetAnimalByID(ctx context.Context, animalID string) (*models.AnimalDTO, error)
	UpdateAnimal(ctx context.Context, animalID string, name, tagNumber, markings *string, isActive *bool) (*models.AnimalDTO, error)
	GetAnimalRecord(ctx context.Context, animalID string) (*models.AnimalRecordDTO, error)
	AddHealthRecord(ctx context.Context, params CreateHealthRecordParams) (*models.HealthRecordDTO, error)
	AddVaccination(ctx context.Context, params CreateVaccinationParams) (*models.VaccinationDTO, error)
	AddTreatment(ctx context.Context, params CreateTreatmentParams) (*models.TreatmentDTO, error)

	// Reports & Images
	CreateOrGetReport(ctx context.Context, params CreateReportParams) (*models.DiseaseReportDTO, bool, error)
	AddReportImage(ctx context.Context, img models.ReportImageDTO) (*models.ReportImageDTO, error)
	GetReportImage(ctx context.Context, reportID, imageID string) (*models.ReportImageDTO, error)
	ListReports(ctx context.Context, filter ReportFilter) ([]models.DiseaseReportDTO, int, error)
	GetReportByID(ctx context.Context, reportID string) (*models.DiseaseReportDTO, error)

	// Vet Claim & Verification
	ClaimReport(ctx context.Context, reportID, vetUserID, vetDistrictID string, isAdmin bool) (*models.DiseaseReportDTO, error)
	VerifyReport(ctx context.Context, params VerifyReportParams) (*models.DiseaseReportDTO, error)

	// Dashboard, Map, Outbreaks, Alerts, Notifications, Nearby Vets
	GetDashboardSummary(ctx context.Context, districtID string) (map[string]any, error)
	GetDashboardTimeseries(ctx context.Context, districtID string, days int) ([]map[string]any, error)
	GetConfirmedMapCases(ctx context.Context, districtID, diseaseCode string) ([]map[string]any, error)
	ListOutbreaks(ctx context.Context, districtID, status string) ([]models.OutbreakDTO, error)
	GetOutbreakByID(ctx context.Context, id string) (*models.OutbreakDTO, error)
	UpdateOutbreakStatus(ctx context.Context, id, status string) (*models.OutbreakDTO, error)
	RecomputeOutbreaks(ctx context.Context, districtID string) ([]models.OutbreakDTO, error)
	ListAlerts(ctx context.Context, districtID string) ([]models.AlertDTO, error)
	CreateAlert(ctx context.Context, params CreateAlertParams) (*models.AlertDTO, error)
	SendAlert(ctx context.Context, alertID string) (*models.AlertDTO, error)
	ListNotifications(ctx context.Context, userID string) ([]models.NotificationDTO, error)
	MarkNotificationRead(ctx context.Context, userID, notificationID string) error
	GetNearbyVeterinarians(ctx context.Context, lat, lng, radiusKm float64) ([]models.NearbyVetDTO, error)
}

// HaversineKm calculates great-circle distance in kilometers between two WGS84 points.
func HaversineKm(lat1, lon1, lat2, lon2 float64) float64 {
	const earthRadiusKm = 6371.0
	dLat := (lat2 - lat1) * math.Pi / 180.0
	dLon := (lon2 - lon1) * math.Pi / 180.0
	rLat1 := lat1 * math.Pi / 180.0
	rLat2 := lat2 * math.Pi / 180.0

	a := math.Sin(dLat/2)*math.Sin(dLat/2) +
		math.Sin(dLon/2)*math.Sin(dLon/2)*math.Cos(rLat1)*math.Cos(rLat2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return math.Round(earthRadiusKm*c*100) / 100
}
