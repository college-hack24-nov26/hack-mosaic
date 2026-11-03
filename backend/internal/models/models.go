package models

import "time"

// Coordinates represents a WGS84 point.
type Coordinates struct {
	Lat float64 `json:"lat"`
	Lng float64 `json:"lng"`
}

// LocationRef matches API_CONTRACTS.md §4.1.
type LocationRef struct {
	ID       string       `json:"id"`
	ParentID *string      `json:"parent_id,omitempty"`
	Level    string       `json:"level"`
	Code     string       `json:"code"`
	NameEn   string       `json:"name_en"`
	NameHi   string       `json:"name_hi"`
	NameMr   string       `json:"name_mr"`
	Centroid *Coordinates `json:"centroid,omitempty"`
}

// SpeciesRef matches API_CONTRACTS.md §4.2.
type SpeciesRef struct {
	ID     int16  `json:"id"`
	Code   string `json:"code"`
	NameEn string `json:"name_en"`
	NameHi string `json:"name_hi"`
	NameMr string `json:"name_mr"`
}

// BreedRef matches API_CONTRACTS.md §4.2.
type BreedRef struct {
	ID          int    `json:"id"`
	SpeciesCode string `json:"species_code"`
	Code        string `json:"code"`
	NameEn      string `json:"name_en"`
	NameHi      string `json:"name_hi"`
	NameMr      string `json:"name_mr"`
}

// DiseaseRef matches API_CONTRACTS.md §4.3.
type DiseaseRef struct {
	ID                int16  `json:"id"`
	Code              string `json:"code"`
	NameEn            string `json:"name_en"`
	NameHi            string `json:"name_hi"`
	NameMr            string `json:"name_mr"`
	IsNotifiable      bool   `json:"is_notifiable"`
	IsOutbreakTracked bool   `json:"is_outbreak_tracked"`
	IsSurveillance    bool   `json:"is_surveillance"`
	ClusterMinCases   int16  `json:"cluster_min_cases"`
	ClusterRadiusM    int    `json:"cluster_radius_m"`
	ClusterWindowDays int16  `json:"cluster_window_days"`
	PrecautionsEn     string `json:"precautions_en,omitempty"`
	PrecautionsHi     string `json:"precautions_hi,omitempty"`
	PrecautionsMr     string `json:"precautions_mr,omitempty"`
}

// SymptomRef matches API_CONTRACTS.md §4.4.
type SymptomRef struct {
	ID       int16  `json:"id"`
	Code     string `json:"code"`
	NameEn   string `json:"name_en"`
	NameHi   string `json:"name_hi"`
	NameMr   string `json:"name_mr"`
	Category string `json:"category"`
}

// FarmerProfile holds farmer-specific fields on UserDTO.
type FarmerProfile struct {
	VillageID     *string      `json:"village_id,omitempty"`
	VillageName   string       `json:"village_name,omitempty"`
	TalukaID      string       `json:"taluka_id"`
	TalukaName    string       `json:"taluka_name,omitempty"`
	DistrictID    string       `json:"district_id"`
	DistrictName  string       `json:"district_name,omitempty"`
	HomeLocation  *Coordinates `json:"home_location,omitempty"`
	ConsentAlerts bool         `json:"consent_alerts"`
}

// VetProfile holds veterinarian-specific fields on UserDTO.
type VetProfile struct {
	RegistrationNo string       `json:"registration_no"`
	Qualification  string       `json:"qualification"`
	ClinicName     string       `json:"clinic_name,omitempty"`
	Address        string       `json:"address,omitempty"`
	WorkingHours   string       `json:"working_hours,omitempty"`
	IsParaVet      bool         `json:"is_para_vet"`
	DistrictID     string       `json:"district_id"`
	DistrictName   string       `json:"district_name,omitempty"`
	TalukaID       *string      `json:"taluka_id,omitempty"`
	TalukaName     string       `json:"taluka_name,omitempty"`
	ClinicLocation *Coordinates `json:"clinic_location,omitempty"`
	IsVerified     bool         `json:"is_verified"`
	VerifiedAt     *time.Time   `json:"verified_at,omitempty"`
}

// OfficerProfile holds officer-specific fields on UserDTO.
type OfficerProfile struct {
	Designation     string `json:"designation"`
	Level           string `json:"level"`
	ScopeLocationID string `json:"scope_location_id"`
	DistrictName    string `json:"district_name,omitempty"`
}

// UserProfileEnvelope supports both nested (profile.farmer / profile.vet / profile.officer)
// and flat access in MeProfile.fromJson in mobile/lib/data/models/me_model.dart.
type UserProfileEnvelope struct {
	Farmer         *FarmerProfile  `json:"farmer,omitempty"`
	Vet            *VetProfile     `json:"vet,omitempty"`
	Officer        *OfficerProfile `json:"officer,omitempty"`
	VillageID      *string         `json:"village_id,omitempty"`
	TalukaID       string          `json:"taluka_id,omitempty"`
	TalukaName     string          `json:"taluka_name,omitempty"`
	DistrictID     string          `json:"district_id,omitempty"`
	DistrictName   string          `json:"district_name,omitempty"`
	ConsentAlerts  *bool           `json:"consent_alerts,omitempty"`
	RegistrationNo string          `json:"registration_no,omitempty"`
	Qualification  string          `json:"qualification,omitempty"`
	ClinicName     string          `json:"clinic_name,omitempty"`
	IsVerified     *bool           `json:"is_verified,omitempty"`
	Designation    string          `json:"designation,omitempty"`
	Level          string          `json:"level,omitempty"`
	ScopeLocID     string          `json:"scope_location_id,omitempty"`
}

// UserDTO matches API_CONTRACTS.md §3.5 and includes dashboard compatibility fields.
type UserDTO struct {
	ID                 string               `json:"id"`
	Phone              string               `json:"phone"`
	PhoneNumber        string               `json:"phone_number"`
	Email              *string              `json:"email,omitempty"`
	FullName           string               `json:"full_name"`
	Name               string               `json:"name"`
	Role               string               `json:"role"`
	PreferredLanguage  string               `json:"preferred_language"`
	LanguagePreference string               `json:"language_preference"`
	AccountStatus      string               `json:"account_status"`
	IsActive           bool                 `json:"is_active"`
	District           string               `json:"district,omitempty"`
	State              string               `json:"state,omitempty"`
	Profile            *UserProfileEnvelope `json:"profile,omitempty"`
	PasswordHash       string               `json:"-"`
}

// AnimalDTO matches API_CONTRACTS.md §5.1.
type AnimalDTO struct {
	ID              string    `json:"id"`
	FarmerUserID    string    `json:"farmer_user_id"`
	SpeciesCode     string    `json:"species_code"`
	BreedCode       *string   `json:"breed_code,omitempty"`
	TagNumber       *string   `json:"tag_number,omitempty"`
	Name            *string   `json:"name,omitempty"`
	Sex             string    `json:"sex"`
	BirthDate       *string   `json:"birth_date,omitempty"`
	ApproxAgeMonths *int16    `json:"approx_age_months,omitempty"`
	Markings        *string   `json:"markings,omitempty"`
	IsActive        bool      `json:"is_active"`
	ClientCreatedAt time.Time `json:"client_created_at"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// HealthRecordDTO matches API_CONTRACTS.md §5.2.
type HealthRecordDTO struct {
	ID               string         `json:"id"`
	AnimalID         string         `json:"animal_id"`
	RecordedByUserID string         `json:"recorded_by_user_id"`
	RecordedByName   string         `json:"recorded_by_name,omitempty"`
	SourceReportID   *string        `json:"source_report_id,omitempty"`
	RecordType       string         `json:"record_type"`
	Summary          string         `json:"summary"`
	WeightKg         *float64       `json:"weight_kg,omitempty"`
	TemperatureC     *float64       `json:"temperature_c,omitempty"`
	Data             map[string]any `json:"data,omitempty"`
	RecordedAt       time.Time      `json:"recorded_at"`
	CreatedAt        time.Time      `json:"created_at"`
}

// VaccinationDTO matches API_CONTRACTS.md §5.4.
type VaccinationDTO struct {
	ID                   string    `json:"id"`
	AnimalID             string    `json:"animal_id"`
	DiseaseCode          *string   `json:"disease_code,omitempty"`
	VaccineName          string    `json:"vaccine_name"`
	BatchNumber          *string   `json:"batch_number,omitempty"`
	DoseNumber           int16     `json:"dose_number"`
	AdministeredOn       string    `json:"administered_on"`
	NextDueOn            *string   `json:"next_due_on,omitempty"`
	AdministeredByUserID *string   `json:"administered_by_user_id,omitempty"`
	Notes                *string   `json:"notes,omitempty"`
	CreatedAt            time.Time `json:"created_at"`
}

// TreatmentDTO matches API_CONTRACTS.md §5.3 and VetRepository.
type TreatmentDTO struct {
	ID                string    `json:"id"`
	AnimalID          string    `json:"animal_id"`
	ReportID          *string   `json:"report_id,omitempty"`
	PrescribedByVetID string    `json:"prescribed_by_vet_id"`
	PrescribedByName  string    `json:"prescribed_by_name,omitempty"`
	MedicationName    string    `json:"medication_name"`
	TreatmentName     string    `json:"treatment_name"`
	Dosage            string    `json:"dosage"`
	DurationDays      *int16    `json:"duration_days,omitempty"`
	Instructions      *string   `json:"instructions,omitempty"`
	Notes             *string   `json:"notes,omitempty"`
	StartedOn         string    `json:"started_on"`
	EndedOn           *string   `json:"ended_on,omitempty"`
	OutcomeNotes      *string   `json:"outcome_notes,omitempty"`
	CreatedAt         time.Time `json:"created_at"`
}

// AnimalRecordDTO matches API_CONTRACTS.md §5.5.
type AnimalRecordDTO struct {
	Animal        AnimalDTO         `json:"animal"`
	HealthRecords []HealthRecordDTO `json:"health_records"`
	Vaccinations  []VaccinationDTO  `json:"vaccinations"`
	Treatments    []TreatmentDTO    `json:"treatments"`
	RecentReports []ReportBriefDTO  `json:"recent_reports"`
	GeneratedAt   time.Time         `json:"generated_at"`
}

// ReportBriefDTO is used inside AnimalRecordDTO.
type ReportBriefDTO struct {
	ID                   string    `json:"id"`
	ReportedAt           time.Time `json:"reported_at"`
	Status               string    `json:"status"`
	ConfirmedDiseaseCode *string   `json:"confirmed_disease_code,omitempty"`
	Description          *string   `json:"description,omitempty"`
}

// ReportAnimalEmbed matches VetReport.animal in mobile.
type ReportAnimalEmbed struct {
	ID          string  `json:"id"`
	Name        *string `json:"name,omitempty"`
	SpeciesCode string  `json:"species_code"`
	BreedCode   *string `json:"breed_code,omitempty"`
	TagNumber   *string `json:"tag_number,omitempty"`
}

// ReportFarmerEmbed matches VetReport.farmer in mobile.
type ReportFarmerEmbed struct {
	ID       string `json:"id"`
	FullName string `json:"full_name"`
	Phone    string `json:"phone,omitempty"`
}

// ReportLocationEmbed matches API_CONTRACTS.md §6.1.
type ReportLocationEmbed struct {
	Lat       float64  `json:"lat"`
	Lng       float64  `json:"lng"`
	AccuracyM *float64 `json:"accuracy_m,omitempty"`
	Source    string   `json:"source"`
}

// ScreeningScore represents one class probability in MobileNetV3 output.
type ScreeningScore struct {
	Label string  `json:"label"`
	Score float64 `json:"score"`
}

// ReportScreeningEmbed matches API_CONTRACTS.md §6.1 (always includes disclaimer).
type ReportScreeningEmbed struct {
	ModelVersion  string           `json:"model_version"`
	TopLabel      string           `json:"top_label"`
	TopConfidence *float64         `json:"top_confidence,omitempty"`
	Inconclusive  bool             `json:"inconclusive"`
	Scores        []ScreeningScore `json:"scores,omitempty"`
	RanAt         time.Time        `json:"ran_at"`
	Disclaimer    string           `json:"disclaimer"`
}

// TfliteImageResult provides image-level TFLite screening fields for the React Dashboard.
type TfliteImageResult struct {
	PredictedClass string  `json:"predicted_class"`
	Confidence     float64 `json:"confidence"`
}

// ReportImageDTO matches API_CONTRACTS.md §6.2.
type ReportImageDTO struct {
	ID               string             `json:"id"`
	ReportID         string             `json:"report_id"`
	URL              string             `json:"url"`
	ImageURL         string             `json:"image_url"`
	MimeType         string             `json:"mime_type"`
	ByteSize         int                `json:"byte_size"`
	WidthPx          *int               `json:"width_px,omitempty"`
	HeightPx         *int               `json:"height_px,omitempty"`
	Sha256Hex        string             `json:"sha256_hex"`
	StorageKey       string             `json:"-"`
	CapturedAt       *time.Time         `json:"captured_at,omitempty"`
	UploadedAt       time.Time          `json:"uploaded_at"`
	TfliteResult     *TfliteImageResult `json:"tflite_result,omitempty"`
	TfliteConfidence *float64           `json:"tflite_confidence,omitempty"`
}

// VerificationVetEmbed identifies the verifying veterinarian.
type VerificationVetEmbed struct {
	ID             string `json:"id"`
	FullName       string `json:"full_name"`
	RegistrationNo string `json:"registration_no,omitempty"`
}

// ReportVerificationDTO matches API_CONTRACTS.md §6.6.
type ReportVerificationDTO struct {
	ID               string                `json:"id"`
	ReportID         string                `json:"report_id"`
	Decision         string                `json:"decision"`
	Status           string                `json:"status"`
	DiseaseCode      *string               `json:"disease_code,omitempty"`
	SuspectedDisease string                `json:"suspected_disease,omitempty"`
	Notes            *string               `json:"notes,omitempty"`
	DiagnosisNotes   string                `json:"diagnosis_notes,omitempty"`
	VisitRequired    bool                  `json:"visit_required"`
	Vet              *VerificationVetEmbed `json:"vet,omitempty"`
	VetID            string                `json:"vet_id,omitempty"`
	VetName          string                `json:"vet_name,omitempty"`
	DecidedAt        time.Time             `json:"decided_at"`
	VerifiedAt       time.Time             `json:"verified_at"`
}

// DiseaseReportDTO matches API_CONTRACTS.md §6.1–6.5, Flutter VetReport, and React Dashboard DiseaseReport.
type DiseaseReportDTO struct {
	ID                   string                 `json:"id"`
	Animal               ReportAnimalEmbed      `json:"animal"`
	Farmer               *ReportFarmerEmbed     `json:"farmer,omitempty"`
	AnimalID             string                 `json:"animal_id"`
	FarmerID             string                 `json:"farmer_id"`
	FarmerName           string                 `json:"farmer_name"`
	FarmerPhone          string                 `json:"farmer_phone,omitempty"`
	AnimalName           string                 `json:"animal_name,omitempty"`
	AnimalSpecies        string                 `json:"animal_species"`
	TagNumber            *string                `json:"tag_number,omitempty"`
	ReportedAt           time.Time              `json:"reported_at"`
	ReceivedAt           time.Time              `json:"received_at"`
	Description          *string                `json:"description,omitempty"`
	DescriptionLanguage  string                 `json:"description_language"`
	SymptomCodes         []string               `json:"symptom_codes"`
	Symptoms             []string               `json:"symptoms"`
	Location             ReportLocationEmbed    `json:"location"`
	Latitude             float64                `json:"latitude"`
	Longitude            float64                `json:"longitude"`
	VillageID            *string                `json:"village_id,omitempty"`
	Village              string                 `json:"village,omitempty"`
	TalukaID             string                 `json:"taluka_id"`
	Taluka               string                 `json:"taluka,omitempty"`
	DistrictID           string                 `json:"district_id"`
	District             string                 `json:"district,omitempty"`
	Status               string                 `json:"status"`
	ConfirmedDiseaseCode *string                `json:"confirmed_disease_code,omitempty"`
	ClaimedByVetID       *string                `json:"claimed_by_vet_id,omitempty"`
	ClaimedAt            *time.Time             `json:"claimed_at,omitempty"`
	ExpectedImageCount   int16                  `json:"expected_image_count"`
	ImagesPending        bool                   `json:"images_pending"`
	Screening            *ReportScreeningEmbed  `json:"screening,omitempty"`
	Images               []ReportImageDTO       `json:"images"`
	Verification         *ReportVerificationDTO `json:"verification,omitempty"`
	CreatedAt            time.Time              `json:"created_at"`
	UpdatedAt            time.Time              `json:"updated_at"`
}

// OutbreakDTO matches API_CONTRACTS.md §7.4, Flutter OutbreakZoneModel, and React OutbreakCluster.
type OutbreakDTO struct {
	ID                 string      `json:"id"`
	ClusterID          string      `json:"cluster_id"`
	DiseaseCode        string      `json:"disease_code"`
	DiseaseName        string      `json:"disease_name"`
	PrimaryDisease     string      `json:"primary_disease"`
	DistrictID         string      `json:"district_id"`
	District           string      `json:"district"`
	TalukaID           *string     `json:"taluka_id,omitempty"`
	Taluka             string      `json:"taluka,omitempty"`
	Centroid           Coordinates `json:"centroid"`
	Latitude           float64     `json:"latitude"`
	Longitude          float64     `json:"longitude"`
	CenterLatitude     float64     `json:"center_latitude"`
	CenterLongitude    float64     `json:"center_longitude"`
	RadiusM            int         `json:"radius_m"`
	RadiusMeters       float64     `json:"radius_meters"`
	RadiusKm           float64     `json:"radius_km"`
	ConfirmedCaseCount int         `json:"confirmed_case_count"`
	CaseCount          int         `json:"case_count"`
	FirstCaseAt        time.Time   `json:"first_case_at"`
	LastCaseAt         time.Time   `json:"last_case_at"`
	DetectedAt         time.Time   `json:"detected_at"`
	Status             string      `json:"status"`
	RiskLevel          string      `json:"risk_level"`
	Advisory           string      `json:"advisory"`
	ReportIDs          []string    `json:"report_ids,omitempty"`
}

// AlertDTO matches API_CONTRACTS.md §7.5 and React DiseaseAlert.
type AlertDTO struct {
	ID               string     `json:"id"`
	OutbreakID       string     `json:"outbreak_id"`
	ApprovedByUserID string     `json:"approved_by_user_id"`
	RadiusM          int        `json:"radius_m"`
	TitleEn          string     `json:"title_en"`
	TitleHi          string     `json:"title_hi,omitempty"`
	TitleMr          string     `json:"title_mr"`
	BodyEn           string     `json:"body_en"`
	BodyHi           string     `json:"body_hi,omitempty"`
	BodyMr           string     `json:"body_mr"`
	Title            string     `json:"title"`
	Message          string     `json:"message"`
	Severity         string     `json:"severity"`
	AffectedDistrict string     `json:"affected_district"`
	DiseaseName      string     `json:"disease_name"`
	Status           string     `json:"status"`
	IsActive         bool       `json:"is_active"`
	RecipientCount   int        `json:"recipient_count"`
	SentAt           *time.Time `json:"sent_at,omitempty"`
	CreatedAt        time.Time  `json:"created_at"`
}

// NotificationDTO matches API_CONTRACTS.md §8.
type NotificationDTO struct {
	ID        string     `json:"id"`
	UserID    string     `json:"user_id"`
	Type      string     `json:"type"`
	AlertID   *string    `json:"alert_id,omitempty"`
	ReportID  *string    `json:"report_id,omitempty"`
	Title     string     `json:"title"`
	Body      string     `json:"body"`
	Language  string     `json:"language"`
	ReadAt    *time.Time `json:"read_at,omitempty"`
	CreatedAt time.Time  `json:"created_at"`
}

// NearbyVetDTO matches Flutter VeterinarianModel.fromJson.
type NearbyVetDTO struct {
	ID                 string  `json:"id"`
	Name               string  `json:"name"`
	Qualification      string  `json:"qualification"`
	RegistrationNumber string  `json:"registration_number"`
	ClinicName         string  `json:"clinic_name"`
	Address            string  `json:"address"`
	Latitude           float64 `json:"latitude"`
	Longitude          float64 `json:"longitude"`
	Phone              string  `json:"phone"`
	IsVerified         bool    `json:"is_verified"`
	IsParaVet          bool    `json:"is_para_vet"`
	WorkingHours       string  `json:"working_hours"`
	DistanceKm         float64 `json:"distance_km"`
}

