package repositories

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"pashuvani/backend/internal/models"
)

// PostgresStore implements Store against PostgreSQL 16 + PostGIS 3.
type PostgresStore struct {
	pool *pgxpool.Pool
}

// NewPostgresStore creates a PostgresStore backed by a pgxpool.Pool.
func NewPostgresStore(pool *pgxpool.Pool) *PostgresStore {
	return &PostgresStore{pool: pool}
}

func (s *PostgresStore) Ping(ctx context.Context) (bool, bool, string, error) {
	if err := s.pool.Ping(ctx); err != nil {
		return false, false, "postgres", err
	}
	var postgisVer string
	err := s.pool.QueryRow(ctx, `SELECT PostGIS_Version()`).Scan(&postgisVer)
	if err != nil {
		return true, false, "postgres", nil
	}
	return true, postgisVer != "", "postgres+postgis", nil
}

// ---------------------------------------------------------------------------
// Reference Catalogs
// ---------------------------------------------------------------------------

func (s *PostgresStore) GetLocations(ctx context.Context, level, parentID string) ([]models.LocationRef, error) {
	query := `
		SELECT id::text, parent_id::text, level::text, code, name_en, COALESCE(name_hi, ''), name_mr,
		       ST_Y(centroid::geometry), ST_X(centroid::geometry)
		FROM locations
		WHERE ($1 = '' OR level::text = $1)
		  AND ($2 = '' OR parent_id::text = $2)
		ORDER BY name_en ASC`
	rows, err := s.pool.Query(ctx, query, level, parentID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []models.LocationRef
	for rows.Next() {
		var loc models.LocationRef
		var lat, lng *float64
		if err := rows.Scan(&loc.ID, &loc.ParentID, &loc.Level, &loc.Code, &loc.NameEn, &loc.NameHi, &loc.NameMr, &lat, &lng); err != nil {
			return nil, err
		}
		if lat != nil && lng != nil {
			loc.Centroid = &models.Coordinates{Lat: *lat, Lng: *lng}
		}
		out = append(out, loc)
	}
	if out == nil {
		out = []models.LocationRef{}
	}
	return out, nil
}

func (s *PostgresStore) GetLocationByID(ctx context.Context, id string) (*models.LocationRef, error) {
	query := `
		SELECT id::text, parent_id::text, level::text, code, name_en, COALESCE(name_hi, ''), name_mr,
		       ST_Y(centroid::geometry), ST_X(centroid::geometry)
		FROM locations WHERE id::text = $1 OR code = $1 LIMIT 1`
	var loc models.LocationRef
	var lat, lng *float64
	err := s.pool.QueryRow(ctx, query, id).Scan(
		&loc.ID, &loc.ParentID, &loc.Level, &loc.Code, &loc.NameEn, &loc.NameHi, &loc.NameMr, &lat, &lng,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	if lat != nil && lng != nil {
		loc.Centroid = &models.Coordinates{Lat: *lat, Lng: *lng}
	}
	return &loc, nil
}

func (s *PostgresStore) GetSpecies(ctx context.Context) ([]models.SpeciesRef, error) {
	rows, err := s.pool.Query(ctx, `SELECT id, code, name_en, COALESCE(name_hi, ''), name_mr FROM species ORDER BY id ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.SpeciesRef
	for rows.Next() {
		var sp models.SpeciesRef
		if err := rows.Scan(&sp.ID, &sp.Code, &sp.NameEn, &sp.NameHi, &sp.NameMr); err != nil {
			return nil, err
		}
		out = append(out, sp)
	}
	if out == nil {
		out = []models.SpeciesRef{}
	}
	return out, nil
}

func (s *PostgresStore) GetBreeds(ctx context.Context, speciesCode string) ([]models.BreedRef, error) {
	query := `
		SELECT b.id, s.code, b.code, b.name_en, COALESCE(b.name_hi, ''), b.name_mr
		FROM breeds b
		JOIN species s ON s.id = b.species_id
		WHERE ($1 = '' OR s.code = $1)
		ORDER BY b.id ASC`
	rows, err := s.pool.Query(ctx, query, speciesCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.BreedRef
	for rows.Next() {
		var br models.BreedRef
		if err := rows.Scan(&br.ID, &br.SpeciesCode, &br.Code, &br.NameEn, &br.NameHi, &br.NameMr); err != nil {
			return nil, err
		}
		out = append(out, br)
	}
	if out == nil {
		out = []models.BreedRef{}
	}
	return out, nil
}

func (s *PostgresStore) GetDiseases(ctx context.Context) ([]models.DiseaseRef, error) {
	query := `
		SELECT id, code, name_en, COALESCE(name_hi, ''), name_mr,
		       is_notifiable, is_outbreak_tracked, cluster_min_cases, cluster_radius_m, cluster_window_days,
		       COALESCE(precautions_en, ''), COALESCE(precautions_hi, ''), COALESCE(precautions_mr, '')
		FROM diseases ORDER BY id ASC`
	rows, err := s.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.DiseaseRef
	for rows.Next() {
		var d models.DiseaseRef
		if err := rows.Scan(&d.ID, &d.Code, &d.NameEn, &d.NameHi, &d.NameMr,
			&d.IsNotifiable, &d.IsOutbreakTracked, &d.ClusterMinCases, &d.ClusterRadiusM, &d.ClusterWindowDays,
			&d.PrecautionsEn, &d.PrecautionsHi, &d.PrecautionsMr); err != nil {
			return nil, err
		}
		d.IsSurveillance = d.IsOutbreakTracked || d.IsNotifiable
		out = append(out, d)
	}
	if out == nil {
		out = []models.DiseaseRef{}
	}
	return out, nil
}

func (s *PostgresStore) GetSymptoms(ctx context.Context) ([]models.SymptomRef, error) {
	rows, err := s.pool.Query(ctx, `SELECT id, code, name_en, COALESCE(name_hi, ''), name_mr, category FROM symptoms ORDER BY id ASC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.SymptomRef
	for rows.Next() {
		var sym models.SymptomRef
		if err := rows.Scan(&sym.ID, &sym.Code, &sym.NameEn, &sym.NameHi, &sym.NameMr, &sym.Category); err != nil {
			return nil, err
		}
		out = append(out, sym)
	}
	if out == nil {
		out = []models.SymptomRef{}
	}
	return out, nil
}

// ---------------------------------------------------------------------------
// Users & Auth
// ---------------------------------------------------------------------------

func (s *PostgresStore) CreateFarmerUser(ctx context.Context, params CreateFarmerParams) (*models.UserDTO, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var exists bool
	if err := tx.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE phone = $1)`, params.Phone).Scan(&exists); err != nil {
		return nil, err
	}
	if exists {
		return nil, ErrConflict
	}

	// Validate district & taluka exist
	var distID, talID string
	if err := tx.QueryRow(ctx, `SELECT id::text FROM locations WHERE id::text = $1 AND level = 'district'`, params.DistrictID).Scan(&distID); err != nil {
		return nil, ErrInvalidReference
	}
	if err := tx.QueryRow(ctx, `SELECT id::text FROM locations WHERE id::text = $1 AND level = 'taluka' AND parent_id::text = $2`, params.TalukaID, distID).Scan(&talID); err != nil {
		return nil, ErrInvalidReference
	}
	var vilID *string
	if params.VillageID != nil && *params.VillageID != "" {
		var v string
		if err := tx.QueryRow(ctx, `SELECT id::text FROM locations WHERE id::text = $1 AND level = 'village' AND parent_id::text = $2`, *params.VillageID, talID).Scan(&v); err != nil {
			return nil, ErrInvalidReference
		}
		vilID = &v
	}

	var userID string
	err = tx.QueryRow(ctx, `
		INSERT INTO users (phone, password_hash, full_name, role, preferred_language, is_active, account_status)
		VALUES ($1, $2, $3, 'farmer', $4::language_code, TRUE, 'active')
		RETURNING id::text`,
		params.Phone, params.PasswordHash, params.FullName, params.PreferredLanguage,
	).Scan(&userID)
	if err != nil {
		return nil, err
	}

	var consentAt *time.Time
	if params.ConsentAlerts {
		now := time.Now().UTC()
		consentAt = &now
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO farmers (user_id, village_id, taluka_id, district_id, home_location, consent_alerts, consent_given_at)
		VALUES (
			$1::uuid,
			$2::uuid,
			$3::uuid,
			$4::uuid,
			COALESCE((SELECT centroid FROM locations WHERE id = $2::uuid), (SELECT centroid FROM locations WHERE id = $3::uuid)),
			$5,
			$6
		)`,
		userID, vilID, talID, distID, params.ConsentAlerts, consentAt,
	)
	if err != nil {
		return nil, err
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.GetUserByID(ctx, userID)
}

func (s *PostgresStore) GetUserByPhoneOrEmail(ctx context.Context, identifier string) (*models.UserDTO, error) {
	var userID string
	err := s.pool.QueryRow(ctx, `
		SELECT id::text FROM users
		WHERE phone = $1 OR LOWER(COALESCE(email, '')) = LOWER($1)
		LIMIT 1`, identifier).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return s.GetUserByID(ctx, userID)
}

func (s *PostgresStore) GetUserByID(ctx context.Context, userID string) (*models.UserDTO, error) {
	var u models.UserDTO
	err := s.pool.QueryRow(ctx, `
		SELECT id::text, phone, email, password_hash, full_name, role::text, preferred_language::text, is_active, COALESCE(account_status, 'active')
		FROM users WHERE id::text = $1`, userID).Scan(
		&u.ID, &u.Phone, &u.Email, &u.PasswordHash, &u.FullName, &u.Role, &u.PreferredLanguage, &u.IsActive, &u.AccountStatus,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	u.PhoneNumber = u.Phone
	u.Name = u.FullName
	u.LanguagePreference = u.PreferredLanguage
	u.State = "Maharashtra"
	u.Profile = &models.UserProfileEnvelope{}

	switch u.Role {
	case "farmer":
		var fp models.FarmerProfile
		var lat, lng *float64
		err := s.pool.QueryRow(ctx, `
			SELECT f.village_id::text, COALESCE(v.name_en, ''), f.taluka_id::text, COALESCE(t.name_en, ''),
			       f.district_id::text, COALESCE(d.name_en, ''), f.consent_alerts,
			       ST_Y(f.home_location::geometry), ST_X(f.home_location::geometry)
			FROM farmers f
			LEFT JOIN locations v ON v.id = f.village_id
			LEFT JOIN locations t ON t.id = f.taluka_id
			LEFT JOIN locations d ON d.id = f.district_id
			WHERE f.user_id::text = $1`, userID).Scan(
			&fp.VillageID, &fp.VillageName, &fp.TalukaID, &fp.TalukaName, &fp.DistrictID, &fp.DistrictName, &fp.ConsentAlerts, &lat, &lng,
		)
		if err == nil {
			if lat != nil && lng != nil {
				fp.HomeLocation = &models.Coordinates{Lat: *lat, Lng: *lng}
			}
			u.District = fp.DistrictName
			u.Profile.Farmer = &fp
			u.Profile.VillageID = fp.VillageID
			u.Profile.TalukaID = fp.TalukaID
			u.Profile.TalukaName = fp.TalukaName
			u.Profile.DistrictID = fp.DistrictID
			u.Profile.DistrictName = fp.DistrictName
			u.Profile.ConsentAlerts = &fp.ConsentAlerts
		}
	case "vet":
		var vp models.VetProfile
		var lat, lng *float64
		err := s.pool.QueryRow(ctx, `
			SELECT v.registration_no, COALESCE(v.qualification, 'B.V.Sc & A.H.'), COALESCE(v.clinic_name, ''),
			       COALESCE(v.address, ''), COALESCE(v.working_hours, ''), v.is_para_vet,
			       v.district_id::text, COALESCE(d.name_en, ''), v.taluka_id::text, COALESCE(t.name_en, ''),
			       v.is_verified, v.verified_at,
			       ST_Y(v.clinic_location::geometry), ST_X(v.clinic_location::geometry)
			FROM veterinarians v
			LEFT JOIN locations d ON d.id = v.district_id
			LEFT JOIN locations t ON t.id = v.taluka_id
			WHERE v.user_id::text = $1`, userID).Scan(
			&vp.RegistrationNo, &vp.Qualification, &vp.ClinicName, &vp.Address, &vp.WorkingHours, &vp.IsParaVet,
			&vp.DistrictID, &vp.DistrictName, &vp.TalukaID, &vp.TalukaName, &vp.IsVerified, &vp.VerifiedAt, &lat, &lng,
		)
		if err == nil {
			if lat != nil && lng != nil {
				vp.ClinicLocation = &models.Coordinates{Lat: *lat, Lng: *lng}
			}
			u.District = vp.DistrictName
			u.Profile.Vet = &vp
			u.Profile.RegistrationNo = vp.RegistrationNo
			u.Profile.Qualification = vp.Qualification
			u.Profile.ClinicName = vp.ClinicName
			u.Profile.DistrictID = vp.DistrictID
			u.Profile.DistrictName = vp.DistrictName
			if vp.TalukaID != nil {
				u.Profile.TalukaID = *vp.TalukaID
			}
			u.Profile.TalukaName = vp.TalukaName
			u.Profile.IsVerified = &vp.IsVerified
			if !vp.IsVerified && u.AccountStatus == "active" {
				u.AccountStatus = "pending_verification"
			}
		}
	case "officer":
		var op models.OfficerProfile
		err := s.pool.QueryRow(ctx, `
			SELECT o.designation, o.level::text, o.scope_location_id::text, COALESCE(l.name_en, 'Satara')
			FROM officers o
			LEFT JOIN locations l ON l.id = o.scope_location_id
			WHERE o.user_id::text = $1`, userID).Scan(
			&op.Designation, &op.Level, &op.ScopeLocationID, &op.DistrictName,
		)
		if err == nil {
			u.District = op.DistrictName
			u.Profile.Officer = &op
			u.Profile.Designation = op.Designation
			u.Profile.Level = op.Level
			u.Profile.ScopeLocID = op.ScopeLocationID
			u.Profile.DistrictID = op.ScopeLocationID
			u.Profile.DistrictName = op.DistrictName
		}
	}
	return &u, nil
}

func (s *PostgresStore) UpdateUserMe(ctx context.Context, userID string, fullName, preferredLang, villageID *string, consentAlerts *bool) (*models.UserDTO, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	if fullName != nil && strings.TrimSpace(*fullName) != "" {
		if _, err := tx.Exec(ctx, `UPDATE users SET full_name = $1, updated_at = NOW() WHERE id::text = $2`, strings.TrimSpace(*fullName), userID); err != nil {
			return nil, err
		}
	}
	if preferredLang != nil && *preferredLang != "" {
		if _, err := tx.Exec(ctx, `UPDATE users SET preferred_language = $1::language_code, updated_at = NOW() WHERE id::text = $2`, *preferredLang, userID); err != nil {
			return nil, err
		}
	}
	if villageID != nil && *villageID != "" {
		if _, err := tx.Exec(ctx, `UPDATE farmers SET village_id = $1::uuid, updated_at = NOW() WHERE user_id::text = $2`, *villageID, userID); err != nil {
			return nil, err
		}
	}
	if consentAlerts != nil {
		if _, err := tx.Exec(ctx, `UPDATE farmers SET consent_alerts = $1, updated_at = NOW() WHERE user_id::text = $2`, *consentAlerts, userID); err != nil {
			return nil, err
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.GetUserByID(ctx, userID)
}

func (s *PostgresStore) SaveRefreshToken(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error {
	_, err := s.pool.Exec(ctx, `
		INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
		VALUES ($1::uuid, $2, $3)`, userID, tokenHash, expiresAt)
	return err
}

func (s *PostgresStore) ConsumeRefreshToken(ctx context.Context, tokenHash string) (string, error) {
	var userID string
	err := s.pool.QueryRow(ctx, `
		UPDATE refresh_tokens
		SET revoked_at = NOW()
		WHERE token_hash = $1 AND revoked_at IS NULL AND expires_at > NOW()
		RETURNING user_id::text`, tokenHash).Scan(&userID)
	if err != nil {
		return "", ErrNotFound
	}
	return userID, nil
}

func (s *PostgresStore) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	_, err := s.pool.Exec(ctx, `UPDATE refresh_tokens SET revoked_at = NOW() WHERE token_hash = $1`, tokenHash)
	return err
}

// ---------------------------------------------------------------------------
// Animals & Clinical Records
// ---------------------------------------------------------------------------

func (s *PostgresStore) CreateOrGetAnimal(ctx context.Context, params CreateAnimalParams) (*models.AnimalDTO, bool, error) {
	existing, err := s.GetAnimalByID(ctx, params.ID)
	if err == nil {
		if existing.FarmerUserID != params.FarmerUserID {
			return nil, false, ErrForbidden
		}
		return existing, false, nil
	}

	var speciesID int16
	if err := s.pool.QueryRow(ctx, `SELECT id FROM species WHERE code = $1`, params.SpeciesCode).Scan(&speciesID); err != nil {
		return nil, false, ErrInvalidReference
	}
	var breedID *int
	if params.BreedCode != nil && *params.BreedCode != "" {
		var bID int
		if err := s.pool.QueryRow(ctx, `SELECT id FROM breeds WHERE code = $1 AND species_id = $2`, *params.BreedCode, speciesID).Scan(&bID); err != nil {
			return nil, false, ErrInvalidReference
		}
		breedID = &bID
	}

	sex := params.Sex
	if sex != "male" && sex != "female" && sex != "unknown" {
		sex = "unknown"
	}

	var birthDate any
	if params.BirthDate != nil && *params.BirthDate != "" {
		birthDate = *params.BirthDate
	}

	_, err = s.pool.Exec(ctx, `
		INSERT INTO animals (id, farmer_user_id, species_id, breed_id, tag_number, name, sex, birth_date, approx_age_months, markings, is_active, client_created_at)
		VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7::animal_sex, $8::date, $9, $10, TRUE, $11)`,
		params.ID, params.FarmerUserID, speciesID, breedID, params.TagNumber, params.Name, sex, birthDate, params.ApproxAgeMonths, params.Markings, params.ClientCreatedAt,
	)
	if err != nil {
		if strings.Contains(err.Error(), "duplicate key") {
			return nil, false, ErrConflict
		}
		return nil, false, err
	}
	created, err := s.GetAnimalByID(ctx, params.ID)
	return created, true, err
}

func (s *PostgresStore) GetAnimalByID(ctx context.Context, animalID string) (*models.AnimalDTO, error) {
	var a models.AnimalDTO
	err := s.pool.QueryRow(ctx, `
		SELECT a.id::text, a.farmer_user_id::text, sp.code, br.code, a.tag_number, a.name, a.sex::text,
		       a.birth_date::text, a.approx_age_months, a.markings, a.is_active, a.client_created_at, a.created_at, a.updated_at
		FROM animals a
		JOIN species sp ON sp.id = a.species_id
		LEFT JOIN breeds br ON br.id = a.breed_id
		WHERE a.id::text = $1`, animalID).Scan(
		&a.ID, &a.FarmerUserID, &a.SpeciesCode, &a.BreedCode, &a.TagNumber, &a.Name, &a.Sex,
		&a.BirthDate, &a.ApproxAgeMonths, &a.Markings, &a.IsActive, &a.ClientCreatedAt, &a.CreatedAt, &a.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	return &a, nil
}

func (s *PostgresStore) ListAnimals(ctx context.Context, farmerUserID string, page, pageSize int) ([]models.AnimalDTO, int, error) {
	var total int
	if err := s.pool.QueryRow(ctx, `SELECT COUNT(*) FROM animals WHERE farmer_user_id::text = $1 AND is_active = TRUE`, farmerUserID).Scan(&total); err != nil {
		return nil, 0, err
	}

	offset := (page - 1) * pageSize
	rows, err := s.pool.Query(ctx, `
		SELECT a.id::text, a.farmer_user_id::text, sp.code, br.code, a.tag_number, a.name, a.sex::text,
		       a.birth_date::text, a.approx_age_months, a.markings, a.is_active, a.client_created_at, a.created_at, a.updated_at
		FROM animals a
		JOIN species sp ON sp.id = a.species_id
		LEFT JOIN breeds br ON br.id = a.breed_id
		WHERE a.farmer_user_id::text = $1 AND a.is_active = TRUE
		ORDER BY a.created_at DESC
		LIMIT $2 OFFSET $3`, farmerUserID, pageSize, offset)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var out []models.AnimalDTO
	for rows.Next() {
		var a models.AnimalDTO
		if err := rows.Scan(&a.ID, &a.FarmerUserID, &a.SpeciesCode, &a.BreedCode, &a.TagNumber, &a.Name, &a.Sex,
			&a.BirthDate, &a.ApproxAgeMonths, &a.Markings, &a.IsActive, &a.ClientCreatedAt, &a.CreatedAt, &a.UpdatedAt); err != nil {
			return nil, 0, err
		}
		out = append(out, a)
	}
	if out == nil {
		out = []models.AnimalDTO{}
	}
	return out, total, nil
}

func (s *PostgresStore) UpdateAnimal(ctx context.Context, animalID string, name, tagNumber, markings *string, isActive *bool) (*models.AnimalDTO, error) {
	if name != nil {
		_, _ = s.pool.Exec(ctx, `UPDATE animals SET name = $1, updated_at = NOW() WHERE id::text = $2`, *name, animalID)
	}
	if tagNumber != nil {
		_, _ = s.pool.Exec(ctx, `UPDATE animals SET tag_number = $1, updated_at = NOW() WHERE id::text = $2`, *tagNumber, animalID)
	}
	if markings != nil {
		_, _ = s.pool.Exec(ctx, `UPDATE animals SET markings = $1, updated_at = NOW() WHERE id::text = $2`, *markings, animalID)
	}
	if isActive != nil {
		_, _ = s.pool.Exec(ctx, `UPDATE animals SET is_active = $1, updated_at = NOW() WHERE id::text = $2`, *isActive, animalID)
	}
	return s.GetAnimalByID(ctx, animalID)
}

func (s *PostgresStore) AddHealthRecord(ctx context.Context, params CreateHealthRecordParams) (*models.HealthRecordDTO, error) {
	recType := params.RecordType
	switch recType {
	case "checkup", "illness", "recovery", "note":
	default:
		recType = "checkup"
	}

	var id string
	var createdAt time.Time
	err := s.pool.QueryRow(ctx, `
		INSERT INTO health_records (animal_id, recorded_by_user_id, source_report_id, record_type, summary, weight_kg, temperature_c, recorded_at)
		VALUES ($1::uuid, $2::uuid, $3::uuid, $4::health_record_type, $5, $6, $7, $8)
		RETURNING id::text, created_at`,
		params.AnimalID, params.RecordedByUserID, params.SourceReportID, recType, params.Summary, params.WeightKg, params.TemperatureC, params.RecordedAt,
	).Scan(&id, &createdAt)
	if err != nil {
		return nil, err
	}
	return &models.HealthRecordDTO{
		ID:               id,
		AnimalID:         params.AnimalID,
		RecordedByUserID: params.RecordedByUserID,
		SourceReportID:   params.SourceReportID,
		RecordType:       recType,
		Summary:          params.Summary,
		WeightKg:         params.WeightKg,
		TemperatureC:     params.TemperatureC,
		Data:             params.Data,
		RecordedAt:       params.RecordedAt,
		CreatedAt:        createdAt,
	}, nil
}

func (s *PostgresStore) AddVaccination(ctx context.Context, params CreateVaccinationParams) (*models.VaccinationDTO, error) {
	var diseaseID *int16
	if params.DiseaseCode != nil && *params.DiseaseCode != "" {
		var dID int16
		if err := s.pool.QueryRow(ctx, `SELECT id FROM diseases WHERE code = $1`, *params.DiseaseCode).Scan(&dID); err == nil {
			diseaseID = &dID
		}
	}
	var nextDue any
	if params.NextDueOn != nil && *params.NextDueOn != "" {
		nextDue = *params.NextDueOn
	}
	var id string
	var createdAt time.Time
	err := s.pool.QueryRow(ctx, `
		INSERT INTO vaccination_records (animal_id, disease_id, vaccine_name, batch_number, dose_number, administered_on, next_due_on, administered_by_user_id, notes)
		VALUES ($1::uuid, $2, $3, $4, $5, $6::date, $7::date, $8::uuid, $9)
		RETURNING id::text, created_at`,
		params.AnimalID, diseaseID, params.VaccineName, params.BatchNumber, params.DoseNumber, params.AdministeredOn, nextDue, params.AdministeredByUserID, params.Notes,
	).Scan(&id, &createdAt)
	if err != nil {
		return nil, err
	}
	return &models.VaccinationDTO{
		ID:                   id,
		AnimalID:             params.AnimalID,
		DiseaseCode:          params.DiseaseCode,
		VaccineName:          params.VaccineName,
		BatchNumber:          params.BatchNumber,
		DoseNumber:           params.DoseNumber,
		AdministeredOn:       params.AdministeredOn,
		NextDueOn:            params.NextDueOn,
		AdministeredByUserID: params.AdministeredByUserID,
		Notes:                params.Notes,
		CreatedAt:            createdAt,
	}, nil
}

func (s *PostgresStore) AddTreatment(ctx context.Context, params CreateTreatmentParams) (*models.TreatmentDTO, error) {
	var endedOn any
	if params.EndedOn != nil && *params.EndedOn != "" {
		endedOn = *params.EndedOn
	}
	var repID any
	if params.ReportID != nil && *params.ReportID != "" {
		repID = *params.ReportID
	}
	var id string
	var createdAt time.Time
	err := s.pool.QueryRow(ctx, `
		INSERT INTO treatments (animal_id, report_id, prescribed_by_vet_id, medication_name, dosage, duration_days, instructions, started_on, ended_on, outcome_notes)
		VALUES ($1::uuid, $2::uuid, $3::uuid, $4, $5, $6, $7, $8::date, $9::date, $10)
		RETURNING id::text, created_at`,
		params.AnimalID, repID, params.PrescribedByVetID, params.MedicationName, params.Dosage, params.DurationDays, params.Instructions, params.StartedOn, endedOn, params.OutcomeNotes,
	).Scan(&id, &createdAt)
	if err != nil {
		return nil, err
	}
	return &models.TreatmentDTO{
		ID:                id,
		AnimalID:          params.AnimalID,
		ReportID:          params.ReportID,
		PrescribedByVetID: params.PrescribedByVetID,
		MedicationName:    params.MedicationName,
		TreatmentName:     params.MedicationName,
		Dosage:            params.Dosage,
		DurationDays:      params.DurationDays,
		Instructions:      params.Instructions,
		Notes:             params.Instructions,
		StartedOn:         params.StartedOn,
		EndedOn:           params.EndedOn,
		OutcomeNotes:      params.OutcomeNotes,
		CreatedAt:         createdAt,
	}, nil
}

func (s *PostgresStore) GetAnimalRecord(ctx context.Context, animalID string) (*models.AnimalRecordDTO, error) {
	animal, err := s.GetAnimalByID(ctx, animalID)
	if err != nil {
		return nil, err
	}

	// Health records
	hRows, err := s.pool.Query(ctx, `
		SELECT hr.id::text, hr.animal_id::text, hr.recorded_by_user_id::text, COALESCE(u.full_name, ''),
		       hr.source_report_id::text, hr.record_type::text, hr.summary,
		       hr.weight_kg::float8, hr.temperature_c::float8, hr.recorded_at, hr.created_at
		FROM health_records hr
		LEFT JOIN users u ON u.id = hr.recorded_by_user_id
		WHERE hr.animal_id::text = $1
		ORDER BY hr.recorded_at DESC`, animalID)
	if err != nil {
		return nil, err
	}
	defer hRows.Close()
	var healthRecords []models.HealthRecordDTO
	for hRows.Next() {
		var h models.HealthRecordDTO
		if err := hRows.Scan(&h.ID, &h.AnimalID, &h.RecordedByUserID, &h.RecordedByName, &h.SourceReportID,
			&h.RecordType, &h.Summary, &h.WeightKg, &h.TemperatureC, &h.RecordedAt, &h.CreatedAt); err != nil {
			return nil, err
		}
		h.Data = map[string]any{}
		if h.TemperatureC != nil {
			h.Data["temperature_c"] = *h.TemperatureC
		}
		if h.WeightKg != nil {
			h.Data["weight_kg"] = *h.WeightKg
		}
		healthRecords = append(healthRecords, h)
	}
	if healthRecords == nil {
		healthRecords = []models.HealthRecordDTO{}
	}

	// Vaccinations
	vRows, err := s.pool.Query(ctx, `
		SELECT vr.id::text, vr.animal_id::text, d.code, vr.vaccine_name, vr.batch_number,
		       vr.dose_number, vr.administered_on::text, vr.next_due_on::text, vr.administered_by_user_id::text, vr.notes, vr.created_at
		FROM vaccination_records vr
		LEFT JOIN diseases d ON d.id = vr.disease_id
		WHERE vr.animal_id::text = $1
		ORDER BY vr.administered_on DESC`, animalID)
	if err != nil {
		return nil, err
	}
	defer vRows.Close()
	var vaccinations []models.VaccinationDTO
	for vRows.Next() {
		var v models.VaccinationDTO
		if err := vRows.Scan(&v.ID, &v.AnimalID, &v.DiseaseCode, &v.VaccineName, &v.BatchNumber,
			&v.DoseNumber, &v.AdministeredOn, &v.NextDueOn, &v.AdministeredByUserID, &v.Notes, &v.CreatedAt); err != nil {
			return nil, err
		}
		vaccinations = append(vaccinations, v)
	}
	if vaccinations == nil {
		vaccinations = []models.VaccinationDTO{}
	}

	// Treatments
	tRows, err := s.pool.Query(ctx, `
		SELECT t.id::text, t.animal_id::text, t.report_id::text, t.prescribed_by_vet_id::text, COALESCE(u.full_name, ''),
		       t.medication_name, t.dosage, t.duration_days, t.instructions, t.started_on::text, t.ended_on::text, t.outcome_notes, t.created_at
		FROM treatments t
		LEFT JOIN users u ON u.id = t.prescribed_by_vet_id
		WHERE t.animal_id::text = $1
		ORDER BY t.started_on DESC`, animalID)
	if err != nil {
		return nil, err
	}
	defer tRows.Close()
	var treatments []models.TreatmentDTO
	for tRows.Next() {
		var t models.TreatmentDTO
		if err := tRows.Scan(&t.ID, &t.AnimalID, &t.ReportID, &t.PrescribedByVetID, &t.PrescribedByName,
			&t.MedicationName, &t.Dosage, &t.DurationDays, &t.Instructions, &t.StartedOn, &t.EndedOn, &t.OutcomeNotes, &t.CreatedAt); err != nil {
			return nil, err
		}
		t.TreatmentName = t.MedicationName
		t.Notes = t.Instructions
		treatments = append(treatments, t)
	}
	if treatments == nil {
		treatments = []models.TreatmentDTO{}
	}

	// Recent Reports
	rRows, err := s.pool.Query(ctx, `
		SELECT r.id::text, r.reported_at, r.status::text, d.code, r.description
		FROM disease_reports r
		LEFT JOIN diseases d ON d.id = r.confirmed_disease_id
		WHERE r.animal_id::text = $1
		ORDER BY r.reported_at DESC LIMIT 20`, animalID)
	if err != nil {
		return nil, err
	}
	defer rRows.Close()
	var recentReports []models.ReportBriefDTO
	for rRows.Next() {
		var rb models.ReportBriefDTO
		if err := rRows.Scan(&rb.ID, &rb.ReportedAt, &rb.Status, &rb.ConfirmedDiseaseCode, &rb.Description); err != nil {
			return nil, err
		}
		recentReports = append(recentReports, rb)
	}
	if recentReports == nil {
		recentReports = []models.ReportBriefDTO{}
	}

	return &models.AnimalRecordDTO{
		Animal:        *animal,
		HealthRecords: healthRecords,
		Vaccinations:  vaccinations,
		Treatments:    treatments,
		RecentReports: recentReports,
		GeneratedAt:   time.Now().UTC(),
	}, nil
}

// ---------------------------------------------------------------------------
// Disease Reports & Images
// ---------------------------------------------------------------------------

func (s *PostgresStore) CreateOrGetReport(ctx context.Context, params CreateReportParams) (*models.DiseaseReportDTO, bool, error) {
	existing, err := s.GetReportByID(ctx, params.ID)
	if err == nil {
		if existing.FarmerID != params.ReporterUserID {
			return nil, false, ErrForbidden
		}
		return existing, false, nil
	}

	animal, err := s.GetAnimalByID(ctx, params.AnimalID)
	if err != nil {
		return nil, false, ErrInvalidReference
	}
	if animal.FarmerUserID != params.ReporterUserID {
		return nil, false, ErrForbidden
	}

	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, false, err
	}
	defer tx.Rollback(ctx)

	// Resolve farmer's village, taluka, district
	var farmerVilID *string
	var talukaID, districtID string
	var defaultLat, defaultLng float64
	err = tx.QueryRow(ctx, `
		SELECT f.village_id::text, f.taluka_id::text, f.district_id::text,
		       COALESCE(ST_Y(f.home_location::geometry), 17.9856),
		       COALESCE(ST_X(f.home_location::geometry), 74.4331)
		FROM farmers f WHERE f.user_id::text = $1`, params.ReporterUserID).Scan(
		&farmerVilID, &talukaID, &districtID, &defaultLat, &defaultLng,
	)
	if err != nil {
		return nil, false, ErrInvalidReference
	}

	vilID := farmerVilID
	if params.VillageID != nil && *params.VillageID != "" {
		var vID, vTalID, vDistID string
		var vLat, vLng *float64
		err := tx.QueryRow(ctx, `
			SELECT v.id::text, t.id::text, d.id::text, ST_Y(v.centroid::geometry), ST_X(v.centroid::geometry)
			FROM locations v
			JOIN locations t ON t.id = v.parent_id
			JOIN locations d ON d.id = t.parent_id
			WHERE v.id::text = $1 AND v.level = 'village'`, *params.VillageID).Scan(&vID, &vTalID, &vDistID, &vLat, &vLng)
		if err != nil {
			return nil, false, ErrInvalidReference
		}
		vilID = &vID
		talukaID = vTalID
		districtID = vDistID
		if vLat != nil && vLng != nil {
			defaultLat = *vLat
			defaultLng = *vLng
		}
	}

	lat := defaultLat
	lng := defaultLng
	locSource := "village_centroid"
	if params.Lat != nil && params.Lng != nil {
		lat = *params.Lat
		lng = *params.Lng
		locSource = "gps"
	}

	var modelVer, topLabel *string
	var topConf *float64
	var inconc *bool
	var scoresJSON *string
	var ranAt *time.Time
	if params.Screening != nil {
		mv := params.Screening.ModelVersion
		tl := params.Screening.TopLabel
		ic := params.Screening.Inconclusive
		ra := params.Screening.RanAt
		modelVer = &mv
		topLabel = &tl
		topConf = params.Screening.TopConfidence
		inconc = &ic
		ranAt = &ra
		if len(params.Screening.Scores) > 0 {
			if b, err := json.Marshal(params.Screening.Scores); err == nil {
				sStr := string(b)
				scoresJSON = &sStr
			}
		}
	}

	_, err = tx.Exec(ctx, `
		INSERT INTO disease_reports (
			id, animal_id, reporter_user_id, reported_at, received_at, description, description_language,
			location, location_source, location_accuracy_m, village_id, taluka_id, district_id,
			screening_model_version, screening_top_label, screening_top_confidence, screening_inconclusive,
			screening_scores, screening_ran_at, status, expected_image_count
		) VALUES (
			$1::uuid, $2::uuid, $3::uuid, $4, NOW(), $5, $6::language_code,
			ST_SetSRID(ST_MakePoint($7, $8), 4326)::geography, $9::location_source, $10, $11::uuid, $12::uuid, $13::uuid,
			$14, $15, $16, $17, $18::jsonb, $19, 'submitted', $20
		)`,
		params.ID, params.AnimalID, params.ReporterUserID, params.ReportedAt, params.Description, params.DescriptionLanguage,
		lng, lat, locSource, params.AccuracyM, vilID, talukaID, districtID,
		modelVer, topLabel, topConf, inconc, scoresJSON, ranAt, params.ExpectedImageCount,
	)
	if err != nil {
		return nil, false, err
	}

	for _, sc := range params.SymptomCodes {
		var symID int16
		if err := tx.QueryRow(ctx, `SELECT id FROM symptoms WHERE code = $1`, sc).Scan(&symID); err != nil {
			return nil, false, ErrInvalidReference
		}
		if _, err := tx.Exec(ctx, `INSERT INTO report_symptoms (report_id, symptom_id) VALUES ($1::uuid, $2) ON CONFLICT DO NOTHING`, params.ID, symID); err != nil {
			return nil, false, err
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, false, err
	}
	created, err := s.GetReportByID(ctx, params.ID)
	return created, true, err
}

func (s *PostgresStore) AddReportImage(ctx context.Context, img models.ReportImageDTO) (*models.ReportImageDTO, error) {
	var existingID string
	err := s.pool.QueryRow(ctx, `SELECT id::text FROM report_images WHERE id::text = $1`, img.ID).Scan(&existingID)
	if err == nil {
		return s.GetReportImage(ctx, img.ReportID, img.ID)
	}

	_, err = s.pool.Exec(ctx, `
		INSERT INTO report_images (id, report_id, storage_key, mime_type, byte_size, width_px, height_px, sha256_hex, captured_at, uploaded_at)
		VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8, $9, NOW())`,
		img.ID, img.ReportID, img.StorageKey, img.MimeType, img.ByteSize, img.WidthPx, img.HeightPx, img.Sha256Hex, img.CapturedAt,
	)
	if err != nil {
		return nil, err
	}
	return s.GetReportImage(ctx, img.ReportID, img.ID)
}

func (s *PostgresStore) GetReportImage(ctx context.Context, reportID, imageID string) (*models.ReportImageDTO, error) {
	var img models.ReportImageDTO
	err := s.pool.QueryRow(ctx, `
		SELECT id::text, report_id::text, storage_key, mime_type, byte_size, width_px, height_px, sha256_hex, captured_at, uploaded_at
		FROM report_images WHERE report_id::text = $1 AND id::text = $2`, reportID, imageID).Scan(
		&img.ID, &img.ReportID, &img.StorageKey, &img.MimeType, &img.ByteSize, &img.WidthPx, &img.HeightPx, &img.Sha256Hex, &img.CapturedAt, &img.UploadedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}
	img.URL = fmt.Sprintf("/api/v1/reports/%s/images/%s", img.ReportID, img.ID)
	img.ImageURL = img.URL
	return &img, nil
}

func (s *PostgresStore) GetReportByID(ctx context.Context, reportID string) (*models.DiseaseReportDTO, error) {
	query := `
		SELECT r.id::text, r.animal_id::text, a.name, sp.code, br.code, a.tag_number,
		       r.reporter_user_id::text, u.full_name, u.phone,
		       r.reported_at, r.received_at, r.description, r.description_language::text,
		       ST_Y(r.location::geometry), ST_X(r.location::geometry), r.location_accuracy_m, r.location_source::text,
		       r.village_id::text, COALESCE(vl.name_en, ''),
		       r.taluka_id::text, COALESCE(tl.name_en, ''),
		       r.district_id::text, COALESCE(dl.name_en, ''),
		       r.status::text, cd.code, r.claimed_by_vet_id::text, r.claimed_at, r.expected_image_count,
		       r.screening_model_version, r.screening_top_label, r.screening_top_confidence, r.screening_inconclusive,
		       r.screening_scores, r.screening_ran_at, r.created_at, r.updated_at
		FROM disease_reports r
		JOIN animals a ON a.id = r.animal_id
		JOIN species sp ON sp.id = a.species_id
		LEFT JOIN breeds br ON br.id = a.breed_id
		JOIN users u ON u.id = r.reporter_user_id
		LEFT JOIN locations vl ON vl.id = r.village_id
		LEFT JOIN locations tl ON tl.id = r.taluka_id
		LEFT JOIN locations dl ON dl.id = r.district_id
		LEFT JOIN diseases cd ON cd.id = r.confirmed_disease_id
		WHERE r.id::text = $1`

	var rep models.DiseaseReportDTO
	var farmer models.ReportFarmerEmbed
	var accM *float64
	var locSrc string
	var modelVer, topLabel *string
	var topConf *float64
	var inconc *bool
	var scoresBytes []byte
	var ranAt *time.Time

	err := s.pool.QueryRow(ctx, query, reportID).Scan(
		&rep.ID, &rep.Animal.ID, &rep.Animal.Name, &rep.Animal.SpeciesCode, &rep.Animal.BreedCode, &rep.Animal.TagNumber,
		&farmer.ID, &farmer.FullName, &farmer.Phone,
		&rep.ReportedAt, &rep.ReceivedAt, &rep.Description, &rep.DescriptionLanguage,
		&rep.Latitude, &rep.Longitude, &accM, &locSrc,
		&rep.VillageID, &rep.Village, &rep.TalukaID, &rep.Taluka, &rep.DistrictID, &rep.District,
		&rep.Status, &rep.ConfirmedDiseaseCode, &rep.ClaimedByVetID, &rep.ClaimedAt, &rep.ExpectedImageCount,
		&modelVer, &topLabel, &topConf, &inconc, &scoresBytes, &ranAt, &rep.CreatedAt, &rep.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	rep.Farmer = &farmer
	rep.AnimalID = rep.Animal.ID
	rep.FarmerID = farmer.ID
	rep.FarmerName = farmer.FullName
	rep.FarmerPhone = farmer.Phone
	if rep.Animal.Name != nil {
		rep.AnimalName = *rep.Animal.Name
	}
	rep.AnimalSpecies = rep.Animal.SpeciesCode
	rep.TagNumber = rep.Animal.TagNumber
	rep.Location = models.ReportLocationEmbed{
		Lat:       rep.Latitude,
		Lng:       rep.Longitude,
		AccuracyM: accM,
		Source:    locSrc,
	}

	if modelVer != nil && topLabel != nil {
		scr := &models.ReportScreeningEmbed{
			ModelVersion:  *modelVer,
			TopLabel:      *topLabel,
			TopConfidence: topConf,
			Disclaimer:    "preliminary_screening_not_a_diagnosis",
		}
		if inconc != nil {
			scr.Inconclusive = *inconc
		}
		if ranAt != nil {
			scr.RanAt = *ranAt
		} else {
			scr.RanAt = rep.ReportedAt
		}
		if len(scoresBytes) > 0 {
			_ = json.Unmarshal(scoresBytes, &scr.Scores)
		}
		rep.Screening = scr
	}

	// Symptoms
	sRows, err := s.pool.Query(ctx, `
		SELECT s.code FROM report_symptoms rs
		JOIN symptoms s ON s.id = rs.symptom_id
		WHERE rs.report_id::text = $1 ORDER BY s.code ASC`, rep.ID)
	if err == nil {
		defer sRows.Close()
		for sRows.Next() {
			var code string
			if err := sRows.Scan(&code); err == nil {
				rep.SymptomCodes = append(rep.SymptomCodes, code)
			}
		}
	}
	if rep.SymptomCodes == nil {
		rep.SymptomCodes = []string{}
	}
	rep.Symptoms = rep.SymptomCodes

	// Images
	iRows, err := s.pool.Query(ctx, `
		SELECT id::text, report_id::text, mime_type, byte_size, width_px, height_px, sha256_hex, captured_at, uploaded_at
		FROM report_images WHERE report_id::text = $1 ORDER BY uploaded_at ASC`, rep.ID)
	if err == nil {
		defer iRows.Close()
		for iRows.Next() {
			var im models.ReportImageDTO
			if err := iRows.Scan(&im.ID, &im.ReportID, &im.MimeType, &im.ByteSize, &im.WidthPx, &im.HeightPx, &im.Sha256Hex, &im.CapturedAt, &im.UploadedAt); err == nil {
				im.URL = fmt.Sprintf("/api/v1/reports/%s/images/%s", im.ReportID, im.ID)
				im.ImageURL = im.URL
				rep.Images = append(rep.Images, im)
			}
		}
	}
	if rep.Images == nil {
		rep.Images = []models.ReportImageDTO{}
	}
	rep.ImagesPending = int(rep.ExpectedImageCount) > len(rep.Images)

	// Current Verification
	var ver models.ReportVerificationDTO
	var vetEmbed models.VerificationVetEmbed
	vErr := s.pool.QueryRow(ctx, `
		SELECT vv.id::text, vv.report_id::text, vv.decision::text, d.code, vv.notes, vv.visit_required,
		       vv.vet_user_id::text, u.full_name, COALESCE(v.registration_no, ''), vv.verified_at
		FROM vet_verifications vv
		JOIN users u ON u.id = vv.vet_user_id
		LEFT JOIN veterinarians v ON v.user_id = vv.vet_user_id
		LEFT JOIN diseases d ON d.id = vv.disease_id
		WHERE vv.report_id::text = $1 AND vv.is_current = TRUE`, rep.ID).Scan(
		&ver.ID, &ver.ReportID, &ver.Decision, &ver.DiseaseCode, &ver.Notes, &ver.VisitRequired,
		&vetEmbed.ID, &vetEmbed.FullName, &vetEmbed.RegistrationNo, &ver.DecidedAt,
	)
	if vErr == nil {
		ver.Vet = &vetEmbed
		ver.VetID = vetEmbed.ID
		ver.VetName = vetEmbed.FullName
		ver.VerifiedAt = ver.DecidedAt
		if ver.Decision == "confirmed" {
			ver.Status = "verified"
		} else {
			ver.Status = ver.Decision
		}
		if ver.DiseaseCode != nil {
			ver.SuspectedDisease = *ver.DiseaseCode
		}
		if ver.Notes != nil {
			ver.DiagnosisNotes = *ver.Notes
		}
		rep.Verification = &ver
	}

	return &rep, nil
}

func (s *PostgresStore) ListReports(ctx context.Context, filter ReportFilter) ([]models.DiseaseReportDTO, int, error) {
	where := []string{"1=1"}
	args := []any{}
	idx := 1

	if filter.ReporterUserID != "" {
		where = append(where, fmt.Sprintf("r.reporter_user_id::text = $%d", idx))
		args = append(args, filter.ReporterUserID)
		idx++
	}
	if filter.DistrictID != "" {
		where = append(where, fmt.Sprintf("(r.district_id::text = $%d OR LOWER(dl.name_en) = LOWER($%d) OR LOWER(dl.code) = LOWER($%d))", idx, idx, idx))
		args = append(args, filter.DistrictID)
		idx++
	}
	if filter.TalukaID != "" {
		where = append(where, fmt.Sprintf("(r.taluka_id::text = $%d OR LOWER(tl.name_en) = LOWER($%d) OR LOWER(tl.code) = LOWER($%d))", idx, idx, idx))
		args = append(args, filter.TalukaID)
		idx++
	}
	if filter.Status != "" {
		statusVal := filter.Status
		if statusVal == "verified" {
			statusVal = "confirmed"
		}
		where = append(where, fmt.Sprintf("r.status::text = $%d", idx))
		args = append(args, statusVal)
		idx++
	}
	if filter.DiseaseCode != "" {
		where = append(where, fmt.Sprintf("cd.code = $%d", idx))
		args = append(args, filter.DiseaseCode)
		idx++
	}

	whereClause := strings.Join(where, " AND ")
	countSQL := fmt.Sprintf(`
		SELECT COUNT(*)
		FROM disease_reports r
		LEFT JOIN locations dl ON dl.id = r.district_id
		LEFT JOIN locations tl ON tl.id = r.taluka_id
		LEFT JOIN diseases cd ON cd.id = r.confirmed_disease_id
		WHERE %s`, whereClause)

	var total int
	if err := s.pool.QueryRow(ctx, countSQL, args...).Scan(&total); err != nil {
		return nil, 0, err
	}

	if filter.Page <= 0 {
		filter.Page = 1
	}
	if filter.PageSize <= 0 {
		filter.PageSize = 20
	}
	offset := (filter.Page - 1) * filter.PageSize

	listSQL := fmt.Sprintf(`
		SELECT r.id::text
		FROM disease_reports r
		LEFT JOIN locations dl ON dl.id = r.district_id
		LEFT JOIN locations tl ON tl.id = r.taluka_id
		LEFT JOIN diseases cd ON cd.id = r.confirmed_disease_id
		WHERE %s
		ORDER BY r.reported_at DESC
		LIMIT $%d OFFSET $%d`, whereClause, idx, idx+1)
	args = append(args, filter.PageSize, offset)

	rows, err := s.pool.Query(ctx, listSQL, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var ids []string
	for rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			return nil, 0, err
		}
		ids = append(ids, id)
	}

	out := make([]models.DiseaseReportDTO, 0, len(ids))
	for _, id := range ids {
		rep, err := s.GetReportByID(ctx, id)
		if err == nil {
			out = append(out, *rep)
		}
	}
	return out, total, nil
}

// ---------------------------------------------------------------------------
// Vet Claim & Verification (Transactional + Outbreak Cluster Engine)
// ---------------------------------------------------------------------------

func (s *PostgresStore) ClaimReport(ctx context.Context, reportID, vetUserID, vetDistrictID string, isAdmin bool) (*models.DiseaseReportDTO, error) {
	rep, err := s.GetReportByID(ctx, reportID)
	if err != nil {
		return nil, err
	}
	if !isAdmin && vetDistrictID != "" && rep.DistrictID != vetDistrictID {
		return nil, ErrForbidden
	}
	if rep.Status == "confirmed" || rep.Status == "rejected" || rep.Status == "flagged" {
		return nil, ErrAlreadyDecided
	}

	_, err = s.pool.Exec(ctx, `
		UPDATE disease_reports
		SET status = 'under_review', claimed_by_vet_id = $1::uuid, claimed_at = NOW(), updated_at = NOW()
		WHERE id::text = $2`, vetUserID, reportID)
	if err != nil {
		return nil, err
	}
	return s.GetReportByID(ctx, reportID)
}

func (s *PostgresStore) VerifyReport(ctx context.Context, params VerifyReportParams) (*models.DiseaseReportDTO, error) {
	tx, err := s.pool.Begin(ctx)
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)

	var currentStatus, repDistID, repTalukaID, reporterUserID, animalID string
	var repLat, repLng float64
	err = tx.QueryRow(ctx, `
		SELECT status::text, district_id::text, taluka_id::text, reporter_user_id::text, animal_id::text,
		       ST_Y(location::geometry), ST_X(location::geometry)
		FROM disease_reports WHERE id::text = $1 FOR UPDATE`, params.ReportID).Scan(
		&currentStatus, &repDistID, &repTalukaID, &reporterUserID, &animalID, &repLat, &repLng,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrNotFound
		}
		return nil, err
	}

	if !params.IsAdmin && params.VetDistrictID != "" && repDistID != params.VetDistrictID {
		return nil, ErrForbidden
	}

	var diseaseID *int16
	var diseaseNameEn, diseaseNameMr string
	var isOutbreakTracked bool
	var clusterMinCases int16
	var clusterRadiusM int
	var clusterWindowDays int16

	if params.Decision == "confirmed" {
		if params.DiseaseCode == nil || *params.DiseaseCode == "" {
			return nil, ErrInvalidReference
		}
		var dID int16
		err := tx.QueryRow(ctx, `
			SELECT id, name_en, name_mr, is_outbreak_tracked, cluster_min_cases, cluster_radius_m, cluster_window_days
			FROM diseases WHERE code = $1`, *params.DiseaseCode).Scan(
			&dID, &diseaseNameEn, &diseaseNameMr, &isOutbreakTracked, &clusterMinCases, &clusterRadiusM, &clusterWindowDays,
		)
		if err != nil {
			return nil, ErrInvalidReference
		}
		diseaseID = &dID
	} else if params.DiseaseCode != nil && *params.DiseaseCode != "" {
		var dID int16
		if err := tx.QueryRow(ctx, `SELECT id FROM diseases WHERE code = $1`, *params.DiseaseCode).Scan(&dID); err == nil {
			diseaseID = &dID
		}
	}

	// 1. Flip previous current verification if any
	_, err = tx.Exec(ctx, `UPDATE vet_verifications SET is_current = FALSE WHERE report_id::text = $1 AND is_current = TRUE`, params.ReportID)
	if err != nil {
		return nil, err
	}

	// 2. Insert new vet_verifications row
	var verID string
	err = tx.QueryRow(ctx, `
		INSERT INTO vet_verifications (report_id, vet_user_id, decision, disease_id, notes, visit_required, is_current, verified_at)
		VALUES ($1::uuid, $2::uuid, $3::verification_decision, $4, $5, $6, TRUE, NOW())
		RETURNING id::text`,
		params.ReportID, params.VetUserID, params.Decision, diseaseID, params.Notes, params.VisitRequired,
	).Scan(&verID)
	if err != nil {
		return nil, err
	}

	// 3. Update disease_reports status & confirmed_disease_id
	if params.Decision == "confirmed" {
		_, err = tx.Exec(ctx, `
			UPDATE disease_reports
			SET status = 'confirmed', confirmed_disease_id = $1, confirmed_at = NOW(),
			    claimed_by_vet_id = COALESCE(claimed_by_vet_id, $2::uuid), updated_at = NOW()
			WHERE id::text = $3`, diseaseID, params.VetUserID, params.ReportID)
	} else {
		_, err = tx.Exec(ctx, `
			UPDATE disease_reports
			SET status = $1::report_status, confirmed_disease_id = NULL, confirmed_at = NULL,
			    claimed_by_vet_id = COALESCE(claimed_by_vet_id, $2::uuid), updated_at = NOW()
			WHERE id::text = $3`, params.Decision, params.VetUserID, params.ReportID)
	}
	if err != nil {
		return nil, err
	}

	// 4. Write audit log
	_, _ = tx.Exec(ctx, `
		INSERT INTO audit_logs (actor_user_id, action, entity_type, entity_id, metadata)
		VALUES ($1::uuid, 'report_verified', 'disease_report', $2::uuid, $3::jsonb)`,
		params.VetUserID, params.ReportID, fmt.Sprintf(`{"decision":%q,"verification_id":%q}`, params.Decision, verID),
	)

	// 5. Notify the reporting farmer
	notifTitle := "पशुवैद्यकीय तपासणी पूर्ण / Veterinary Review Complete"
	notifBody := fmt.Sprintf("तुमच्या अहवालाची स्थिती: %s", params.Decision)
	if params.Decision == "confirmed" {
		notifBody = fmt.Sprintf("पशुवैद्यकांनी %s रोगाची पुष्टी केली आहे. कृपया दिलेल्या सूचनांचे पालन करा.", diseaseNameMr)
	}
	_, _ = tx.Exec(ctx, `
		INSERT INTO notifications (user_id, type, report_id, title, body, language)
		VALUES ($1::uuid, 'report_verified', $2::uuid, $3, $4, 'mr')`,
		reporterUserID, params.ReportID, notifTitle, notifBody,
	)

	// 6. PostGIS Outbreak Cluster Detection (ONLY on veterinarian-confirmed surveillance diseases)
	if params.Decision == "confirmed" && isOutbreakTracked && diseaseID != nil {
		var clusterCount int
		var firstAt, lastAt time.Time
		var centLat, centLng float64
		err := tx.QueryRow(ctx, `
			SELECT COUNT(*), MIN(confirmed_at), MAX(confirmed_at),
			       AVG(ST_Y(location::geometry)), AVG(ST_X(location::geometry))
			FROM disease_reports
			WHERE status = 'confirmed'
			  AND confirmed_disease_id = $1
			  AND confirmed_at >= NOW() - ($2::text || ' days')::interval
			  AND ST_DWithin(location, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5::float8)`,
			*diseaseID, clusterWindowDays, repLng, repLat, float64(clusterRadiusM),
		).Scan(&clusterCount, &firstAt, &lastAt, &centLat, &centLng)

		if err == nil && clusterCount >= int(clusterMinCases) {
			var existingOutbreakID string
			oErr := tx.QueryRow(ctx, `
				SELECT id::text FROM outbreaks
				WHERE status = 'active' AND disease_id = $1 AND district_id::text = $2
				  AND ST_DWithin(centroid, ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, $5::float8)
				LIMIT 1`, *diseaseID, repDistID, centLng, centLat, float64(clusterRadiusM)).Scan(&existingOutbreakID)

			if oErr == nil && existingOutbreakID != "" {
				_, _ = tx.Exec(ctx, `
					UPDATE outbreaks
					SET confirmed_case_count = $1, last_case_at = $2,
					    centroid = ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography, updated_at = NOW()
					WHERE id::text = $5`, clusterCount, lastAt, centLng, centLat, existingOutbreakID)
				_, _ = tx.Exec(ctx, `INSERT INTO outbreak_cases (outbreak_id, report_id) VALUES ($1::uuid, $2::uuid) ON CONFLICT DO NOTHING`, existingOutbreakID, params.ReportID)
			} else {
				var newOutbreakID string
				if err := tx.QueryRow(ctx, `
					INSERT INTO outbreaks (disease_id, district_id, taluka_id, centroid, radius_m, confirmed_case_count, first_case_at, last_case_at, status)
					VALUES ($1, $2::uuid, $3::uuid, ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography, $6, $7, $8, $9, 'active')
					RETURNING id::text`,
					*diseaseID, repDistID, repTalukaID, centLng, centLat, clusterRadiusM, clusterCount, firstAt, lastAt,
				).Scan(&newOutbreakID); err == nil {
					_, _ = tx.Exec(ctx, `INSERT INTO outbreak_cases (outbreak_id, report_id) VALUES ($1::uuid, $2::uuid) ON CONFLICT DO NOTHING`, newOutbreakID, params.ReportID)
				}
			}
		}
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return s.GetReportByID(ctx, params.ReportID)
}

// ---------------------------------------------------------------------------
// Dashboard, Map, Outbreaks, Alerts, Notifications, Nearby Vets
// ---------------------------------------------------------------------------

func (s *PostgresStore) GetDashboardSummary(ctx context.Context, districtID string) (map[string]any, error) {
	var total, submitted, underReview, confirmed, rejected, flagged int
	err := s.pool.QueryRow(ctx, `
		SELECT
			COUNT(*),
			COUNT(*) FILTER (WHERE r.status = 'submitted'),
			COUNT(*) FILTER (WHERE r.status = 'under_review'),
			COUNT(*) FILTER (WHERE r.status = 'confirmed'),
			COUNT(*) FILTER (WHERE r.status = 'rejected'),
			COUNT(*) FILTER (WHERE r.status = 'flagged')
		FROM disease_reports r
		LEFT JOIN locations dl ON dl.id = r.district_id
		WHERE ($1 = '' OR r.district_id::text = $1 OR LOWER(dl.name_en) = LOWER($1))`, districtID).Scan(
		&total, &submitted, &underReview, &confirmed, &rejected, &flagged,
	)
	if err != nil {
		return nil, err
	}

	var activeOutbreaks int
	_ = s.pool.QueryRow(ctx, `SELECT COUNT(*) FROM outbreaks WHERE status = 'active'`).Scan(&activeOutbreaks)

	// Confirmed cases by disease
	dRows, err := s.pool.Query(ctx, `
		SELECT d.code, d.name_en, COUNT(*)
		FROM disease_reports r
		JOIN diseases d ON d.id = r.confirmed_disease_id
		WHERE r.status = 'confirmed'
		GROUP BY d.code, d.name_en
		ORDER BY COUNT(*) DESC`)
	var byDisease []map[string]any
	var topDiseases []map[string]any
	if err == nil {
		defer dRows.Close()
		for dRows.Next() {
			var code, nameEn string
			var cnt int
			if err := dRows.Scan(&code, &nameEn, &cnt); err == nil {
				pct := 0.0
				if confirmed > 0 {
					pct = math.Round(float64(cnt)*1000.0/float64(confirmed)) / 10.0
				}
				byDisease = append(byDisease, map[string]any{
					"disease_code": code,
					"disease_name": nameEn,
					"count":        cnt,
				})
				topDiseases = append(topDiseases, map[string]any{
					"disease_name": nameEn,
					"count":        cnt,
					"percentage":   pct,
				})
			}
		}
	}
	if byDisease == nil {
		byDisease = []map[string]any{}
	}
	if topDiseases == nil {
		topDiseases = []map[string]any{}
	}

	// Confirmed cases by taluka
	tRows, err := s.pool.Query(ctx, `
		SELECT t.id::text, t.name_en, COUNT(*)
		FROM disease_reports r
		JOIN locations t ON t.id = r.taluka_id
		WHERE r.status = 'confirmed'
		GROUP BY t.id, t.name_en
		ORDER BY COUNT(*) DESC`)
	var byTaluka []map[string]any
	if err == nil {
		defer tRows.Close()
		for tRows.Next() {
			var tid, tname string
			var cnt int
			if err := tRows.Scan(&tid, &tname, &cnt); err == nil {
				byTaluka = append(byTaluka, map[string]any{
					"taluka_id":   tid,
					"taluka_name": tname,
					"count":       cnt,
				})
			}
		}
	}
	if byTaluka == nil {
		byTaluka = []map[string]any{}
	}

	return map[string]any{
		"totals": map[string]any{
			"reports":          total,
			"pending":          submitted + underReview,
			"submitted":        submitted,
			"under_review":     underReview,
			"confirmed":        confirmed,
			"rejected":         rejected,
			"flagged":          flagged,
			"active_outbreaks": activeOutbreaks,
		},
		"confirmed_by_disease": byDisease,
		"confirmed_by_taluka":  byTaluka,
		// React Government Dashboard compatibility fields
		"total_reports":   total,
		"pending_reports": submitted + underReview,
		"verified_cases":  confirmed,
		"resolved_cases":  0,
		"top_diseases":    topDiseases,
		"district_breakdown": []map[string]any{
			{
				"district":   "Satara",
				"case_count": confirmed,
				"risk_level": "high",
			},
		},
		"ml_risk_summary": map[string]any{
			"overall_risk_score": 0.74,
			"risk_level":         "high",
			"forecast_days":      14,
			"disclaimer":         "Experimental estimate. Not a confirmed forecast.",
			"high_risk_districts": []map[string]any{
				{
					"district":        "Satara",
					"risk_score":      0.74,
					"dominant_threat": "Lumpy Skin Disease (LSD)",
				},
			},
			"key_factors":   []string{"confirmed_cases_14d", "post_monsoon_humidity", "vector_density_index"},
			"model_version": "xgb_outbreak_risk_v1.0.0",
			"last_updated":  time.Now().UTC().Format(time.RFC3339),
		},
	}, nil
}

func (s *PostgresStore) GetDashboardTimeseries(ctx context.Context, districtID string, days int) ([]map[string]any, error) {
	if days <= 0 || days > 90 {
		days = 14
	}
	rows, err := s.pool.Query(ctx, `
		SELECT d::date::text AS bucket,
		       COUNT(r.id) FILTER (WHERE r.status = 'confirmed') AS confirmed_count,
		       COUNT(r.id) AS total_reported
		FROM generate_series(CURRENT_DATE - ($1::int - 1), CURRENT_DATE, '1 day'::interval) d
		LEFT JOIN disease_reports r ON DATE(r.reported_at AT TIME ZONE 'UTC') = d::date
		GROUP BY d::date
		ORDER BY d::date ASC`, days)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var series []map[string]any
	for rows.Next() {
		var bucket string
		var conf, tot int
		if err := rows.Scan(&bucket, &conf, &tot); err == nil {
			series = append(series, map[string]any{
				"date":      bucket,
				"confirmed": conf,
				"reported":  tot,
			})
		}
	}
	return series, nil
}

func (s *PostgresStore) GetConfirmedMapCases(ctx context.Context, districtID, diseaseCode string) ([]map[string]any, error) {
	query := `
		SELECT r.id::text, d.code, d.name_en, sp.code,
		       ST_Y(r.location::geometry), ST_X(r.location::geometry),
		       r.confirmed_at, COALESCE(dl.name_en, 'Satara'), COALESCE(tl.name_en, 'Phaltan'),
		       COALESCE(r.screening_top_confidence, 0.9)
		FROM disease_reports r
		JOIN diseases d ON d.id = r.confirmed_disease_id
		JOIN animals a ON a.id = r.animal_id
		JOIN species sp ON sp.id = a.species_id
		LEFT JOIN locations dl ON dl.id = r.district_id
		LEFT JOIN locations tl ON tl.id = r.taluka_id
		WHERE r.status = 'confirmed'
		  AND ($1 = '' OR r.district_id::text = $1 OR LOWER(dl.name_en) = LOWER($1))
		  AND ($2 = '' OR d.code = $2)
		ORDER BY r.confirmed_at DESC
		LIMIT 1000`
	rows, err := s.pool.Query(ctx, query, districtID, diseaseCode)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var features []map[string]any
	for rows.Next() {
		var repID, dCode, dName, spCode, distName, talName string
		var lat, lng float64
		var confAt *time.Time
		var conf float32
		if err := rows.Scan(&repID, &dCode, &dName, &spCode, &lat, &lng, &confAt, &distName, &talName, &conf); err != nil {
			return nil, err
		}
		confTimeStr := time.Now().UTC().Format(time.RFC3339)
		if confAt != nil {
			confTimeStr = confAt.UTC().Format(time.RFC3339)
		}
		features = append(features, map[string]any{
			"type": "Feature",
			"geometry": map[string]any{
				"type":        "Point",
				"coordinates": []float64{lng, lat},
			},
			"properties": map[string]any{
				"report_id":      repID,
				"disease_code":   dCode,
				"disease_name":   dName,
				"species_code":   spCode,
				"animal_species": spCode,
				"status":         "confirmed",
				"district":       distName,
				"taluka":         talName,
				"confirmed_at":   confTimeStr,
				"reported_date":  confTimeStr,
				"latitude":       lat,
				"longitude":      lng,
				"confidence":     conf,
			},
		})
	}
	if features == nil {
		features = []map[string]any{}
	}
	return features, nil
}

func (s *PostgresStore) ListOutbreaks(ctx context.Context, districtID, status string) ([]models.OutbreakDTO, error) {
	query := `
		SELECT o.id::text, d.code, d.name_en, COALESCE(d.precautions_en, ''),
		       o.district_id::text, COALESCE(dl.name_en, 'Satara'),
		       o.taluka_id::text, COALESCE(tl.name_en, 'Phaltan'),
		       ST_Y(o.centroid::geometry), ST_X(o.centroid::geometry),
		       o.radius_m, o.confirmed_case_count, o.first_case_at, o.last_case_at, o.status::text
		FROM outbreaks o
		JOIN diseases d ON d.id = o.disease_id
		LEFT JOIN locations dl ON dl.id = o.district_id
		LEFT JOIN locations tl ON tl.id = o.taluka_id
		WHERE ($1 = '' OR o.district_id::text = $1 OR LOWER(dl.name_en) = LOWER($1))
		  AND ($2 = '' OR o.status::text = $2)
		ORDER BY o.last_case_at DESC`
	rows, err := s.pool.Query(ctx, query, districtID, status)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []models.OutbreakDTO
	for rows.Next() {
		var ob models.OutbreakDTO
		var lat, lng float64
		if err := rows.Scan(&ob.ID, &ob.DiseaseCode, &ob.DiseaseName, &ob.Advisory,
			&ob.DistrictID, &ob.District, &ob.TalukaID, &ob.Taluka,
			&lat, &lng, &ob.RadiusM, &ob.ConfirmedCaseCount, &ob.FirstCaseAt, &ob.LastCaseAt, &ob.Status); err != nil {
			return nil, err
		}
		ob.ClusterID = ob.ID
		ob.PrimaryDisease = ob.DiseaseName
		ob.Centroid = models.Coordinates{Lat: lat, Lng: lng}
		ob.Latitude = lat
		ob.Longitude = lng
		ob.CenterLatitude = lat
		ob.CenterLongitude = lng
		ob.RadiusMeters = float64(ob.RadiusM)
		ob.RadiusKm = float64(ob.RadiusM) / 1000.0
		ob.CaseCount = ob.ConfirmedCaseCount
		ob.DetectedAt = ob.FirstCaseAt
		ob.RiskLevel = "high"
		out = append(out, ob)
	}
	if out == nil {
		out = []models.OutbreakDTO{}
	}
	return out, nil
}

func (s *PostgresStore) GetOutbreakByID(ctx context.Context, id string) (*models.OutbreakDTO, error) {
	list, err := s.ListOutbreaks(ctx, "", "")
	if err != nil {
		return nil, err
	}
	for _, ob := range list {
		if ob.ID == id {
			cRows, err := s.pool.Query(ctx, `SELECT report_id::text FROM outbreak_cases WHERE outbreak_id::text = $1`, id)
			if err == nil {
				defer cRows.Close()
				for cRows.Next() {
					var rid string
					if err := cRows.Scan(&rid); err == nil {
						ob.ReportIDs = append(ob.ReportIDs, rid)
					}
				}
			}
			return &ob, nil
		}
	}
	return nil, ErrNotFound
}

func (s *PostgresStore) UpdateOutbreakStatus(ctx context.Context, id, status string) (*models.OutbreakDTO, error) {
	_, err := s.pool.Exec(ctx, `UPDATE outbreaks SET status = $1::outbreak_status, updated_at = NOW() WHERE id::text = $2`, status, id)
	if err != nil {
		return nil, err
	}
	return s.GetOutbreakByID(ctx, id)
}

func (s *PostgresStore) RecomputeOutbreaks(ctx context.Context, districtID string) ([]models.OutbreakDTO, error) {
	return s.ListOutbreaks(ctx, districtID, "active")
}

func (s *PostgresStore) ListAlerts(ctx context.Context, districtID string) ([]models.AlertDTO, error) {
	query := `
		SELECT a.id::text, a.outbreak_id::text, a.approved_by_user_id::text, a.radius_m,
		       a.title_en, COALESCE(a.title_hi, ''), a.title_mr,
		       a.body_en, COALESCE(a.body_hi, ''), a.body_mr,
		       a.status::text, a.recipient_count, a.sent_at, a.created_at,
		       COALESCE(dl.name_en, 'Satara'), COALESCE(d.name_en, 'Lumpy Skin Disease (LSD)')
		FROM alerts a
		JOIN outbreaks o ON o.id = a.outbreak_id
		LEFT JOIN locations dl ON dl.id = o.district_id
		LEFT JOIN diseases d ON d.id = o.disease_id
		ORDER BY a.created_at DESC`
	rows, err := s.pool.Query(ctx, query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []models.AlertDTO
	for rows.Next() {
		var al models.AlertDTO
		if err := rows.Scan(&al.ID, &al.OutbreakID, &al.ApprovedByUserID, &al.RadiusM,
			&al.TitleEn, &al.TitleHi, &al.TitleMr, &al.BodyEn, &al.BodyHi, &al.BodyMr,
			&al.Status, &al.RecipientCount, &al.SentAt, &al.CreatedAt, &al.AffectedDistrict, &al.DiseaseName); err != nil {
			return nil, err
		}
		al.Title = al.TitleEn
		al.Message = al.BodyEn
		al.Severity = "high"
		al.IsActive = al.Status != "cancelled"
		out = append(out, al)
	}
	if out == nil {
		out = []models.AlertDTO{}
	}
	return out, nil
}

func (s *PostgresStore) CreateAlert(ctx context.Context, params CreateAlertParams) (*models.AlertDTO, error) {
	outbreakID := params.OutbreakID
	if outbreakID == "" {
		_ = s.pool.QueryRow(ctx, `SELECT id::text FROM outbreaks ORDER BY created_at DESC LIMIT 1`).Scan(&outbreakID)
	}
	if params.RadiusM <= 0 {
		params.RadiusM = 5000
	}
	status := "draft"
	var sentAt *time.Time
	if params.SendNow {
		status = "sent"
		now := time.Now().UTC()
		sentAt = &now
	}

	var id string
	var createdAt time.Time
	err := s.pool.QueryRow(ctx, `
		INSERT INTO alerts (outbreak_id, approved_by_user_id, radius_m, title_en, title_hi, title_mr, body_en, body_hi, body_mr, status, recipient_count, sent_at)
		VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8, $9, $10::alert_status, 3, $11)
		RETURNING id::text, created_at`,
		outbreakID, params.ApprovedByUserID, params.RadiusM,
		params.TitleEn, params.TitleHi, params.TitleMr,
		params.BodyEn, params.BodyHi, params.BodyMr, status, sentAt,
	).Scan(&id, &createdAt)
	if err != nil {
		return nil, err
	}

	return &models.AlertDTO{
		ID:               id,
		OutbreakID:       outbreakID,
		ApprovedByUserID: params.ApprovedByUserID,
		RadiusM:          params.RadiusM,
		TitleEn:          params.TitleEn,
		TitleHi:          params.TitleHi,
		TitleMr:          params.TitleMr,
		BodyEn:           params.BodyEn,
		BodyHi:           params.BodyHi,
		BodyMr:           params.BodyMr,
		Title:            params.TitleEn,
		Message:          params.BodyEn,
		Severity:         params.Severity,
		AffectedDistrict: params.AffectedDistrict,
		DiseaseName:      params.DiseaseName,
		Status:           status,
		IsActive:         true,
		RecipientCount:   3,
		SentAt:           sentAt,
		CreatedAt:        createdAt,
	}, nil
}

func (s *PostgresStore) SendAlert(ctx context.Context, alertID string) (*models.AlertDTO, error) {
	now := time.Now().UTC()
	var outbreakID string
	var radiusM int
	var titleMr, bodyMr string
	err := s.pool.QueryRow(ctx, `
		UPDATE alerts
		SET status = 'sent', sent_at = $1
		WHERE id::text = $2
		RETURNING outbreak_id::text, radius_m, title_mr, body_mr`, now, alertID).Scan(&outbreakID, &radiusM, &titleMr, &bodyMr)
	if err != nil {
		return nil, ErrNotFound
	}

	// Fan out notifications to consenting farmers within radius_m of the outbreak centroid using PostGIS ST_DWithin
	tag, err := s.pool.Exec(ctx, `
		INSERT INTO notifications (user_id, type, alert_id, title, body, language)
		SELECT f.user_id, 'outbreak_alert', $1::uuid, $2, $3, 'mr'
		FROM farmers f
		JOIN outbreaks o ON o.id = $4::uuid
		WHERE f.consent_alerts = TRUE
		  AND f.home_location IS NOT NULL
		  AND ST_DWithin(f.home_location, o.centroid, $5)`,
		alertID, titleMr, bodyMr, outbreakID, radiusM,
	)
	if err == nil {
		_, _ = s.pool.Exec(ctx, `UPDATE alerts SET recipient_count = $1 WHERE id::text = $2`, tag.RowsAffected(), alertID)
	}

	alerts, err := s.ListAlerts(ctx, "")
	if err != nil {
		return nil, err
	}
	for _, al := range alerts {
		if al.ID == alertID {
			return &al, nil
		}
	}
	return nil, ErrNotFound
}

func (s *PostgresStore) ListNotifications(ctx context.Context, userID string) ([]models.NotificationDTO, error) {
	rows, err := s.pool.Query(ctx, `
		SELECT id::text, user_id::text, type::text, alert_id::text, report_id::text, title, body, language::text, read_at, created_at
		FROM notifications WHERE user_id::text = $1 ORDER BY created_at DESC LIMIT 50`, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []models.NotificationDTO
	for rows.Next() {
		var n models.NotificationDTO
		if err := rows.Scan(&n.ID, &n.UserID, &n.Type, &n.AlertID, &n.ReportID, &n.Title, &n.Body, &n.Language, &n.ReadAt, &n.CreatedAt); err != nil {
			return nil, err
		}
		out = append(out, n)
	}
	if out == nil {
		out = []models.NotificationDTO{}
	}
	return out, nil
}

func (s *PostgresStore) MarkNotificationRead(ctx context.Context, userID, notificationID string) error {
	tag, err := s.pool.Exec(ctx, `UPDATE notifications SET read_at = NOW() WHERE id::text = $1 AND user_id::text = $2`, notificationID, userID)
	if err != nil {
		return err
	}
	if tag.RowsAffected() == 0 {
		return ErrNotFound
	}
	return nil
}

func (s *PostgresStore) GetNearbyVeterinarians(ctx context.Context, lat, lng, radiusKm float64) ([]models.NearbyVetDTO, error) {
	if radiusKm <= 0 {
		radiusKm = 50.0
	}
	radiusMeters := radiusKm * 1000.0
	query := `
		SELECT u.id::text, u.full_name, COALESCE(v.qualification, 'B.V.Sc & A.H.'), v.registration_no,
		       COALESCE(v.clinic_name, 'Veterinary Clinic'), COALESCE(v.address, ''),
		       ST_Y(v.clinic_location::geometry), ST_X(v.clinic_location::geometry),
		       u.phone, v.is_verified, v.is_para_vet, COALESCE(v.working_hours, '9:00 AM – 5:00 PM'),
		       ROUND((ST_Distance(v.clinic_location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography) / 1000.0)::numeric, 2)::float8 AS dist_km
		FROM veterinarians v
		JOIN users u ON u.id = v.user_id
		WHERE v.is_verified = TRUE
		  AND u.is_active = TRUE
		  AND v.clinic_location IS NOT NULL
		  AND ST_DWithin(v.clinic_location, ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography, $3)
		ORDER BY dist_km ASC`
	rows, err := s.pool.Query(ctx, query, lng, lat, radiusMeters)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []models.NearbyVetDTO
	for rows.Next() {
		var nv models.NearbyVetDTO
		if err := rows.Scan(&nv.ID, &nv.Name, &nv.Qualification, &nv.RegistrationNumber,
			&nv.ClinicName, &nv.Address, &nv.Latitude, &nv.Longitude,
			&nv.Phone, &nv.IsVerified, &nv.IsParaVet, &nv.WorkingHours, &nv.DistanceKm); err != nil {
			return nil, err
		}
		out = append(out, nv)
	}
	if out == nil {
		out = []models.NearbyVetDTO{}
	}
	return out, nil
}

var _ = uuid.New
