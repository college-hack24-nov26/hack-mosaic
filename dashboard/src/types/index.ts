// Standard API Response Envelope
export interface ApiResponse<T> {
  success: boolean;
  data: T;
  error: {
    code: string;
    message: string;
  } | null;
  meta: {
    timestamp: string;
    request_id: string;
    pagination?: {
      total: number;
      page: number;
      limit: number;
      pages: number;
    };
  };
}

export type UserRole = 'farmer' | 'veterinarian' | 'authority';

export interface User {
  id: string;
  phone_number: string;
  name: string;
  role: UserRole;
  district: string;
  state: string;
  language_preference: string;
}

export interface AuthResponse {
  user: User;
  access_token: string;
  refresh_token: string;
}

export type ReportStatus = 'submitted' | 'under_review' | 'verified' | 'rejected' | 'resolved';

export interface ReportImage {
  id: string;
  image_url: string;
  tflite_result?: {
    predicted_class: string;
    confidence: number;
  };
  tflite_confidence?: number;
}

export interface MLAnalysis {
  id: string;
  report_id: string;
  model_type: 'mobilenet' | 'xgboost' | 'gemini';
  confidence?: number;
  result: {
    disease_class?: string;
    confidence?: number;
    risk_score?: number;
    risk_level?: 'low' | 'medium' | 'high' | 'critical';
    risk_factors?: string[];
    gemini_observations?: string;
  };
  created_at: string;
}

export interface VeterinaryVerification {
  id: string;
  report_id: string;
  vet_id: string;
  vet_name: string;
  status: 'verified' | 'rejected';
  suspected_disease: string;
  diagnosis_notes: string;
  treatment_notes: string;
  follow_up_date?: string;
  verified_at: string;
}

export interface DiseaseReport {
  id: string;
  animal_id: string;
  farmer_id: string;
  farmer_name: string;
  farmer_phone: string;
  animal_name: string;
  animal_species: string;
  tag_number?: string;
  status: ReportStatus;
  symptoms: string[];
  description: string;
  voice_note_url?: string;
  images: ReportImage[];
  latitude: number;
  longitude: number;
  district: string;
  village: string;
  created_at: string;
  updated_at: string;
  verification?: VeterinaryVerification;
  ml_analyses?: MLAnalysis[];
}

export interface MapCasePin {
  report_id: string;
  latitude: number;
  longitude: number;
  animal_species: string;
  disease_name: string;
  status: ReportStatus;
  district: string;
  reported_date: string;
  confidence: number;
}

export interface OutbreakCluster {
  cluster_id: string;
  center_latitude: number;
  center_longitude: number;
  radius_km: number;
  case_count: number;
  primary_disease: string;
  risk_level: 'medium' | 'high' | 'critical';
  district: string;
}

export interface MLRiskSummary {
  overall_risk_score: number;
  risk_level: 'low' | 'medium' | 'high' | 'critical';
  forecast_days: number;
  high_risk_districts: {
    district: string;
    risk_score: number;
    dominant_threat: string;
  }[];
  key_factors: string[];
  model_version: string;
  last_updated: string;
}

export interface DashboardStats {
  total_reports: number;
  pending_reports: number;
  verified_cases: number;
  resolved_cases: number;
  top_diseases: {
    disease_name: string;
    count: number;
    percentage: number;
  }[];
  district_breakdown: {
    district: string;
    case_count: number;
    risk_level: 'low' | 'medium' | 'high' | 'critical';
  }[];
  ml_risk_summary: MLRiskSummary;
}

export interface DiseaseAlert {
  id: string;
  title: string;
  message: string;
  severity: 'low' | 'medium' | 'high' | 'critical';
  affected_district: string;
  disease_name: string;
  is_active: boolean;
  created_at: string;
  expires_at?: string;
}

