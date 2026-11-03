import axios, { AxiosInstance } from 'axios';
import { 
  DashboardStats, 
  DiseaseReport, 
  MapCasePin, 
  OutbreakCluster, 
  DiseaseAlert, 
  AuthResponse,
  User 
} from '../types';
import { 
  mockStats, 
  mockReports, 
  mockMapPins, 
  mockClusters, 
  mockAlerts, 
  mockCurrentUser 
} from './mockData';
import districtGeoJSON from '../data/districts.json';

const BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8080/api/v1';

class ApiService {
  private client: AxiosInstance;

  constructor() {
    this.client = axios.create({
      baseURL: BASE_URL,
      timeout: 5000,
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Automatically inject JWT Token from localStorage
    this.client.interceptors.request.use((config) => {
      const token = localStorage.getItem('pashuvani_token');
      if (token) {
        config.headers.Authorization = `Bearer ${token}`;
      }
      return config;
    });
  }

  // Auth Endpoints
  async login(phone_number: string, password: string): Promise<AuthResponse> {
    try {
      const response = await this.client.post('/auth/login', { phone_number, password });
      if (response.data.success) {
        localStorage.setItem('pashuvani_token', response.data.data.access_token);
        return response.data.data;
      }
    } catch {
      console.warn('[API] Backend unreachable, using demo auth fallback.');
    }
    // Fallback demo auth
    const demoResponse: AuthResponse = {
      user: mockCurrentUser,
      access_token: 'mock_jwt_token_demo_authority_pune_district',
      refresh_token: 'mock_refresh_token_demo'
    };
    localStorage.setItem('pashuvani_token', demoResponse.access_token);
    return demoResponse;
  }

  async getMe(): Promise<User> {
    try {
      const response = await this.client.get('/auth/me');
      if (response.data.success) return response.data.data;
    } catch {
      // Fallback
    }
    return mockCurrentUser;
  }

  // Dashboard Endpoints
  async getDashboardStats(district?: string): Promise<DashboardStats> {
    try {
      const response = await this.client.get('/dashboard/stats', { params: { district } });
      if (response.data.success) return response.data.data;
    } catch {
      console.info('[API] Using mock Dashboard Stats');
    }
    return mockStats;
  }

  async getMapPins(status?: string, district?: string): Promise<MapCasePin[]> {
    try {
      const response = await this.client.get('/dashboard/map-data', { params: { status, district } });
      if (response.data.success) return response.data.data;
    } catch {
      console.info('[API] Using mock Map Pins');
    }
    return mockMapPins;
  }

  async getClusters(): Promise<OutbreakCluster[]> {
    try {
      const response = await this.client.get('/dashboard/clusters');
      if (response.data.success) return response.data.data;
    } catch {
      console.info('[API] Using mock Outbreak Clusters');
    }
    return mockClusters;
  }

  // Reports Management
  async getReports(status?: string, district?: string): Promise<DiseaseReport[]> {
    try {
      const response = await this.client.get('/reports', { params: { status, district } });
      if (response.data.success) return response.data.data;
    } catch {
      console.info('[API] Using mock Reports');
    }
    return mockReports;
  }

  async getReportById(id: string): Promise<DiseaseReport | undefined> {
    try {
      const response = await this.client.get(`/reports/${id}`);
      if (response.data.success) return response.data.data;
    } catch {
      // Fallback
    }
    return mockReports.find(r => r.id === id);
  }

  // Alerts Management
  async getAlerts(district?: string): Promise<DiseaseAlert[]> {
    try {
      const response = await this.client.get('/alerts', { params: { district, is_active: true } });
      if (response.data.success) return response.data.data;
    } catch {
      console.info('[API] Using mock Alerts');
    }
    return mockAlerts;
  }

  async createAlert(alertData: Partial<DiseaseAlert>): Promise<DiseaseAlert> {
    try {
      const response = await this.client.post('/alerts', alertData);
      if (response.data.success) return response.data.data;
    } catch {
      console.info('[API] Simulating alert creation');
    }
    const newAlert: DiseaseAlert = {
      id: `alt_${Date.now()}`,
      title: alertData.title || 'Official Surveillance Alert',
      message: alertData.message || '',
      severity: alertData.severity || 'high',
      affected_district: alertData.affected_district || 'Pune',
      disease_name: alertData.disease_name || 'Livestock Epidemic',
      is_active: true,
      created_at: new Date().toISOString()
    };
    mockAlerts.unshift(newAlert);
    return newAlert;
  }
  // Geographic / GeoJSON Boundary Data
  async getDistrictGeoJSON(): Promise<any> {
    try {
      const response = await this.client.get('/dashboard/districts-geojson');
      if (response.data && response.data.success && response.data.data) {
        return response.data.data;
      }
    } catch {
      // API fallback
    }

    try {
      const res = await fetch('/geo/districts.json');
      if (res.ok) {
        return await res.json();
      }
    } catch {
      // Static fallback
    }

    return districtGeoJSON;
  }
}

export { districtGeoJSON };
export const api = new ApiService();

