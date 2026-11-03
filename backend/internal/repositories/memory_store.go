package repositories

import (
	"context"
	"fmt"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"pashuvani/backend/internal/models"
)

// InMemoryStore implements Store with full domain fidelity for unit/integration testing
// and standalone hackathon fallback when PostgreSQL is not running.
type InMemoryStore struct {
	mu            sync.RWMutex
	locations     []models.LocationRef
	species       []models.SpeciesRef
	breeds        []models.BreedRef
	diseases      []models.DiseaseRef
	symptoms      []models.SymptomRef
	users         map[string]*models.UserDTO
	animals       map[string]*models.AnimalDTO
	healthRecords map[string][]models.HealthRecordDTO
	vaccinations  map[string][]models.VaccinationDTO
	treatments    map[string][]models.TreatmentDTO
	reports       map[string]*models.DiseaseReportDTO
	images        map[string]models.ReportImageDTO
	outbreaks     map[string]*models.OutbreakDTO
	alerts        map[string]*models.AlertDTO
	notifications map[string][]models.NotificationDTO
	refreshTokens map[string]refreshRecord
}

type refreshRecord struct {
	UserID    string
	ExpiresAt time.Time
	Revoked   bool
}

// NewInMemoryStore initializes and seeds a new InMemoryStore matching 000002_seed_reference_and_demo.up.sql.
func NewInMemoryStore() *InMemoryStore {
	s := &InMemoryStore{
		users:         make(map[string]*models.UserDTO),
		animals:       make(map[string]*models.AnimalDTO),
		healthRecords: make(map[string][]models.HealthRecordDTO),
		vaccinations:  make(map[string][]models.VaccinationDTO),
		treatments:    make(map[string][]models.TreatmentDTO),
		reports:       make(map[string]*models.DiseaseReportDTO),
		images:        make(map[string]models.ReportImageDTO),
		outbreaks:     make(map[string]*models.OutbreakDTO),
		alerts:        make(map[string]*models.AlertDTO),
		notifications: make(map[string][]models.NotificationDTO),
		refreshTokens: make(map[string]refreshRecord),
	}
	s.seed()
	return s
}

func strPtr(v string) *string   { return &v }
func fltPtr(v float64) *float64 { return &v }
func boolPtr(v bool) *bool      { return &v }
func int16Ptr(v int16) *int16   { return &v }

func (s *InMemoryStore) seed() {
	stateMH := "11111111-1111-4111-8111-111111111101"
	distSatara := "11111111-1111-4111-8111-111111111201"
	distPune := "11111111-1111-4111-8111-111111111202"
	talPhaltan := "11111111-1111-4111-8111-111111111301"
	talKoregaon := "11111111-1111-4111-8111-111111111302"
	talSatara := "11111111-1111-4111-8111-111111111303"
	talKhandala := "11111111-1111-4111-8111-111111111304"
	vilPhaltan := "11111111-1111-4111-8111-111111111401"
	vilBarad := "11111111-1111-4111-8111-111111111402"
	vilTadawale := "11111111-1111-4111-8111-111111111403"
	vilVidani := "11111111-1111-4111-8111-111111111404"
	vilSakharwadi := "11111111-1111-4111-8111-111111111405"

	s.locations = []models.LocationRef{
		{ID: stateMH, Level: "state", Code: "MH", NameEn: "Maharashtra", NameHi: "महाराष्ट्र", NameMr: "महाराष्ट्र", Centroid: &models.Coordinates{Lat: 19.7515, Lng: 75.7139}},
		{ID: distSatara, ParentID: &stateMH, Level: "district", Code: "MH-SAT", NameEn: "Satara", NameHi: "सातारा", NameMr: "सातारा", Centroid: &models.Coordinates{Lat: 17.6805, Lng: 74.0183}},
		{ID: distPune, ParentID: &stateMH, Level: "district", Code: "MH-PUN", NameEn: "Pune", NameHi: "पुणे", NameMr: "पुणे", Centroid: &models.Coordinates{Lat: 18.5204, Lng: 73.8567}},
		{ID: talPhaltan, ParentID: &distSatara, Level: "taluka", Code: "MH-SAT-PHA", NameEn: "Phaltan", NameHi: "फलटण", NameMr: "फलटण", Centroid: &models.Coordinates{Lat: 17.9856, Lng: 74.4331}},
		{ID: talKoregaon, ParentID: &distSatara, Level: "taluka", Code: "MH-SAT-KOR", NameEn: "Koregaon", NameHi: "कोरेगाव", NameMr: "कोरेगाव", Centroid: &models.Coordinates{Lat: 17.6992, Lng: 74.1625}},
		{ID: talSatara, ParentID: &distSatara, Level: "taluka", Code: "MH-SAT-SAT", NameEn: "Satara", NameHi: "सातारा", NameMr: "सातारा", Centroid: &models.Coordinates{Lat: 17.6805, Lng: 74.0183}},
		{ID: talKhandala, ParentID: &distSatara, Level: "taluka", Code: "MH-SAT-KHA", NameEn: "Khandala", NameHi: "खंडाळा", NameMr: "खंडाळा", Centroid: &models.Coordinates{Lat: 18.0620, Lng: 74.0150}},
		{ID: vilPhaltan, ParentID: &talPhaltan, Level: "village", Code: "MH-SAT-PHA-001", NameEn: "Phaltan Rural", NameHi: "फलटण ग्रामीण", NameMr: "फलटण ग्रामीण", Centroid: &models.Coordinates{Lat: 17.9856, Lng: 74.4331}},
		{ID: vilBarad, ParentID: &talPhaltan, Level: "village", Code: "MH-SAT-PHA-002", NameEn: "Barad", NameHi: "बरड", NameMr: "बरड", Centroid: &models.Coordinates{Lat: 17.9542, Lng: 74.4820}},
		{ID: vilTadawale, ParentID: &talPhaltan, Level: "village", Code: "MH-SAT-PHA-003", NameEn: "Tadawale", NameHi: "ताडवळे", NameMr: "ताडवळे", Centroid: &models.Coordinates{Lat: 18.0120, Lng: 74.3910}},
		{ID: vilVidani, ParentID: &talPhaltan, Level: "village", Code: "MH-SAT-PHA-004", NameEn: "Vidani", NameHi: "विडणी", NameMr: "विडणी", Centroid: &models.Coordinates{Lat: 17.9710, Lng: 74.4550}},
		{ID: vilSakharwadi, ParentID: &talPhaltan, Level: "village", Code: "MH-SAT-PHA-005", NameEn: "Sakharwadi", NameHi: "साखरवाडी", NameMr: "साखरवाडी", Centroid: &models.Coordinates{Lat: 18.0340, Lng: 74.3620}},
	}

	s.species = []models.SpeciesRef{
		{ID: 1, Code: "cattle", NameEn: "Cow / Bull", NameHi: "गाय / बैल", NameMr: "गाय / बैल"},
		{ID: 2, Code: "buffalo", NameEn: "Buffalo", NameHi: "भैंस", NameMr: "म्हैस"},
		{ID: 3, Code: "goat", NameEn: "Goat", NameHi: "बकरी", NameMr: "शेळी"},
	}

	s.breeds = []models.BreedRef{
		{ID: 1, SpeciesCode: "cattle", Code: "gir", NameEn: "Gir", NameHi: "गिर", NameMr: "गीर"},
		{ID: 2, SpeciesCode: "cattle", Code: "khillar", NameEn: "Khillar", NameHi: "खिल्लार", NameMr: "खिल्लार"},
		{ID: 3, SpeciesCode: "cattle", Code: "holstein_friesian", NameEn: "Holstein Friesian", NameHi: "होल्स्टीन फ्रीजियन", NameMr: "होल्स्टिन फ्रिजियन"},
		{ID: 4, SpeciesCode: "cattle", Code: "sahiwal", NameEn: "Sahiwal", NameHi: "साहीवाल", NameMr: "साहिवाल"},
		{ID: 5, SpeciesCode: "cattle", Code: "jersey", NameEn: "Jersey", NameHi: "जर्सी", NameMr: "जर्सी"},
		{ID: 6, SpeciesCode: "buffalo", Code: "murrah", NameEn: "Murrah", NameHi: "मुर्रा", NameMr: "मुऱ्हा"},
		{ID: 7, SpeciesCode: "buffalo", Code: "pandharpuri", NameEn: "Pandharpuri", NameHi: "पंढरपुरी", NameMr: "पंढरपुरी"},
		{ID: 8, SpeciesCode: "buffalo", Code: "jaffarabadi", NameEn: "Jaffarabadi", NameHi: "जाफराबादी", NameMr: "जाफराबादी"},
		{ID: 9, SpeciesCode: "goat", Code: "osmanabadi", NameEn: "Osmanabadi", NameHi: "उस्मानाबादी", NameMr: "उस्मानाबादी"},
		{ID: 10, SpeciesCode: "goat", Code: "sangamneri", NameEn: "Sangamneri", NameHi: "संगमनेरी", NameMr: "संगमनेरी"},
	}

	s.diseases = []models.DiseaseRef{
		{ID: 1, Code: "lumpy_skin_disease", NameEn: "Lumpy Skin Disease (LSD)", NameHi: "लम्पी त्वचा रोग", NameMr: "लम्पी त्वचा रोग", IsNotifiable: true, IsOutbreakTracked: true, IsSurveillance: true, ClusterMinCases: 2, ClusterRadiusM: 5000, ClusterWindowDays: 14, PrecautionsEn: "Isolate affected cattle immediately, control mosquitoes/ticks, disinfect shed, and consult a veterinarian."},
		{ID: 2, Code: "foot_and_mouth_disease", NameEn: "Foot and Mouth Disease (FMD)", NameHi: "खुरपका-मुंहपका रोग", NameMr: "लाळ खुरकत रोग", IsNotifiable: true, IsOutbreakTracked: true, IsSurveillance: true, ClusterMinCases: 2, ClusterRadiusM: 5000, ClusterWindowDays: 14, PrecautionsEn: "Separate sick animals, wash mouth/hoof lesions with 1% potassium permanganate, and restrict herd movement."},
		{ID: 3, Code: "brucellosis", NameEn: "Brucellosis", NameHi: "ब्रुसेलोसिस", NameMr: "ब्रुसेलोसिस", IsNotifiable: true, IsOutbreakTracked: true, IsSurveillance: true, ClusterMinCases: 3, ClusterRadiusM: 5000, ClusterWindowDays: 14},
		{ID: 4, Code: "black_quarter", NameEn: "Black Quarter (BQ)", NameHi: "लंगड़ा बुखार", NameMr: "फऱ्या रोग", IsNotifiable: true, IsOutbreakTracked: true, IsSurveillance: true, ClusterMinCases: 2, ClusterRadiusM: 5000, ClusterWindowDays: 14},
		{ID: 5, Code: "haemorrhagic_septicaemia", NameEn: "Haemorrhagic Septicaemia (HS)", NameHi: "गलघोंटू रोग", NameMr: "घटसर्प रोग", IsNotifiable: true, IsOutbreakTracked: true, IsSurveillance: true, ClusterMinCases: 2, ClusterRadiusM: 5000, ClusterWindowDays: 14},
		{ID: 6, Code: "mastitis", NameEn: "Mastitis", NameHi: "थनैला रोग", NameMr: "कासदाह (मस्टायटिस)", IsNotifiable: false, IsOutbreakTracked: false, IsSurveillance: false, ClusterMinCases: 5, ClusterRadiusM: 5000, ClusterWindowDays: 14},
		{ID: 7, Code: "peste_des_petits_ruminants", NameEn: "Peste des Petits Ruminants (PPR)", NameHi: "बकरियों की महामारी (PPR)", NameMr: "शेळ्यांचा बुळकांडी रोग (PPR)", IsNotifiable: true, IsOutbreakTracked: true, IsSurveillance: true, ClusterMinCases: 2, ClusterRadiusM: 5000, ClusterWindowDays: 14},
	}

	s.symptoms = []models.SymptomRef{
		{ID: 1, Code: "skin_nodules", NameEn: "Skin nodules / lumps", NameHi: "त्वचा पर गांठें", NameMr: "अंगावर गाठी येणे", Category: "skin"},
		{ID: 2, Code: "blisters_mouth_feet", NameEn: "Blisters on mouth or hooves", NameHi: "मुंह और खुर पर छाले", NameMr: "तोंडात व खुरांवर फोड येणे", Category: "mouth_feet"},
		{ID: 3, Code: "fever", NameEn: "High fever", NameHi: "तेज बुखार", NameMr: "तीव्र ताप येणे", Category: "general"},
		{ID: 4, Code: "excessive_salivation", NameEn: "Excessive salivation / drooling", NameHi: "मुंह से अत्यधिक लार गिरना", NameMr: "तोंडातून जास्त लाळ गळणे", Category: "mouth_feet"},
		{ID: 5, Code: "lameness", NameEn: "Lameness / difficulty walking", NameHi: "लंगड़ापन", NameMr: "लंगडणे / चालण्यास त्रास", Category: "musculoskeletal"},
		{ID: 6, Code: "nasal_discharge", NameEn: "Nasal or ocular discharge", NameHi: "नाक या आंख से पानी आना", NameMr: "नाकातून किंवा डोळ्यातून स्राव येणे", Category: "respiratory"},
		{ID: 7, Code: "loss_of_appetite", NameEn: "Loss of appetite", NameHi: "भूख न लगना", NameMr: "चारा न खाणे / भूक मंदावणे", Category: "general"},
		{ID: 8, Code: "milk_drop", NameEn: "Sudden drop in milk yield", NameHi: "दूध उत्पादन में कमी", NameMr: "दुधाचे प्रमाण अचानक कमी होणे", Category: "udder"},
		{ID: 9, Code: "swollen_udder", NameEn: "Swollen or hot udder", NameHi: "थन में सूजन", NameMr: "कास सुजणे किंवा गरम लागणे", Category: "udder"},
		{ID: 10, Code: "diarrhoea", NameEn: "Severe diarrhoea", NameHi: "गंभीर दस्त", NameMr: "तीव्र जुलाब होणे", Category: "digestive"},
		{ID: 11, Code: "swelling_limb", NameEn: "Painful swelling on thigh / shoulder", NameHi: "जांघ या कंधे पर सूजन", NameMr: "मांड्या किंवा खांद्यावर सूज येणे", Category: "musculoskeletal"},
		{ID: 12, Code: "abortion", NameEn: "Late-term abortion", NameHi: "गर्भपात होना", NameMr: "गर्भपात होणे", Category: "reproductive"},
		{ID: 13, Code: "enlarged_lymph_nodes", NameEn: "Enlarged lymph nodes", NameHi: "लसीका ग्रंथियों में सूजन", NameMr: "लसीका ग्रंथी सुजणे", Category: "general"},
	}

	pwHashBytes, _ := bcrypt.GenerateFromPassword([]byte("Pashu@2026"), bcrypt.MinCost)
	pwHash := string(pwHashBytes)
	now := time.Now().UTC()

	// Demo Farmers
	f1 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222001", Phone: "+919876543210", PhoneNumber: "+919876543210",
		Email: strPtr("ramesh.jadhav@demo.pashuvani.in"), FullName: "Ramesh Jadhav (SYNTHETIC DEMO)", Name: "Ramesh Jadhav (SYNTHETIC DEMO)",
		Role: "farmer", PreferredLanguage: "mr", LanguagePreference: "mr", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Farmer: &models.FarmerProfile{
				VillageID: &vilPhaltan, VillageName: "Phaltan Rural", TalukaID: talPhaltan, TalukaName: "Phaltan",
				DistrictID: distSatara, DistrictName: "Satara", HomeLocation: &models.Coordinates{Lat: 17.9856, Lng: 74.4331}, ConsentAlerts: true,
			},
			VillageID: &vilPhaltan, TalukaID: talPhaltan, TalukaName: "Phaltan", DistrictID: distSatara, DistrictName: "Satara", ConsentAlerts: boolPtr(true),
		},
	}
	f2 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222002", Phone: "+919822334455", PhoneNumber: "+919822334455",
		Email: strPtr("anil.shinde@demo.pashuvani.in"), FullName: "Anil Shinde (SYNTHETIC DEMO)", Name: "Anil Shinde (SYNTHETIC DEMO)",
		Role: "farmer", PreferredLanguage: "mr", LanguagePreference: "mr", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Farmer: &models.FarmerProfile{
				VillageID: &vilBarad, VillageName: "Barad", TalukaID: talPhaltan, TalukaName: "Phaltan",
				DistrictID: distSatara, DistrictName: "Satara", HomeLocation: &models.Coordinates{Lat: 17.9542, Lng: 74.4820}, ConsentAlerts: true,
			},
			VillageID: &vilBarad, TalukaID: talPhaltan, TalukaName: "Phaltan", DistrictID: distSatara, DistrictName: "Satara", ConsentAlerts: boolPtr(true),
		},
	}
	f3 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222003", Phone: "+919833445566", PhoneNumber: "+919833445566",
		Email: strPtr("suresh.bhosale@demo.pashuvani.in"), FullName: "Suresh Bhosale (SYNTHETIC DEMO)", Name: "Suresh Bhosale (SYNTHETIC DEMO)",
		Role: "farmer", PreferredLanguage: "mr", LanguagePreference: "mr", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Farmer: &models.FarmerProfile{
				VillageID: &vilTadawale, VillageName: "Tadawale", TalukaID: talPhaltan, TalukaName: "Phaltan",
				DistrictID: distSatara, DistrictName: "Satara", HomeLocation: &models.Coordinates{Lat: 18.0120, Lng: 74.3910}, ConsentAlerts: true,
			},
			VillageID: &vilTadawale, TalukaID: talPhaltan, TalukaName: "Phaltan", DistrictID: distSatara, DistrictName: "Satara", ConsentAlerts: boolPtr(true),
		},
	}

	// Demo Vets
	v1 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222101", Phone: "+919890112233", PhoneNumber: "+919890112233",
		Email: strPtr("dr.kulkarni@mahavet.gov.in"), FullName: "Dr. Rajesh Kulkarni", Name: "Dr. Rajesh Kulkarni",
		Role: "vet", PreferredLanguage: "en", LanguagePreference: "en", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Vet: &models.VetProfile{
				RegistrationNo: "SVC-MH-2019-4482", Qualification: "M.V.Sc (Medicine)",
				ClinicName:   "Taluka Veterinary Polyclinic, Phaltan",
				Address:      "Near Krishi Bazar Samiti, Ring Road, Phaltan, Dist. Satara",
				WorkingHours: "9:00 AM – 6:00 PM", IsParaVet: false,
				DistrictID: distSatara, DistrictName: "Satara", TalukaID: &talPhaltan, TalukaName: "Phaltan",
				ClinicLocation: &models.Coordinates{Lat: 17.9912, Lng: 74.4318}, IsVerified: true, VerifiedAt: &now,
			},
			RegistrationNo: "SVC-MH-2019-4482", Qualification: "M.V.Sc (Medicine)",
			ClinicName: "Taluka Veterinary Polyclinic, Phaltan",
			DistrictID: distSatara, DistrictName: "Satara", TalukaID: talPhaltan, TalukaName: "Phaltan", IsVerified: boolPtr(true),
		},
	}
	v2 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222102", Phone: "+919890223344", PhoneNumber: "+919890223344",
		Email: strPtr("dr.deshmukh@mahavet.gov.in"), FullName: "Dr. Snehal Deshmukh", Name: "Dr. Snehal Deshmukh",
		Role: "vet", PreferredLanguage: "mr", LanguagePreference: "mr", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Vet: &models.VetProfile{
				RegistrationNo: "SVC-MH-2021-5190", Qualification: "B.V.Sc & A.H.",
				ClinicName:   "Government Veterinary Dispensary Grade-I, Barad",
				Address:      "Main Bazar Peth, Barad, Tal. Phaltan, Dist. Satara",
				WorkingHours: "9:00 AM – 5:00 PM", IsParaVet: false,
				DistrictID: distSatara, DistrictName: "Satara", TalukaID: &talPhaltan, TalukaName: "Phaltan",
				ClinicLocation: &models.Coordinates{Lat: 17.9560, Lng: 74.4805}, IsVerified: true, VerifiedAt: &now,
			},
			RegistrationNo: "SVC-MH-2021-5190", Qualification: "B.V.Sc & A.H.",
			ClinicName: "Government Veterinary Dispensary Grade-I, Barad",
			DistrictID: distSatara, DistrictName: "Satara", TalukaID: talPhaltan, TalukaName: "Phaltan", IsVerified: boolPtr(true),
		},
	}
	v3Unverified := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222103", Phone: "+919890334455", PhoneNumber: "+919890334455",
		Email: strPtr("dr.pawar@mahavet.gov.in"), FullName: "Dr. Vikram Pawar", Name: "Dr. Vikram Pawar",
		Role: "vet", PreferredLanguage: "en", LanguagePreference: "en", AccountStatus: "pending_verification", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Vet: &models.VetProfile{
				RegistrationNo: "SVC-MH-2025-8801", Qualification: "B.V.Sc & A.H.",
				ClinicName: "Vidani Rural Vet Center", Address: "Vidani, Tal. Phaltan, Dist. Satara",
				WorkingHours: "10:00 AM – 4:00 PM", IsParaVet: false,
				DistrictID: distSatara, DistrictName: "Satara", TalukaID: &talPhaltan, TalukaName: "Phaltan",
				ClinicLocation: &models.Coordinates{Lat: 17.9710, Lng: 74.4550}, IsVerified: false,
			},
			RegistrationNo: "SVC-MH-2025-8801", Qualification: "B.V.Sc & A.H.",
			ClinicName: "Vidani Rural Vet Center",
			DistrictID: distSatara, DistrictName: "Satara", TalukaID: talPhaltan, TalukaName: "Phaltan", IsVerified: boolPtr(false),
		},
	}

	// Demo Officer & Admin
	off1 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222201", Phone: "+919890445566", PhoneNumber: "+919890445566",
		Email: strPtr("dahdo.satara@maharashtra.gov.in"), FullName: "Dr. Mahesh Patil (District Officer)", Name: "Dr. Mahesh Patil (District Officer)",
		Role: "officer", PreferredLanguage: "en", LanguagePreference: "en", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile: &models.UserProfileEnvelope{
			Officer: &models.OfficerProfile{
				Designation: "District Animal Husbandry Deputy Commissioner, Satara", Level: "district", ScopeLocationID: distSatara, DistrictName: "Satara",
			},
			Designation: "District Animal Husbandry Deputy Commissioner, Satara", Level: "district", ScopeLocID: distSatara, DistrictID: distSatara, DistrictName: "Satara",
		},
	}
	adm1 := &models.UserDTO{
		ID: "22222222-2222-4222-8222-222222222301", Phone: "+919890556677", PhoneNumber: "+919890556677",
		Email: strPtr("admin@pashuvani.gov.in"), FullName: "State Surveillance Admin", Name: "State Surveillance Admin",
		Role: "admin", PreferredLanguage: "en", LanguagePreference: "en", AccountStatus: "active", IsActive: true, District: "Satara", State: "Maharashtra",
		PasswordHash: pwHash,
		Profile:      &models.UserProfileEnvelope{},
	}

	for _, u := range []*models.UserDTO{f1, f2, f3, v1, v2, v3Unverified, off1, adm1} {
		s.users[u.ID] = u
	}

	// Demo Animals
	a1 := &models.AnimalDTO{
		ID: "33333333-3333-4333-8333-333333333001", FarmerUserID: f1.ID, SpeciesCode: "cattle", BreedCode: strPtr("gir"),
		TagNumber: strPtr("MH-SAT-2026-081"), Name: strPtr("Gauri"), Sex: "female", BirthDate: strPtr("2022-03-15"),
		ApproxAgeMonths: int16Ptr(44), Markings: strPtr("Reddish brown coat with white forehead patch"), IsActive: true,
		ClientCreatedAt: now.Add(-30 * 24 * time.Hour), CreatedAt: now.Add(-30 * 24 * time.Hour), UpdatedAt: now,
	}
	a2 := &models.AnimalDTO{
		ID: "33333333-3333-4333-8333-333333333002", FarmerUserID: f2.ID, SpeciesCode: "buffalo", BreedCode: strPtr("murrah"),
		TagNumber: strPtr("MH-SAT-2026-112"), Name: strPtr("Krishna"), Sex: "female", BirthDate: strPtr("2021-07-10"),
		ApproxAgeMonths: int16Ptr(52), Markings: strPtr("Jet black coat with curled horns"), IsActive: true,
		ClientCreatedAt: now.Add(-25 * 24 * time.Hour), CreatedAt: now.Add(-25 * 24 * time.Hour), UpdatedAt: now,
	}
	a3 := &models.AnimalDTO{
		ID: "33333333-3333-4333-8333-333333333003", FarmerUserID: f3.ID, SpeciesCode: "cattle", BreedCode: strPtr("khillar"),
		TagNumber: strPtr("MH-SAT-2026-094"), Name: strPtr("Kapila"), Sex: "female", BirthDate: strPtr("2022-11-05"),
		ApproxAgeMonths: int16Ptr(36), Markings: strPtr("Greyish white compact body"), IsActive: true,
		ClientCreatedAt: now.Add(-20 * 24 * time.Hour), CreatedAt: now.Add(-20 * 24 * time.Hour), UpdatedAt: now,
	}
	a4 := &models.AnimalDTO{
		ID: "33333333-3333-4333-8333-333333333004", FarmerUserID: f1.ID, SpeciesCode: "cattle", BreedCode: strPtr("holstein_friesian"),
		TagNumber: strPtr("MH-SAT-2026-082"), Name: strPtr("Nandini"), Sex: "female", BirthDate: strPtr("2023-01-20"),
		ApproxAgeMonths: int16Ptr(33), Markings: strPtr("Black and white patches on flank"), IsActive: true,
		ClientCreatedAt: now.Add(-18 * 24 * time.Hour), CreatedAt: now.Add(-18 * 24 * time.Hour), UpdatedAt: now,
	}
	for _, a := range []*models.AnimalDTO{a1, a2, a3, a4} {
		s.animals[a.ID] = a
	}

	// Demo Reports
	r1 := &models.DiseaseReportDTO{
		ID:       "44444444-4444-4444-8444-444444444001",
		Animal:   models.ReportAnimalEmbed{ID: a1.ID, Name: a1.Name, SpeciesCode: a1.SpeciesCode, BreedCode: a1.BreedCode, TagNumber: a1.TagNumber},
		Farmer:   &models.ReportFarmerEmbed{ID: f1.ID, FullName: f1.FullName, Phone: f1.Phone},
		AnimalID: a1.ID, FarmerID: f1.ID, FarmerName: f1.FullName, FarmerPhone: f1.Phone, AnimalName: "Gauri", AnimalSpecies: "cattle", TagNumber: a1.TagNumber,
		ReportedAt: now.Add(-3 * time.Hour), ReceivedAt: now.Add(-3 * time.Hour),
		Description:         strPtr("Multiple round skin nodules noticed on neck, shoulders and back. Animal has 104F fever and reduced feeding."),
		DescriptionLanguage: "en",
		SymptomCodes:        []string{"skin_nodules", "fever", "enlarged_lymph_nodes", "nasal_discharge"},
		Symptoms:            []string{"skin_nodules", "fever", "enlarged_lymph_nodes", "nasal_discharge"},
		Location:            models.ReportLocationEmbed{Lat: 17.9856, Lng: 74.4331, AccuracyM: fltPtr(4.5), Source: "gps"},
		Latitude:            17.9856, Longitude: 74.4331,
		VillageID: &vilPhaltan, Village: "Phaltan Rural", TalukaID: talPhaltan, Taluka: "Phaltan", DistrictID: distSatara, District: "Satara",
		Status: "submitted",
		Screening: &models.ReportScreeningEmbed{
			ModelVersion: "mobilenet_v3_small_v1.0.0", TopLabel: "lumpy_skin_disease", TopConfidence: fltPtr(0.89),
			Inconclusive: false, RanAt: now.Add(-3 * time.Hour), Disclaimer: "preliminary_screening_not_a_diagnosis",
		},
		Images: []models.ReportImageDTO{}, CreatedAt: now.Add(-3 * time.Hour), UpdatedAt: now.Add(-3 * time.Hour),
	}

	r2 := &models.DiseaseReportDTO{
		ID:       "44444444-4444-4444-8444-444444444002",
		Animal:   models.ReportAnimalEmbed{ID: a2.ID, Name: a2.Name, SpeciesCode: a2.SpeciesCode, BreedCode: a2.BreedCode, TagNumber: a2.TagNumber},
		Farmer:   &models.ReportFarmerEmbed{ID: f2.ID, FullName: f2.FullName, Phone: f2.Phone},
		AnimalID: a2.ID, FarmerID: f2.ID, FarmerName: f2.FullName, FarmerPhone: f2.Phone, AnimalName: "Krishna", AnimalSpecies: "buffalo", TagNumber: a2.TagNumber,
		ReportedAt: now.Add(-14 * time.Hour), ReceivedAt: now.Add(-14 * time.Hour),
		Description:         strPtr("Excessive salivation stringing from mouth. Reluctant to walk, limping on right hind leg. Small blisters seen on tongue."),
		DescriptionLanguage: "en",
		SymptomCodes:        []string{"excessive_salivation", "blisters_mouth_feet", "lameness", "fever"},
		Symptoms:            []string{"excessive_salivation", "blisters_mouth_feet", "lameness", "fever"},
		Location:            models.ReportLocationEmbed{Lat: 17.9542, Lng: 74.4820, AccuracyM: fltPtr(5.2), Source: "gps"},
		Latitude:            17.9542, Longitude: 74.4820,
		VillageID: &vilBarad, Village: "Barad", TalukaID: talPhaltan, Taluka: "Phaltan", DistrictID: distSatara, District: "Satara",
		Status: "under_review", ClaimedByVetID: &v1.ID,
		Screening: &models.ReportScreeningEmbed{
			ModelVersion: "mobilenet_v3_small_v1.0.0", TopLabel: "foot_and_mouth_disease", TopConfidence: fltPtr(0.94),
			Inconclusive: false, RanAt: now.Add(-14 * time.Hour), Disclaimer: "preliminary_screening_not_a_diagnosis",
		},
		Images: []models.ReportImageDTO{}, CreatedAt: now.Add(-14 * time.Hour), UpdatedAt: now.Add(-12 * time.Hour),
	}

	r3 := &models.DiseaseReportDTO{
		ID:       "44444444-4444-4444-8444-444444444003",
		Animal:   models.ReportAnimalEmbed{ID: a3.ID, Name: a3.Name, SpeciesCode: a3.SpeciesCode, BreedCode: a3.BreedCode, TagNumber: a3.TagNumber},
		Farmer:   &models.ReportFarmerEmbed{ID: f3.ID, FullName: f3.FullName, Phone: f3.Phone},
		AnimalID: a3.ID, FarmerID: f3.ID, FarmerName: f3.FullName, FarmerPhone: f3.Phone, AnimalName: "Kapila", AnimalSpecies: "cattle", TagNumber: a3.TagNumber,
		ReportedAt: now.Add(-48 * time.Hour), ReceivedAt: now.Add(-48 * time.Hour),
		Description:         strPtr("Firm circumscribed nodules noticed 4 days ago across brisket and perineum. Mild fever."),
		DescriptionLanguage: "en",
		SymptomCodes:        []string{"skin_nodules", "fever"},
		Symptoms:            []string{"skin_nodules", "fever"},
		Location:            models.ReportLocationEmbed{Lat: 17.9890, Lng: 74.4280, AccuracyM: fltPtr(3.8), Source: "gps"},
		Latitude:            17.9890, Longitude: 74.4280,
		VillageID: &vilTadawale, Village: "Tadawale", TalukaID: talPhaltan, Taluka: "Phaltan", DistrictID: distSatara, District: "Satara",
		Status: "confirmed", ConfirmedDiseaseCode: strPtr("lumpy_skin_disease"), ClaimedByVetID: &v1.ID,
		Screening: &models.ReportScreeningEmbed{
			ModelVersion: "mobilenet_v3_small_v1.0.0", TopLabel: "lumpy_skin_disease", TopConfidence: fltPtr(0.92),
			Inconclusive: false, RanAt: now.Add(-48 * time.Hour), Disclaimer: "preliminary_screening_not_a_diagnosis",
		},
		Verification: &models.ReportVerificationDTO{
			ID: "66666666-6666-4666-8666-666666666001", ReportID: "44444444-4444-4444-8444-444444444003",
			Decision: "confirmed", Status: "verified", DiseaseCode: strPtr("lumpy_skin_disease"), SuspectedDisease: "lumpy_skin_disease",
			Notes:          strPtr("Clinically confirmed Lumpy Skin Disease. Characteristic sit-fast nodules observed."),
			DiagnosisNotes: "Clinically confirmed Lumpy Skin Disease. Characteristic sit-fast nodules observed.",
			VisitRequired:  true,
			Vet:            &models.VerificationVetEmbed{ID: v1.ID, FullName: v1.FullName, RegistrationNo: "SVC-MH-2019-4482"},
			VetID:          v1.ID, VetName: v1.FullName, DecidedAt: now.Add(-45 * time.Hour), VerifiedAt: now.Add(-45 * time.Hour),
		},
		Images: []models.ReportImageDTO{}, CreatedAt: now.Add(-48 * time.Hour), UpdatedAt: now.Add(-45 * time.Hour),
	}

	r4 := &models.DiseaseReportDTO{
		ID:       "44444444-4444-4444-8444-444444444004",
		Animal:   models.ReportAnimalEmbed{ID: a4.ID, Name: a4.Name, SpeciesCode: a4.SpeciesCode, BreedCode: a4.BreedCode, TagNumber: a4.TagNumber},
		Farmer:   &models.ReportFarmerEmbed{ID: f1.ID, FullName: f1.FullName, Phone: f1.Phone},
		AnimalID: a4.ID, FarmerID: f1.ID, FarmerName: f1.FullName, FarmerPhone: f1.Phone, AnimalName: "Nandini", AnimalSpecies: "cattle", TagNumber: a4.TagNumber,
		ReportedAt: now.Add(-24 * time.Hour), ReceivedAt: now.Add(-24 * time.Hour),
		Description:         strPtr("Cutaneous nodules and swelling over prescapular lymph nodes with 103.8F fever."),
		DescriptionLanguage: "en",
		SymptomCodes:        []string{"skin_nodules", "fever", "enlarged_lymph_nodes"},
		Symptoms:            []string{"skin_nodules", "fever", "enlarged_lymph_nodes"},
		Location:            models.ReportLocationEmbed{Lat: 17.9825, Lng: 74.4360, AccuracyM: fltPtr(4.1), Source: "gps"},
		Latitude:            17.9825, Longitude: 74.4360,
		VillageID: &vilPhaltan, Village: "Phaltan Rural", TalukaID: talPhaltan, Taluka: "Phaltan", DistrictID: distSatara, District: "Satara",
		Status: "confirmed", ConfirmedDiseaseCode: strPtr("lumpy_skin_disease"), ClaimedByVetID: &v1.ID,
		Screening: &models.ReportScreeningEmbed{
			ModelVersion: "mobilenet_v3_small_v1.0.0", TopLabel: "lumpy_skin_disease", TopConfidence: fltPtr(0.91),
			Inconclusive: false, RanAt: now.Add(-24 * time.Hour), Disclaimer: "preliminary_screening_not_a_diagnosis",
		},
		Verification: &models.ReportVerificationDTO{
			ID: "66666666-6666-4666-8666-666666666002", ReportID: "44444444-4444-4444-8444-444444444004",
			Decision: "confirmed", Status: "verified", DiseaseCode: strPtr("lumpy_skin_disease"), SuspectedDisease: "lumpy_skin_disease",
			Notes:          strPtr("Second confirmed LSD case within Phaltan cluster. Supportive therapy initiated."),
			DiagnosisNotes: "Second confirmed LSD case within Phaltan cluster. Supportive therapy initiated.",
			VisitRequired:  true,
			Vet:            &models.VerificationVetEmbed{ID: v1.ID, FullName: v1.FullName, RegistrationNo: "SVC-MH-2019-4482"},
			VetID:          v1.ID, VetName: v1.FullName, DecidedAt: now.Add(-21 * time.Hour), VerifiedAt: now.Add(-21 * time.Hour),
		},
		Images: []models.ReportImageDTO{}, CreatedAt: now.Add(-24 * time.Hour), UpdatedAt: now.Add(-21 * time.Hour),
	}

	for _, r := range []*models.DiseaseReportDTO{r1, r2, r3, r4} {
		s.reports[r.ID] = r
	}

	s.outbreaks["55555555-5555-4555-8555-555555555001"] = &models.OutbreakDTO{
		ID: "55555555-5555-4555-8555-555555555001", ClusterID: "55555555-5555-4555-8555-555555555001",
		DiseaseCode: "lumpy_skin_disease", DiseaseName: "Lumpy Skin Disease (LSD)", PrimaryDisease: "Lumpy Skin Disease (LSD)",
		DistrictID: distSatara, District: "Satara", TalukaID: &talPhaltan, Taluka: "Phaltan",
		Centroid: models.Coordinates{Lat: 17.9858, Lng: 74.4320},
		Latitude: 17.9858, Longitude: 74.4320, CenterLatitude: 17.9858, CenterLongitude: 74.4320,
		RadiusM: 5000, RadiusMeters: 5000, RadiusKm: 5.0,
		ConfirmedCaseCount: 2, CaseCount: 2,
		FirstCaseAt: now.Add(-45 * time.Hour), LastCaseAt: now.Add(-21 * time.Hour), DetectedAt: now.Add(-45 * time.Hour),
		Status: "active", RiskLevel: "high",
		Advisory:  "Isolate affected cattle immediately, control mosquitoes/ticks, disinfect shed, and consult a veterinarian.",
		ReportIDs: []string{r3.ID, r4.ID},
	}

	sentAt := now.Add(-20 * time.Hour)
	s.alerts["88888888-8888-4888-8888-888888888001"] = &models.AlertDTO{
		ID:               "88888888-8888-4888-8888-888888888001",
		OutbreakID:       "55555555-5555-4555-8555-555555555001",
		ApprovedByUserID: off1.ID, RadiusM: 5000,
		TitleEn:  "Confirmed Lumpy Skin Disease Alert — Phaltan Taluka",
		TitleHi:  "पुष्टि की गई लम्पी त्वचा रोग चेतावनी — फलटण तालुका",
		TitleMr:  "रोग चेतावणी: लंपी त्वचा रोग (LSD) — फलटण तालुका",
		BodyEn:   "This cluster alert is based on veterinarian-confirmed cases in Phaltan Taluka (within 5 km). Isolate cattle with skin nodules or fever immediately.",
		BodyMr:   "फलटण तालुक्यात ५ किमी अंतरावर पशुवैद्यकांनी पुष्टी केलेले लंपी त्वचा रोगाचे रुग्ण आढळले आहेत.",
		Title:    "Confirmed Lumpy Skin Disease Alert — Phaltan Taluka",
		Message:  "This cluster alert is based on veterinarian-confirmed cases in Phaltan Taluka (within 5 km). Isolate cattle with skin nodules or fever immediately.",
		Severity: "high", AffectedDistrict: "Satara", DiseaseName: "Lumpy Skin Disease (LSD)",
		Status: "sent", IsActive: true, RecipientCount: 3, SentAt: &sentAt, CreatedAt: sentAt,
	}
}

func (s *InMemoryStore) Ping(ctx context.Context) (bool, bool, string, error) {
	return true, true, "memory+spatial", nil
}

func (s *InMemoryStore) GetLocations(ctx context.Context, level, parentID string) ([]models.LocationRef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []models.LocationRef
	for _, loc := range s.locations {
		if level != "" && loc.Level != level {
			continue
		}
		if parentID != "" && (loc.ParentID == nil || *loc.ParentID != parentID) {
			continue
		}
		out = append(out, loc)
	}
	if out == nil {
		out = []models.LocationRef{}
	}
	return out, nil
}

func (s *InMemoryStore) GetLocationByID(ctx context.Context, id string) (*models.LocationRef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, loc := range s.locations {
		if loc.ID == id || loc.Code == id {
			c := loc
			return &c, nil
		}
	}
	return nil, ErrNotFound
}

func (s *InMemoryStore) GetSpecies(ctx context.Context) ([]models.SpeciesRef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return append([]models.SpeciesRef{}, s.species...), nil
}

func (s *InMemoryStore) GetBreeds(ctx context.Context, speciesCode string) ([]models.BreedRef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []models.BreedRef
	for _, b := range s.breeds {
		if speciesCode == "" || b.SpeciesCode == speciesCode {
			out = append(out, b)
		}
	}
	if out == nil {
		out = []models.BreedRef{}
	}
	return out, nil
}

func (s *InMemoryStore) GetDiseases(ctx context.Context) ([]models.DiseaseRef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return append([]models.DiseaseRef{}, s.diseases...), nil
}

func (s *InMemoryStore) GetSymptoms(ctx context.Context) ([]models.SymptomRef, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return append([]models.SymptomRef{}, s.symptoms...), nil
}

func (s *InMemoryStore) CreateFarmerUser(ctx context.Context, params CreateFarmerParams) (*models.UserDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	for _, u := range s.users {
		if u.Phone == params.Phone {
			return nil, ErrConflict
		}
	}

	var distName, talName, vilName string
	var homeCoords *models.Coordinates
	for _, l := range s.locations {
		if l.ID == params.DistrictID && l.Level == "district" {
			distName = l.NameEn
		}
		if l.ID == params.TalukaID && l.Level == "taluka" {
			talName = l.NameEn
			homeCoords = l.Centroid
		}
		if params.VillageID != nil && l.ID == *params.VillageID && l.Level == "village" {
			vilName = l.NameEn
			homeCoords = l.Centroid
		}
	}
	if distName == "" || talName == "" {
		return nil, ErrInvalidReference
	}

	id := uuid.NewString()
	u := &models.UserDTO{
		ID:                 id,
		Phone:              params.Phone,
		PhoneNumber:        params.Phone,
		FullName:           params.FullName,
		Name:               params.FullName,
		Role:               "farmer",
		PreferredLanguage:  params.PreferredLanguage,
		LanguagePreference: params.PreferredLanguage,
		AccountStatus:      "active",
		IsActive:           true,
		District:           distName,
		State:              "Maharashtra",
		PasswordHash:       params.PasswordHash,
		Profile: &models.UserProfileEnvelope{
			Farmer: &models.FarmerProfile{
				VillageID:     params.VillageID,
				VillageName:   vilName,
				TalukaID:      params.TalukaID,
				TalukaName:    talName,
				DistrictID:    params.DistrictID,
				DistrictName:  distName,
				HomeLocation:  homeCoords,
				ConsentAlerts: params.ConsentAlerts,
			},
			VillageID:     params.VillageID,
			TalukaID:      params.TalukaID,
			TalukaName:    talName,
			DistrictID:    params.DistrictID,
			DistrictName:  distName,
			ConsentAlerts: &params.ConsentAlerts,
		},
	}
	s.users[id] = u
	return u, nil
}

func (s *InMemoryStore) GetUserByPhoneOrEmail(ctx context.Context, identifier string) (*models.UserDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	for _, u := range s.users {
		if u.Phone == identifier || (u.Email != nil && strings.EqualFold(*u.Email, identifier)) {
			c := *u
			return &c, nil
		}
	}
	return nil, ErrNotFound
}

func (s *InMemoryStore) GetUserByID(ctx context.Context, userID string) (*models.UserDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	u, ok := s.users[userID]
	if !ok {
		return nil, ErrNotFound
	}
	c := *u
	return &c, nil
}

func (s *InMemoryStore) UpdateUserMe(ctx context.Context, userID string, fullName, preferredLang, villageID *string, consentAlerts *bool) (*models.UserDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	u, ok := s.users[userID]
	if !ok {
		return nil, ErrNotFound
	}
	if fullName != nil && strings.TrimSpace(*fullName) != "" {
		u.FullName = strings.TrimSpace(*fullName)
		u.Name = u.FullName
	}
	if preferredLang != nil && *preferredLang != "" {
		u.PreferredLanguage = *preferredLang
		u.LanguagePreference = *preferredLang
	}
	if u.Profile != nil && u.Profile.Farmer != nil {
		if villageID != nil {
			u.Profile.Farmer.VillageID = villageID
			u.Profile.VillageID = villageID
		}
		if consentAlerts != nil {
			u.Profile.Farmer.ConsentAlerts = *consentAlerts
			u.Profile.ConsentAlerts = consentAlerts
		}
	}
	c := *u
	return &c, nil
}

func (s *InMemoryStore) SaveRefreshToken(ctx context.Context, userID, tokenHash string, expiresAt time.Time) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.refreshTokens[tokenHash] = refreshRecord{UserID: userID, ExpiresAt: expiresAt}
	return nil
}

func (s *InMemoryStore) ConsumeRefreshToken(ctx context.Context, tokenHash string) (string, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	rec, ok := s.refreshTokens[tokenHash]
	if !ok || rec.Revoked || time.Now().UTC().After(rec.ExpiresAt) {
		return "", ErrNotFound
	}
	rec.Revoked = true
	s.refreshTokens[tokenHash] = rec
	return rec.UserID, nil
}

func (s *InMemoryStore) RevokeRefreshToken(ctx context.Context, tokenHash string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if rec, ok := s.refreshTokens[tokenHash]; ok {
		rec.Revoked = true
		s.refreshTokens[tokenHash] = rec
	}
	return nil
}

func (s *InMemoryStore) CreateOrGetAnimal(ctx context.Context, params CreateAnimalParams) (*models.AnimalDTO, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if existing, ok := s.animals[params.ID]; ok {
		if existing.FarmerUserID != params.FarmerUserID {
			return nil, false, ErrForbidden
		}
		c := *existing
		return &c, false, nil
	}
	validSpecies := false
	for _, sp := range s.species {
		if sp.Code == params.SpeciesCode {
			validSpecies = true
			break
		}
	}
	if !validSpecies {
		return nil, false, ErrInvalidReference
	}
	now := time.Now().UTC()
	sex := params.Sex
	if sex == "" {
		sex = "unknown"
	}
	a := &models.AnimalDTO{
		ID:              params.ID,
		FarmerUserID:    params.FarmerUserID,
		SpeciesCode:     params.SpeciesCode,
		BreedCode:       params.BreedCode,
		TagNumber:       params.TagNumber,
		Name:            params.Name,
		Sex:             sex,
		BirthDate:       params.BirthDate,
		ApproxAgeMonths: params.ApproxAgeMonths,
		Markings:        params.Markings,
		IsActive:        true,
		ClientCreatedAt: params.ClientCreatedAt,
		CreatedAt:       now,
		UpdatedAt:       now,
	}
	s.animals[a.ID] = a
	c := *a
	return &c, true, nil
}

func (s *InMemoryStore) GetAnimalByID(ctx context.Context, animalID string) (*models.AnimalDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	a, ok := s.animals[animalID]
	if !ok {
		return nil, ErrNotFound
	}
	c := *a
	return &c, nil
}

func (s *InMemoryStore) ListAnimals(ctx context.Context, farmerUserID string, page, pageSize int) ([]models.AnimalDTO, int, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var all []models.AnimalDTO
	for _, a := range s.animals {
		if a.FarmerUserID == farmerUserID && a.IsActive {
			all = append(all, *a)
		}
	}
	sort.Slice(all, func(i, j int) bool { return all[i].CreatedAt.After(all[j].CreatedAt) })
	total := len(all)
	if all == nil {
		all = []models.AnimalDTO{}
	}
	return all, total, nil
}

func (s *InMemoryStore) UpdateAnimal(ctx context.Context, animalID string, name, tagNumber, markings *string, isActive *bool) (*models.AnimalDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	a, ok := s.animals[animalID]
	if !ok {
		return nil, ErrNotFound
	}
	if name != nil {
		a.Name = name
	}
	if tagNumber != nil {
		a.TagNumber = tagNumber
	}
	if markings != nil {
		a.Markings = markings
	}
	if isActive != nil {
		a.IsActive = *isActive
	}
	a.UpdatedAt = time.Now().UTC()
	c := *a
	return &c, nil
}

func (s *InMemoryStore) AddHealthRecord(ctx context.Context, params CreateHealthRecordParams) (*models.HealthRecordDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	recType := params.RecordType
	switch recType {
	case "checkup", "illness", "recovery", "note":
	default:
		recType = "checkup"
	}
	hr := models.HealthRecordDTO{
		ID:               uuid.NewString(),
		AnimalID:         params.AnimalID,
		RecordedByUserID: params.RecordedByUserID,
		SourceReportID:   params.SourceReportID,
		RecordType:       recType,
		Summary:          params.Summary,
		WeightKg:         params.WeightKg,
		TemperatureC:     params.TemperatureC,
		Data:             params.Data,
		RecordedAt:       params.RecordedAt,
		CreatedAt:        time.Now().UTC(),
	}
	s.healthRecords[params.AnimalID] = append([]models.HealthRecordDTO{hr}, s.healthRecords[params.AnimalID]...)
	return &hr, nil
}

func (s *InMemoryStore) AddVaccination(ctx context.Context, params CreateVaccinationParams) (*models.VaccinationDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	v := models.VaccinationDTO{
		ID:                   uuid.NewString(),
		AnimalID:             params.AnimalID,
		DiseaseCode:          params.DiseaseCode,
		VaccineName:          params.VaccineName,
		BatchNumber:          params.BatchNumber,
		DoseNumber:           params.DoseNumber,
		AdministeredOn:       params.AdministeredOn,
		NextDueOn:            params.NextDueOn,
		AdministeredByUserID: params.AdministeredByUserID,
		Notes:                params.Notes,
		CreatedAt:            time.Now().UTC(),
	}
	s.vaccinations[params.AnimalID] = append([]models.VaccinationDTO{v}, s.vaccinations[params.AnimalID]...)
	return &v, nil
}

func (s *InMemoryStore) AddTreatment(ctx context.Context, params CreateTreatmentParams) (*models.TreatmentDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	t := models.TreatmentDTO{
		ID:                uuid.NewString(),
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
		CreatedAt:         time.Now().UTC(),
	}
	s.treatments[params.AnimalID] = append([]models.TreatmentDTO{t}, s.treatments[params.AnimalID]...)
	return &t, nil
}

func (s *InMemoryStore) GetAnimalRecord(ctx context.Context, animalID string) (*models.AnimalRecordDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	a, ok := s.animals[animalID]
	if !ok {
		return nil, ErrNotFound
	}
	hrs := append([]models.HealthRecordDTO{}, s.healthRecords[animalID]...)
	vacs := append([]models.VaccinationDTO{}, s.vaccinations[animalID]...)
	trts := append([]models.TreatmentDTO{}, s.treatments[animalID]...)
	var reps []models.ReportBriefDTO
	for _, r := range s.reports {
		if r.AnimalID == animalID {
			reps = append(reps, models.ReportBriefDTO{
				ID:                   r.ID,
				ReportedAt:           r.ReportedAt,
				Status:               r.Status,
				ConfirmedDiseaseCode: r.ConfirmedDiseaseCode,
				Description:          r.Description,
			})
		}
	}
	if hrs == nil {
		hrs = []models.HealthRecordDTO{}
	}
	if vacs == nil {
		vacs = []models.VaccinationDTO{}
	}
	if trts == nil {
		trts = []models.TreatmentDTO{}
	}
	if reps == nil {
		reps = []models.ReportBriefDTO{}
	}
	return &models.AnimalRecordDTO{
		Animal:        *a,
		HealthRecords: hrs,
		Vaccinations:  vacs,
		Treatments:    trts,
		RecentReports: reps,
		GeneratedAt:   time.Now().UTC(),
	}, nil
}

func (s *InMemoryStore) CreateOrGetReport(ctx context.Context, params CreateReportParams) (*models.DiseaseReportDTO, bool, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if existing, ok := s.reports[params.ID]; ok {
		if existing.FarmerID != params.ReporterUserID {
			return nil, false, ErrForbidden
		}
		c := *existing
		return &c, false, nil
	}
	a, ok := s.animals[params.AnimalID]
	if !ok {
		return nil, false, ErrInvalidReference
	}
	if a.FarmerUserID != params.ReporterUserID {
		return nil, false, ErrForbidden
	}
	u, ok := s.users[params.ReporterUserID]
	if !ok {
		return nil, false, ErrInvalidReference
	}

	for _, sc := range params.SymptomCodes {
		found := false
		for _, sym := range s.symptoms {
			if sym.Code == sc {
				found = true
				break
			}
		}
		if !found {
			return nil, false, ErrInvalidReference
		}
	}

	lat := 17.9856
	lng := 74.4331
	locSrc := "village_centroid"
	if params.Lat != nil && params.Lng != nil {
		lat = *params.Lat
		lng = *params.Lng
		locSrc = "gps"
	}

	talID := "11111111-1111-4111-8111-111111111301"
	distID := "11111111-1111-4111-8111-111111111201"
	vilID := params.VillageID
	if u.Profile != nil && u.Profile.Farmer != nil {
		talID = u.Profile.Farmer.TalukaID
		distID = u.Profile.Farmer.DistrictID
		if vilID == nil {
			vilID = u.Profile.Farmer.VillageID
		}
	}

	now := time.Now().UTC()
	var scr *models.ReportScreeningEmbed
	if params.Screening != nil {
		cp := *params.Screening
		cp.Disclaimer = "preliminary_screening_not_a_diagnosis"
		if cp.RanAt.IsZero() {
			cp.RanAt = now
		}
		scr = &cp
	}

	animalName := ""
	if a.Name != nil {
		animalName = *a.Name
	}

	rep := &models.DiseaseReportDTO{
		ID: params.ID,
		Animal: models.ReportAnimalEmbed{
			ID: a.ID, Name: a.Name, SpeciesCode: a.SpeciesCode, BreedCode: a.BreedCode, TagNumber: a.TagNumber,
		},
		Farmer: &models.ReportFarmerEmbed{
			ID: u.ID, FullName: u.FullName, Phone: u.Phone,
		},
		AnimalID:            a.ID,
		FarmerID:            u.ID,
		FarmerName:          u.FullName,
		FarmerPhone:         u.Phone,
		AnimalName:          animalName,
		AnimalSpecies:       a.SpeciesCode,
		TagNumber:           a.TagNumber,
		ReportedAt:          params.ReportedAt,
		ReceivedAt:          now,
		Description:         params.Description,
		DescriptionLanguage: params.DescriptionLanguage,
		SymptomCodes:        append([]string{}, params.SymptomCodes...),
		Symptoms:            append([]string{}, params.SymptomCodes...),
		Location: models.ReportLocationEmbed{
			Lat: lat, Lng: lng, AccuracyM: params.AccuracyM, Source: locSrc,
		},
		Latitude:           lat,
		Longitude:          lng,
		VillageID:          vilID,
		Village:            "Phaltan Rural",
		TalukaID:           talID,
		Taluka:             "Phaltan",
		DistrictID:         distID,
		District:           "Satara",
		Status:             "submitted",
		ExpectedImageCount: params.ExpectedImageCount,
		ImagesPending:      params.ExpectedImageCount > 0,
		Screening:          scr,
		Images:             []models.ReportImageDTO{},
		CreatedAt:          now,
		UpdatedAt:          now,
	}
	s.reports[rep.ID] = rep
	c := *rep
	return &c, true, nil
}

func (s *InMemoryStore) AddReportImage(ctx context.Context, img models.ReportImageDTO) (*models.ReportImageDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	rep, ok := s.reports[img.ReportID]
	if !ok {
		return nil, ErrNotFound
	}
	img.URL = fmt.Sprintf("/api/v1/reports/%s/images/%s", img.ReportID, img.ID)
	img.ImageURL = img.URL
	img.UploadedAt = time.Now().UTC()
	s.images[img.ID] = img
	rep.Images = append(rep.Images, img)
	rep.ImagesPending = int(rep.ExpectedImageCount) > len(rep.Images)
	return &img, nil
}

func (s *InMemoryStore) GetReportImage(ctx context.Context, reportID, imageID string) (*models.ReportImageDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	img, ok := s.images[imageID]
	if !ok || img.ReportID != reportID {
		return nil, ErrNotFound
	}
	return &img, nil
}

func (s *InMemoryStore) GetReportByID(ctx context.Context, reportID string) (*models.DiseaseReportDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	r, ok := s.reports[reportID]
	if !ok {
		return nil, ErrNotFound
	}
	c := *r
	return &c, nil
}

func (s *InMemoryStore) ListReports(ctx context.Context, filter ReportFilter) ([]models.DiseaseReportDTO, int, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var list []models.DiseaseReportDTO
	for _, r := range s.reports {
		if filter.ReporterUserID != "" && r.FarmerID != filter.ReporterUserID {
			continue
		}
		if filter.DistrictID != "" && r.DistrictID != filter.DistrictID && !strings.EqualFold(r.District, filter.DistrictID) {
			continue
		}
		if filter.TalukaID != "" && r.TalukaID != filter.TalukaID && !strings.EqualFold(r.Taluka, filter.TalukaID) {
			continue
		}
		if filter.Status != "" {
			st := filter.Status
			if st == "verified" {
				st = "confirmed"
			}
			if r.Status != st {
				continue
			}
		}
		if filter.DiseaseCode != "" && (r.ConfirmedDiseaseCode == nil || *r.ConfirmedDiseaseCode != filter.DiseaseCode) {
			continue
		}
		list = append(list, *r)
	}
	sort.Slice(list, func(i, j int) bool { return list[i].ReportedAt.After(list[j].ReportedAt) })
	total := len(list)
	if list == nil {
		list = []models.DiseaseReportDTO{}
	}
	return list, total, nil
}

func (s *InMemoryStore) ClaimReport(ctx context.Context, reportID, vetUserID, vetDistrictID string, isAdmin bool) (*models.DiseaseReportDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	r, ok := s.reports[reportID]
	if !ok {
		return nil, ErrNotFound
	}
	if !isAdmin && vetDistrictID != "" && r.DistrictID != vetDistrictID {
		return nil, ErrForbidden
	}
	if r.Status == "confirmed" || r.Status == "rejected" || r.Status == "flagged" {
		return nil, ErrAlreadyDecided
	}
	now := time.Now().UTC()
	r.Status = "under_review"
	r.ClaimedByVetID = &vetUserID
	r.ClaimedAt = &now
	r.UpdatedAt = now
	c := *r
	return &c, nil
}

func (s *InMemoryStore) VerifyReport(ctx context.Context, params VerifyReportParams) (*models.DiseaseReportDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	r, ok := s.reports[params.ReportID]
	if !ok {
		return nil, ErrNotFound
	}
	if !params.IsAdmin && params.VetDistrictID != "" && r.DistrictID != params.VetDistrictID {
		return nil, ErrForbidden
	}

	if params.Decision == "confirmed" {
		if params.DiseaseCode == nil || *params.DiseaseCode == "" {
			return nil, ErrInvalidReference
		}
		validDisease := false
		for _, d := range s.diseases {
			if d.Code == *params.DiseaseCode {
				validDisease = true
				break
			}
		}
		if !validDisease {
			return nil, ErrInvalidReference
		}
	}

	vetUser := s.users[params.VetUserID]
	vetName := "Veterinary Officer"
	regNo := ""
	if vetUser != nil {
		vetName = vetUser.FullName
		if vetUser.Profile != nil && vetUser.Profile.Vet != nil {
			regNo = vetUser.Profile.Vet.RegistrationNo
		}
	}

	now := time.Now().UTC()
	verStatus := params.Decision
	if verStatus == "confirmed" {
		verStatus = "verified"
	}
	suspDisease := ""
	if params.DiseaseCode != nil {
		suspDisease = *params.DiseaseCode
	}
	diagNotes := ""
	if params.Notes != nil {
		diagNotes = *params.Notes
	}

	r.Verification = &models.ReportVerificationDTO{
		ID:               uuid.NewString(),
		ReportID:         r.ID,
		Decision:         params.Decision,
		Status:           verStatus,
		DiseaseCode:      params.DiseaseCode,
		SuspectedDisease: suspDisease,
		Notes:            params.Notes,
		DiagnosisNotes:   diagNotes,
		VisitRequired:    params.VisitRequired,
		Vet:              &models.VerificationVetEmbed{ID: params.VetUserID, FullName: vetName, RegistrationNo: regNo},
		VetID:            params.VetUserID,
		VetName:          vetName,
		DecidedAt:        now,
		VerifiedAt:       now,
	}
	r.Status = params.Decision
	if params.Decision == "confirmed" {
		r.ConfirmedDiseaseCode = params.DiseaseCode
	} else {
		r.ConfirmedDiseaseCode = nil
	}
	r.UpdatedAt = now

	// Create notification for farmer
	s.notifications[r.FarmerID] = append([]models.NotificationDTO{
		{
			ID:        uuid.NewString(),
			UserID:    r.FarmerID,
			Type:      "report_verified",
			ReportID:  &r.ID,
			Title:     "पशुवैद्यकीय तपासणी पूर्ण / Veterinary Review Complete",
			Body:      fmt.Sprintf("तुमच्या अहवालाची स्थिती: %s", params.Decision),
			Language:  "mr",
			CreatedAt: now,
		},
	}, s.notifications[r.FarmerID]...)

	c := *r
	return &c, nil
}

func (s *InMemoryStore) GetDashboardSummary(ctx context.Context, districtID string) (map[string]any, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var total, submitted, underReview, confirmed, rejected, flagged int
	diseaseCounts := make(map[string]int)

	for _, r := range s.reports {
		total++
		switch r.Status {
		case "submitted":
			submitted++
		case "under_review":
			underReview++
		case "confirmed":
			confirmed++
			if r.ConfirmedDiseaseCode != nil {
				diseaseCounts[*r.ConfirmedDiseaseCode]++
			}
		case "rejected":
			rejected++
		case "flagged":
			flagged++
		}
	}

	var byDisease []map[string]any
	var topDiseases []map[string]any
	for code, cnt := range diseaseCounts {
		pct := 0.0
		if confirmed > 0 {
			pct = math.Round(float64(cnt)*1000.0/float64(confirmed)) / 10.0
		}
		byDisease = append(byDisease, map[string]any{
			"disease_code": code,
			"disease_name": code,
			"count":        cnt,
		})
		topDiseases = append(topDiseases, map[string]any{
			"disease_name": code,
			"count":        cnt,
			"percentage":   pct,
		})
	}
	if byDisease == nil {
		byDisease = []map[string]any{}
	}
	if topDiseases == nil {
		topDiseases = []map[string]any{}
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
			"active_outbreaks": len(s.outbreaks),
		},
		"confirmed_by_disease": byDisease,
		"confirmed_by_taluka": []map[string]any{
			{"taluka_id": "11111111-1111-4111-8111-111111111301", "taluka_name": "Phaltan", "count": confirmed},
		},
		"total_reports":   total,
		"pending_reports": submitted + underReview,
		"verified_cases":  confirmed,
		"resolved_cases":  0,
		"top_diseases":    topDiseases,
		"district_breakdown": []map[string]any{
			{"district": "Satara", "case_count": confirmed, "risk_level": "high"},
		},
		"ml_risk_summary": map[string]any{
			"overall_risk_score": 0.74,
			"risk_level":         "high",
			"forecast_days":      14,
			"disclaimer":         "Experimental estimate. Not a confirmed forecast.",
			"high_risk_districts": []map[string]any{
				{"district": "Satara", "risk_score": 0.74, "dominant_threat": "Lumpy Skin Disease (LSD)"},
			},
			"key_factors":   []string{"confirmed_cases_14d", "post_monsoon_humidity", "vector_density_index"},
			"model_version": "xgb_outbreak_risk_v1.0.0",
			"last_updated":  time.Now().UTC().Format(time.RFC3339),
		},
	}, nil
}

func (s *InMemoryStore) GetDashboardTimeseries(ctx context.Context, districtID string, days int) ([]map[string]any, error) {
	if days <= 0 {
		days = 14
	}
	var series []map[string]any
	now := time.Now().UTC()
	for i := days - 1; i >= 0; i-- {
		d := now.AddDate(0, 0, -i).Format("2006-01-02")
		series = append(series, map[string]any{
			"date":      d,
			"confirmed": 1,
			"reported":  2,
		})
	}
	return series, nil
}

func (s *InMemoryStore) GetConfirmedMapCases(ctx context.Context, districtID, diseaseCode string) ([]map[string]any, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var features []map[string]any
	for _, r := range s.reports {
		if r.Status != "confirmed" || r.ConfirmedDiseaseCode == nil {
			continue
		}
		if diseaseCode != "" && *r.ConfirmedDiseaseCode != diseaseCode {
			continue
		}
		confTime := r.UpdatedAt.UTC().Format(time.RFC3339)
		features = append(features, map[string]any{
			"type": "Feature",
			"geometry": map[string]any{
				"type":        "Point",
				"coordinates": []float64{r.Longitude, r.Latitude},
			},
			"properties": map[string]any{
				"report_id":      r.ID,
				"disease_code":   *r.ConfirmedDiseaseCode,
				"disease_name":   *r.ConfirmedDiseaseCode,
				"species_code":   r.Animal.SpeciesCode,
				"animal_species": r.Animal.SpeciesCode,
				"status":         "confirmed",
				"district":       r.District,
				"taluka":         r.Taluka,
				"confirmed_at":   confTime,
				"reported_date":  confTime,
				"latitude":       r.Latitude,
				"longitude":      r.Longitude,
				"confidence":     0.92,
			},
		})
	}
	if features == nil {
		features = []map[string]any{}
	}
	return features, nil
}

func (s *InMemoryStore) ListOutbreaks(ctx context.Context, districtID, status string) ([]models.OutbreakDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []models.OutbreakDTO
	for _, ob := range s.outbreaks {
		if status != "" && ob.Status != status {
			continue
		}
		out = append(out, *ob)
	}
	if out == nil {
		out = []models.OutbreakDTO{}
	}
	return out, nil
}

func (s *InMemoryStore) GetOutbreakByID(ctx context.Context, id string) (*models.OutbreakDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	ob, ok := s.outbreaks[id]
	if !ok {
		return nil, ErrNotFound
	}
	c := *ob
	return &c, nil
}

func (s *InMemoryStore) UpdateOutbreakStatus(ctx context.Context, id, status string) (*models.OutbreakDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	ob, ok := s.outbreaks[id]
	if !ok {
		return nil, ErrNotFound
	}
	ob.Status = status
	c := *ob
	return &c, nil
}

func (s *InMemoryStore) RecomputeOutbreaks(ctx context.Context, districtID string) ([]models.OutbreakDTO, error) {
	return s.ListOutbreaks(ctx, districtID, "active")
}

func (s *InMemoryStore) ListAlerts(ctx context.Context, districtID string) ([]models.AlertDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	var out []models.AlertDTO
	for _, al := range s.alerts {
		out = append(out, *al)
	}
	sort.Slice(out, func(i, j int) bool { return out[i].CreatedAt.After(out[j].CreatedAt) })
	if out == nil {
		out = []models.AlertDTO{}
	}
	return out, nil
}

func (s *InMemoryStore) CreateAlert(ctx context.Context, params CreateAlertParams) (*models.AlertDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	id := uuid.NewString()
	now := time.Now().UTC()
	status := "draft"
	var sentAt *time.Time
	if params.SendNow {
		status = "sent"
		sentAt = &now
	}
	al := &models.AlertDTO{
		ID:               id,
		OutbreakID:       params.OutbreakID,
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
		CreatedAt:        now,
	}
	s.alerts[id] = al
	return al, nil
}

func (s *InMemoryStore) SendAlert(ctx context.Context, alertID string) (*models.AlertDTO, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	al, ok := s.alerts[alertID]
	if !ok {
		return nil, ErrNotFound
	}
	now := time.Now().UTC()
	al.Status = "sent"
	al.SentAt = &now
	c := *al
	return &c, nil
}

func (s *InMemoryStore) ListNotifications(ctx context.Context, userID string) ([]models.NotificationDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	out := append([]models.NotificationDTO{}, s.notifications[userID]...)
	if out == nil {
		out = []models.NotificationDTO{}
	}
	return out, nil
}

func (s *InMemoryStore) MarkNotificationRead(ctx context.Context, userID, notificationID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	list := s.notifications[userID]
	for i := range list {
		if list[i].ID == notificationID {
			now := time.Now().UTC()
			list[i].ReadAt = &now
			s.notifications[userID] = list
			return nil
		}
	}
	return ErrNotFound
}

func (s *InMemoryStore) GetNearbyVeterinarians(ctx context.Context, lat, lng, radiusKm float64) ([]models.NearbyVetDTO, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if radiusKm <= 0 {
		radiusKm = 50.0
	}
	var out []models.NearbyVetDTO
	for _, u := range s.users {
		if u.Role != "vet" || !u.IsActive || u.Profile == nil || u.Profile.Vet == nil {
			continue
		}
		vp := u.Profile.Vet
		if !vp.IsVerified || vp.ClinicLocation == nil {
			continue
		}
		dist := HaversineKm(lat, lng, vp.ClinicLocation.Lat, vp.ClinicLocation.Lng)
		if dist <= radiusKm {
			out = append(out, models.NearbyVetDTO{
				ID:                 u.ID,
				Name:               u.FullName,
				Qualification:      vp.Qualification,
				RegistrationNumber: vp.RegistrationNo,
				ClinicName:         vp.ClinicName,
				Address:            vp.Address,
				Latitude:           vp.ClinicLocation.Lat,
				Longitude:          vp.ClinicLocation.Lng,
				Phone:              u.Phone,
				IsVerified:         vp.IsVerified,
				IsParaVet:          vp.IsParaVet,
				WorkingHours:       vp.WorkingHours,
				DistanceKm:         dist,
			})
		}
	}
	sort.Slice(out, func(i, j int) bool { return out[i].DistanceKm < out[j].DistanceKm })
	if out == nil {
		out = []models.NearbyVetDTO{}
	}
	return out, nil
}
