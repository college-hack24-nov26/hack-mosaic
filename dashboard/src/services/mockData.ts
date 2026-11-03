// @ts-nocheck
import { DashboardStats, DiseaseReport, MapCasePin, OutbreakCluster, DiseaseAlert, User } from '../types';

export const mockCurrentUser: User = {
  id: 'usr_auth_001',
  phone_number: '+91 98220 12345',
  name: 'Dr. Suresh Patil',
  role: 'authority',
  district: 'Pune',
  state: 'Maharashtra',
  language_preference: 'mr'
};

export const mockStats: DashboardStats = {
  total_reports: 168,
  pending_reports: 24,
  verified_cases: 112,
  resolved_cases: 32,
  top_diseases: [
    { disease_name: 'Foot and Mouth Disease (FMD)', count: 68, percentage: 40.5 },
    { disease_name: 'Lumpy Skin Disease (LSD)', count: 42, percentage: 25.0 },
    { disease_name: 'Blackleg (Quarter Evil)', count: 28, percentage: 16.7 },
    { disease_name: 'Brucellosis', count: 18, percentage: 10.7 },
    { disease_name: 'Anthrax (Suspected)', count: 12, percentage: 7.1 }
  ],
  district_breakdown: [
    { district: 'Pune', case_count: 54, risk_level: 'critical' },
    { district: 'Ahmednagar', case_count: 42, risk_level: 'high' },
    { district: 'Satara', case_count: 31, risk_level: 'medium' },
    { district: 'Solapur', case_count: 26, risk_level: 'high' },
    { district: 'Kolhapur', case_count: 15, risk_level: 'low' }
  ],
  ml_risk_summary: {
    overall_risk_score: 0.84,
    risk_level: 'critical',
    forecast_days: 14,
    high_risk_districts: [
      { district: 'Pune', risk_score: 0.88, dominant_threat: 'Foot and Mouth Disease' },
      { district: 'Ahmednagar', risk_score: 0.82, dominant_threat: 'Lumpy Skin Disease' },
      { district: 'Solapur', risk_score: 0.74, dominant_threat: 'Blackleg' }
    ],
    key_factors: [
      'Sudden +48% spike in bovine oral vesicle reports within Haveli & Shirur talukas',
      'Unseasonal post-monsoon precipitation elevating vector-borne transmission',
      'Weekly cattle market movement along the Pune-Ahmednagar highway corridor'
    ],
    model_version: 'XGBoost-Surveillance-v1.2',
    last_updated: '2026-11-03T11:30:00Z'
  }
};

export const mockMapPins: MapCasePin[] = [
  {
    report_id: 'rpt_001',
    latitude: 18.5204,
    longitude: 73.8567,
    animal_species: 'Cow (Gir)',
    disease_name: 'Foot and Mouth Disease',
    status: 'verified',
    district: 'Pune',
    reported_date: '2026-11-02',
    confidence: 0.92
  },
  {
    report_id: 'rpt_002',
    latitude: 18.7500,
    longitude: 74.1500,
    animal_species: 'Buffalo (Murrah)',
    disease_name: 'Lumpy Skin Disease',
    status: 'verified',
    district: 'Pune',
    reported_date: '2026-11-01',
    confidence: 0.87
  },
  {
    report_id: 'rpt_003',
    latitude: 18.6200,
    longitude: 73.9800,
    animal_species: 'Cow (Jersey Cross)',
    disease_name: 'Foot and Mouth Disease',
    status: 'submitted',
    district: 'Pune',
    reported_date: '2026-11-03',
    confidence: 0.78
  },
  {
    report_id: 'rpt_004',
    latitude: 19.0952,
    longitude: 74.7496,
    animal_species: 'Cow (Khillari)',
    disease_name: 'Lumpy Skin Disease',
    status: 'verified',
    district: 'Ahmednagar',
    reported_date: '2026-10-31',
    confidence: 0.94
  },
  {
    report_id: 'rpt_005',
    latitude: 19.2200,
    longitude: 74.5600,
    animal_species: 'Buffalo (Jaffarabadi)',
    disease_name: 'Blackleg',
    status: 'under_review',
    district: 'Ahmednagar',
    reported_date: '2026-11-02',
    confidence: 0.81
  },
  {
    report_id: 'rpt_006',
    latitude: 17.6805,
    longitude: 74.0183,
    animal_species: 'Cow (Sahiwal)',
    disease_name: 'Brucellosis',
    status: 'verified',
    district: 'Satara',
    reported_date: '2026-10-29',
    confidence: 0.89
  },
  {
    report_id: 'rpt_007',
    latitude: 17.6599,
    longitude: 75.9064,
    animal_species: 'Cow (Deoni)',
    disease_name: 'Foot and Mouth Disease',
    status: 'verified',
    district: 'Solapur',
    reported_date: '2026-11-01',
    confidence: 0.91
  },
  {
    report_id: 'rpt_008',
    latitude: 16.7050,
    longitude: 74.2433,
    animal_species: 'Buffalo (Pandharpuri)',
    disease_name: 'Healthy / Checkup',
    status: 'resolved',
    district: 'Kolhapur',
    reported_date: '2026-10-25',
    confidence: 0.96
  }
];

export const mockClusters: OutbreakCluster[] = [
  {
    cluster_id: 'cls_001',
    center_latitude: 18.5800,
    center_longitude: 73.9200,
    radius_km: 18,
    case_count: 28,
    primary_disease: 'Foot and Mouth Disease',
    risk_level: 'critical',
    district: 'Pune'
  },
  {
    cluster_id: 'cls_002',
    center_latitude: 19.1400,
    center_longitude: 74.6800,
    radius_km: 24,
    case_count: 19,
    primary_disease: 'Lumpy Skin Disease',
    risk_level: 'high',
    district: 'Ahmednagar'
  },
  {
    cluster_id: 'cls_003',
    center_latitude: 17.6700,
    center_longitude: 75.8800,
    radius_km: 15,
    case_count: 14,
    primary_disease: 'Foot and Mouth Disease',
    risk_level: 'high',
    district: 'Solapur'
  }
];

export const mockReports: DiseaseReport[] = [
  {
    id: 'rpt_001',
    animal_id: 'ani_9021',
    farmer_id: 'frm_102',
    farmer_name: 'Ramesh Balu Shinde',
    farmer_phone: '+91 98231 44556',
    animal_name: 'Lakshmi',
    animal_species: 'Cow (Gir Breed)',
    tag_number: 'MH-PUN-2024-8841',
    status: 'verified',
    symptoms: ['Excessive Salivation', 'Blisters on Tongue', 'Lameness in hind legs', 'High Fever (105°F)'],
    description: 'Animal has not been eating fodder since yesterday morning. Drooling profusely with clear distress when walking.',
    images: [
      {
        id: 'img_01',
        image_url: 'https://images.unsplash.com/photo-1546445317-29f4545e9d53?auto=format&fit=crop&q=80&w=800',
        tflite_result: {
          predicted_class: 'foot_and_mouth_disease',
          confidence: 0.92
        },
        tflite_confidence: 0.92
      }
    ],
    latitude: 18.5204,
    longitude: 73.8567,
    district: 'Pune',
    village: 'Haveli',
    created_at: '2026-11-02T08:15:00Z',
    updated_at: '2026-11-02T11:45:00Z',
    verification: {
      id: 'ver_001',
      report_id: 'rpt_001',
      vet_id: 'vet_044',
      vet_name: 'Dr. Anita Deshmukh',
      status: 'verified',
      suspected_disease: 'Foot and Mouth Disease (FMD)',
      diagnosis_notes: 'Clinical signs confirm acute FMD outbreak. Blisters present inside buccal cavity and interdigital space.',
      treatment_notes: 'Administered broad-spectrum antibiotic injection to prevent secondary bacterial infection. Recommended potassium permanganate mouth wash.',
      follow_up_date: '2026-11-06',
      verified_at: '2026-11-02T11:45:00Z'
    },
    ml_analyses: [
      {
        id: 'mla_001',
        report_id: 'rpt_001',
        model_type: 'mobilenet',
        confidence: 0.92,
        result: {
          disease_class: 'foot_and_mouth_disease',
          confidence: 0.92
        },
        created_at: '2026-11-02T08:16:00Z'
      },
      {
        id: 'mla_002',
        report_id: 'rpt_001',
        model_type: 'gemini',
        result: {
          gemini_observations: 'Visual inspection shows characteristic erosive lesions on buccal mucosa and foot rot signs consistent with Aphthovirus.'
        },
        created_at: '2026-11-02T08:16:30Z'
      }
    ]
  },
  {
    id: 'rpt_002',
    animal_id: 'ani_9034',
    farmer_id: 'frm_108',
    farmer_name: 'Vikas Tukaram Kadam',
    farmer_phone: '+91 97654 33211',
    animal_name: 'Kalu',
    animal_species: 'Buffalo (Murrah)',
    tag_number: 'MH-PUN-2024-9102',
    status: 'verified',
    symptoms: ['Skin Nodules (2-5cm)', 'Swollen Lymph Nodes', 'Lethargy', 'Decreased Milk Yield'],
    description: 'Hard circular nodules appeared all over neck and back. Milk yield dropped from 12L to 3L.',
    images: [
      {
        id: 'img_02',
        image_url: 'https://images.unsplash.com/photo-1527153857715-3908f2bae5e8?auto=format&fit=crop&q=80&w=800',
        tflite_result: {
          predicted_class: 'lumpy_skin_disease',
          confidence: 0.87
        },
        tflite_confidence: 0.87
      }
    ],
    latitude: 18.7500,
    longitude: 74.1500,
    district: 'Pune',
    village: 'Shirur',
    created_at: '2026-11-01T14:30:00Z',
    updated_at: '2026-11-01T17:20:00Z',
    verification: {
      id: 'ver_002',
      report_id: 'rpt_002',
      vet_id: 'vet_012',
      vet_name: 'Dr. Sanjay Thorat',
      status: 'verified',
      suspected_disease: 'Lumpy Skin Disease (LSD)',
      diagnosis_notes: 'Typical cutaneous nodular eruption. Contagious vector-borne poxvirus.',
      treatment_notes: 'Anti-inflammatory and supportive vitamin therapy. Strict isolation ordered from adjacent sheds.',
      follow_up_date: '2026-11-08',
      verified_at: '2026-11-01T17:20:00Z'
    }
  },
  {
    id: 'rpt_003',
    animal_id: 'ani_9045',
    farmer_id: 'frm_122',
    farmer_name: 'Sunita Popat Gaikwad',
    farmer_phone: '+91 94220 88990',
    animal_name: 'Gauri',
    animal_species: 'Cow (Jersey Cross)',
    tag_number: 'MH-PUN-2025-1104',
    status: 'submitted',
    symptoms: ['Sore Hooves', 'Mild Drooling', 'Loss of Appetite'],
    description: 'Animal limping since this morning. Minor lesions noticed on lower gum.',
    images: [
      {
        id: 'img_03',
        image_url: 'https://images.unsplash.com/photo-1500595046743-cd271d694d30?auto=format&fit=crop&q=80&w=800',
        tflite_result: {
          predicted_class: 'foot_and_mouth_disease',
          confidence: 0.78
        },
        tflite_confidence: 0.78
      }
    ],
    latitude: 18.6200,
    longitude: 73.9800,
    district: 'Pune',
    village: 'Khed',
    created_at: '2026-11-03T07:10:00Z',
    updated_at: '2026-11-03T07:10:00Z'
  }
];

export const mockAlerts: DiseaseAlert[] = [
  {
    id: 'alt_001',
    title: 'Urgent Quarantine Advisory: Foot & Mouth Disease Cluster in Pune District',
    message: 'High transmission velocity detected in Haveli and Khed blocks. Immediate prohibition of livestock transportation and mandatory ring vaccination in a 10km radius ordered.',
    severity: 'critical',
    affected_district: 'Pune',
    disease_name: 'Foot and Mouth Disease',
    is_active: true,
    created_at: '2026-11-02T14:00:00Z',
    expires_at: '2026-11-16T14:00:00Z'
  },
  {
    id: 'alt_002',
    title: 'Vector Control Warning: Lumpy Skin Disease Surge in Ahmednagar',
    message: 'Elevated mosquito and biting fly activity observed. Farmers advised to spray sheds with eco-friendly neem vector repellant and report any new cutaneous nodules.',
    severity: 'high',
    affected_district: 'Ahmednagar',
    disease_name: 'Lumpy Skin Disease',
    is_active: true,
    created_at: '2026-11-01T10:30:00Z',
    expires_at: '2026-11-15T10:30:00Z'
  },
  {
    id: 'alt_003',
    title: 'Pre-Winter Preventive Vaccination Drive: Blackleg in Solapur',
    message: 'Veterinary dispensary camps operating across 42 gram panchayats for clostridial disease immunization.',
    severity: 'medium',
    affected_district: 'Solapur',
    disease_name: 'Blackleg',
    is_active: true,
    created_at: '2026-10-30T09:00:00Z',
    expires_at: '2026-11-13T09:00:00Z'
  }
];

