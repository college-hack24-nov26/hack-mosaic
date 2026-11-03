package routes_test

import (
	"bytes"
	"encoding/json"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"pashuvani/backend/internal/config"
	"pashuvani/backend/internal/repositories"
	"pashuvani/backend/internal/routes"
	"pashuvani/backend/internal/services"
)

func setupTestServer(t *testing.T) (*httptest.Server, string) {
	t.Helper()
	tmpUploads, err := os.MkdirTemp("", "pashuvani-test-uploads-*")
	if err != nil {
		t.Fatalf("create temp upload dir: %v", err)
	}
	t.Cleanup(func() { _ = os.RemoveAll(tmpUploads) })

	cfg := &config.Config{
		Env:               "test",
		Port:              "8080",
		CORSOrigins:       []string{"*"},
		JWTSecret:         "test-jwt-secret-key-2026-pashuvani",
		AccessTTLSeconds:  3600,
		RefreshTTLSeconds: 86400,
		DBDriver:          "memory",
		UploadDir:         tmpUploads,
		MaxUploadBytes:    5242880,
	}

	store := repositories.NewInMemoryStore()
	authSvc := services.NewAuthService(cfg.JWTSecret, cfg.AccessTTLSeconds, cfg.RefreshTTLSeconds)
	router := routes.NewRouter(cfg, store, authSvc)

	srv := httptest.NewServer(router)
	t.Cleanup(srv.Close)
	return srv, tmpUploads
}

func doJSON(t *testing.T, method, url, token string, body any) (int, map[string]any) {
	t.Helper()
	var reqBody *bytes.Reader
	if body != nil {
		raw, err := json.Marshal(body)
		if err != nil {
			t.Fatalf("marshal body: %v", err)
		}
		reqBody = bytes.NewReader(raw)
	} else {
		reqBody = bytes.NewReader(nil)
	}

	req, err := http.NewRequest(method, url, reqBody)
	if err != nil {
		t.Fatalf("new request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}

	res, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("execute request: %v", err)
	}
	defer res.Body.Close()

	var parsed map[string]any
	_ = json.NewDecoder(res.Body).Decode(&parsed)
	return res.StatusCode, parsed
}

func TestHealthAndReferenceCatalogs(t *testing.T) {
	srv, _ := setupTestServer(t)

	// 1. GET /health
	status, body := doJSON(t, http.MethodGet, srv.URL+"/health", "", nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /health, got %d", status)
	}
	data, _ := body["data"].(map[string]any)
	if data["status"] != "ok" {
		t.Fatalf("expected status ok, got %v", data["status"])
	}

	// 2. GET /api/v1/healthz
	status, _ = doJSON(t, http.MethodGet, srv.URL+"/api/v1/healthz", "", nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /api/v1/healthz, got %d", status)
	}

	// 3. GET /api/v1/reference/locations?level=district
	status, body = doJSON(t, http.MethodGet, srv.URL+"/api/v1/reference/locations?level=district", "", nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on locations, got %d", status)
	}
	locs, _ := body["data"].([]any)
	if len(locs) < 1 {
		t.Fatalf("expected seeded districts, got %d", len(locs))
	}

	// 4. GET /api/v1/reference/diseases & symptoms
	status, body = doJSON(t, http.MethodGet, srv.URL+"/api/v1/reference/diseases", "", nil)
	if status != http.StatusOK || len(body["data"].([]any)) < 5 {
		t.Fatalf("expected seeded diseases, status=%d", status)
	}
	status, body = doJSON(t, http.MethodGet, srv.URL+"/api/v1/reference/symptoms", "", nil)
	if status != http.StatusOK || len(body["data"].([]any)) < 10 {
		t.Fatalf("expected seeded symptoms, status=%d", status)
	}
}

func TestAuthenticationAndRBAC(t *testing.T) {
	srv, _ := setupTestServer(t)

	// 1. Register new farmer
	regPayload := map[string]any{
		"phone":              "+919765432109",
		"password":           "FarmerPass123",
		"full_name":          "Ganesh More",
		"preferred_language": "mr",
		"district_id":        "11111111-1111-4111-8111-111111111201",
		"taluka_id":          "11111111-1111-4111-8111-111111111301",
		"village_id":         "11111111-1111-4111-8111-111111111401",
		"consent_alerts":     true,
	}
	status, body := doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/register", "", regPayload)
	if status != http.StatusCreated {
		t.Fatalf("expected 201 on farmer register, got %d (%v)", status, body)
	}
	regData := body["data"].(map[string]any)
	farmerToken := regData["access_token"].(string)
	refreshToken := regData["refresh_token"].(string)

	// 2. Duplicate registration returns 409 CONFLICT
	status, _ = doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/register", "", regPayload)
	if status != http.StatusConflict {
		t.Fatalf("expected 409 on duplicate phone register, got %d", status)
	}

	// 3. Invalid credentials returns 401 INVALID_CREDENTIALS
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/login", "", map[string]any{
		"phone":    "+919765432109",
		"password": "WrongPassword999",
	})
	if status != http.StatusUnauthorized {
		t.Fatalf("expected 401 on wrong password, got %d", status)
	}

	// 4. GET /api/v1/me with valid JWT
	status, body = doJSON(t, http.MethodGet, srv.URL+"/api/v1/me", farmerToken, nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /me, got %d", status)
	}
	meData := body["data"].(map[string]any)
	if meData["role"] != "farmer" {
		t.Fatalf("expected farmer role, got %v", meData["role"])
	}

	// 5. Refresh token rotation
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/refresh", "", map[string]any{
		"refresh_token": refreshToken,
	})
	if status != http.StatusOK {
		t.Fatalf("expected 200 on token refresh, got %d (%v)", status, body)
	}

	// 6. Farmer cannot access vet verification endpoint (403 FORBIDDEN)
	status, _ = doJSON(t, http.MethodPost, srv.URL+"/api/v1/reports/44444444-4444-4444-8444-444444444001/verifications", farmerToken, map[string]any{
		"decision":     "confirmed",
		"disease_code": "lumpy_skin_disease",
	})
	if status != http.StatusForbidden {
		t.Fatalf("expected 403 when farmer attempts vet verification, got %d", status)
	}

	// 7. Unverified veterinarian login succeeds (so app can show Verification Pending screen),
	//    but clinical verification is blocked with 403 VET_NOT_VERIFIED
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/login", "", map[string]any{
		"phone":    "+919890334455",
		"password": "Pashu@2026",
	})
	if status != http.StatusOK {
		t.Fatalf("expected 200 login for unverified vet, got %d", status)
	}
	unverifiedVetToken := body["data"].(map[string]any)["access_token"].(string)

	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/reports/44444444-4444-4444-8444-444444444001/verifications", unverifiedVetToken, map[string]any{
		"decision":     "confirmed",
		"disease_code": "lumpy_skin_disease",
	})
	if status != http.StatusForbidden {
		t.Fatalf("expected 403 for unverified vet verification, got %d", status)
	}
	errObj := body["error"].(map[string]any)
	if errObj["code"] != "VET_NOT_VERIFIED" {
		t.Fatalf("expected VET_NOT_VERIFIED error code, got %v", errObj["code"])
	}
}

func TestGoldenThreadFarmerToVetToDashboard(t *testing.T) {
	srv, _ := setupTestServer(t)

	// Step 1: Farmer logs in
	status, body := doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/login", "", map[string]any{
		"phone":    "+919876543210",
		"password": "Pashu@2026",
	})
	if status != http.StatusOK {
		t.Fatalf("farmer login failed: %d", status)
	}
	farmerToken := body["data"].(map[string]any)["access_token"].(string)

	// Step 2: Farmer registers a new animal (with client-generated UUID)
	animalID := "33333333-3333-4333-8333-333333333099"
	animalPayload := map[string]any{
		"id":           animalID,
		"species_code": "cattle",
		"breed_code":   "gir",
		"tag_number":   "MH-SAT-2026-999",
		"name":         "Lakshmi",
		"sex":          "female",
		"birth_date":   "2023-05-01",
		"markings":     "White star on forehead",
	}
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/animals", farmerToken, animalPayload)
	if status != http.StatusCreated {
		t.Fatalf("expected 201 on animal create, got %d (%v)", status, body)
	}
	// Idempotent retry returns 200 OK
	status, _ = doJSON(t, http.MethodPost, srv.URL+"/api/v1/animals", farmerToken, animalPayload)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on idempotent animal retry, got %d", status)
	}

	// Step 3: Farmer submits a disease report with on-device MobileNetV3 screening
	reportID := "44444444-4444-4444-8444-444444444099"
	reportPayload := map[string]any{
		"id":                   reportID,
		"animal_id":            animalID,
		"description":          "Raised skin nodules on neck and high fever since yesterday.",
		"description_language": "mr",
		"symptom_codes":        []string{"skin_nodules", "fever", "loss_of_appetite"},
		"location": map[string]any{
			"lat":        17.9870,
			"lng":        74.4345,
			"accuracy_m": 6.0,
		},
		"expected_image_count": 1,
		"screening": map[string]any{
			"model_version":  "mobilenet_v3_small_v1.0.0",
			"top_label":      "lumpy_skin_disease",
			"top_confidence": 0.91,
			"inconclusive":   false,
		},
	}
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/reports", farmerToken, reportPayload)
	if status != http.StatusCreated {
		t.Fatalf("expected 201 on report create, got %d (%v)", status, body)
	}
	repData := body["data"].(map[string]any)
	// Safety invariant: AI screening never sets status=confirmed!
	if repData["status"] != "submitted" {
		t.Fatalf("expected report status 'submitted', got %v", repData["status"])
	}
	screening := repData["screening"].(map[string]any)
	if screening["disclaimer"] != "preliminary_screening_not_a_diagnosis" {
		t.Fatalf("expected preliminary disclaimer, got %v", screening["disclaimer"])
	}

	// Step 4: Farmer uploads JPEG image to the report
	var buf bytes.Buffer
	mw := multipart.NewWriter(&buf)
	_ = mw.WriteField("id", "77777777-8888-4999-8000-111111111111")
	fw, _ := mw.CreateFormFile("file", "lesion.jpg")
	// Valid JPEG magic bytes (FF D8 FF E0 ...)
	_, _ = fw.Write([]byte{0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 'J', 'F', 'I', 'F', 0x00, 0x01, 0xFF, 0xD9})
	_ = mw.Close()

	imgReq, _ := http.NewRequest(http.MethodPost, srv.URL+"/api/v1/reports/"+reportID+"/images", &buf)
	imgReq.Header.Set("Content-Type", mw.FormDataContentType())
	imgReq.Header.Set("Authorization", "Bearer "+farmerToken)
	imgRes, err := http.DefaultClient.Do(imgReq)
	if err != nil {
		t.Fatalf("upload image request failed: %v", err)
	}
	defer imgRes.Body.Close()
	if imgRes.StatusCode != http.StatusCreated {
		t.Fatalf("expected 201 on image upload, got %d", imgRes.StatusCode)
	}

	// Step 5: Verified Veterinarian logs in
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/auth/login", "", map[string]any{
		"phone":    "+919890112233",
		"password": "Pashu@2026",
	})
	if status != http.StatusOK {
		t.Fatalf("vet login failed: %d", status)
	}
	vetToken := body["data"].(map[string]any)["access_token"].(string)

	// Step 6: Vet claims and then confirms the disease report
	status, _ = doJSON(t, http.MethodPost, srv.URL+"/api/v1/reports/"+reportID+"/claim", vetToken, map[string]any{})
	if status != http.StatusOK {
		t.Fatalf("expected 200 on vet claim, got %d", status)
	}

	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/reports/"+reportID+"/verifications", vetToken, map[string]any{
		"decision":       "confirmed",
		"disease_code":   "lumpy_skin_disease",
		"notes":          "Confirmed LSD cutaneous nodules during field inspection.",
		"visit_required": true,
	})
	if status != http.StatusCreated {
		t.Fatalf("expected 201 on vet verification, got %d (%v)", status, body)
	}
	verifiedRep := body["data"].(map[string]any)
	if verifiedRep["status"] != "confirmed" {
		t.Fatalf("expected report status 'confirmed' after vet verification, got %v", verifiedRep["status"])
	}

	// Step 7: Vet adds treatment record
	status, body = doJSON(t, http.MethodPost, srv.URL+"/api/v1/animals/"+animalID+"/treatments", vetToken, map[string]any{
		"report_id":       reportID,
		"medication_name": "Meloxicam Injection",
		"dosage":          "15 ml IM",
		"started_on":      "2026-11-03",
		"notes":           "Isolate animal for 14 days",
	})
	if status != http.StatusCreated {
		t.Fatalf("expected 201 on treatment create, got %d (%v)", status, body)
	}

	// Step 8: Confirmed case appears in GeoJSON GET /api/v1/map/cases
	status, mapBody := doJSON(t, http.MethodGet, srv.URL+"/api/v1/map/cases", vetToken, nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /map/cases, got %d", status)
	}
	if mapBody["type"] != "FeatureCollection" {
		t.Fatalf("expected FeatureCollection, got %v", mapBody["type"])
	}
	features := mapBody["features"].([]any)
	foundNewCase := false
	for _, f := range features {
		fm := f.(map[string]any)
		props := fm["properties"].(map[string]any)
		if props["report_id"] == reportID {
			foundNewCase = true
		}
		if props["status"] != "confirmed" {
			t.Fatalf("non-confirmed report leaked into /map/cases: %v", props)
		}
	}
	if !foundNewCase {
		t.Fatalf("newly confirmed report %s did not appear in /map/cases", reportID)
	}

	// Step 9: Nearby veterinarians query returns only verified vets sorted by distance
	status, nearbyBody := doJSON(t, http.MethodGet, srv.URL+"/api/v1/veterinarians/nearby?lat=17.9856&lng=74.4331&radius_km=50", "", nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on nearby vets, got %d", status)
	}
	vets := nearbyBody["data"].([]any)
	if len(vets) != 2 {
		t.Fatalf("expected 2 verified vets (and 0 unverified), got %d", len(vets))
	}
}

func TestDashboardAndMLRiskIntegration(t *testing.T) {
	srv, _ := setupTestServer(t)

	demoToken := "demo_authority_token"

	// 1. Verify 1-Click Demo Authority Token works for GET /api/v1/dashboard/stats
	status, statsBody := doJSON(t, http.MethodGet, srv.URL+"/api/v1/dashboard/stats", demoToken, nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /dashboard/stats with demo_authority_token, got %d (%v)", status, statsBody)
	}
	statsData := statsBody["data"].(map[string]any)
	mlRisk := statsData["ml_risk_summary"].(map[string]any)
	if mlRisk["disclaimer"] != "Experimental estimate. Not a confirmed forecast." {
		t.Fatalf("expected mandatory ML risk disclaimer, got %v", mlRisk["disclaimer"])
	}

	// 2. Verify POST /api/v1/ml/outbreak-risk proxy with circuit-breaker fallback
	status, riskBody := doJSON(t, http.MethodPost, srv.URL+"/api/v1/ml/outbreak-risk", demoToken, map[string]any{
		"district":         "Satara",
		"disease_category": "LSD",
		"past_cases_30d":   8,
		"rainfall_mm":      240.0,
		"temperature_c":    29.5,
		"humidity_pct":     78.0,
		"cattle_density":   425000,
	})
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /ml/outbreak-risk, got %d (%v)", status, riskBody)
	}
	riskData := riskBody["data"].(map[string]any)
	if riskData["disclaimer"] != "Experimental estimate. Not a confirmed forecast." {
		t.Fatalf("expected mandatory disclaimer on /ml/outbreak-risk, got %v", riskData["disclaimer"])
	}

	// 3. Verify GET /api/v1/reports for officer returns enriched TFLite image result and verified status for confirmed cases
	status, repListBody := doJSON(t, http.MethodGet, srv.URL+"/api/v1/reports?status=verified", demoToken, nil)
	if status != http.StatusOK {
		t.Fatalf("expected 200 on /reports?status=verified, got %d", status)
	}
	repItems := repListBody["data"].([]any)
	if len(repItems) == 0 {
		t.Fatalf("expected at least 1 confirmed/verified report")
	}
	firstRep := repItems[0].(map[string]any)
	if firstRep["status"] != "verified" {
		t.Fatalf("expected dashboard-mapped status 'verified', got %v", firstRep["status"])
	}
	imgs := firstRep["images"].([]any)
	if len(imgs) == 0 {
		t.Fatalf("expected enriched default image with TFLite result for dashboard")
	}
}


