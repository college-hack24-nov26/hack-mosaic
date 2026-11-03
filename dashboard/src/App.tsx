import React, { useState, useEffect } from 'react';
import { AuthProvider, useAuth } from './context/AuthContext';
import { Navbar } from './components/layout/Navbar';
import { Sidebar, TabType } from './components/layout/Sidebar';
import { SplashScreen } from './components/layout/SplashScreen';
import { TopAlertBanner } from './components/alerts/TopAlertBanner';
import { BroadcastAlertModal } from './components/alerts/BroadcastAlertModal';
import { CaseDetailModal } from './components/cases/CaseDetailModal';
import { OverviewPage } from './pages/OverviewPage';
import { SurveillanceMapPage } from './pages/SurveillanceMapPage';
import { ProtocolsPage } from './pages/ProtocolsPage';
import { CasesPage } from './pages/CasesPage';
import { AlertsPage } from './pages/AlertsPage';
import { LoginPage } from './pages/LoginPage';
import { api } from './services/api';
import {
  DashboardStats,
  MapCasePin,
  OutbreakCluster,
  DiseaseReport,
  DiseaseAlert,
} from './types';
import { mockStats, mockMapPins, mockClusters, mockReports, mockAlerts } from './services/mockData';

const DashboardContent: React.FC = () => {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [showSplash, setShowSplash] = useState(true);
  const [activeTab, setActiveTab] = useState<TabType>('overview');
  const [stats, setStats] = useState<DashboardStats>(mockStats);
  const [pins, setPins] = useState<MapCasePin[]>(mockMapPins);
  const [clusters, setClusters] = useState<OutbreakCluster[]>(mockClusters);
  const [reports, setReports] = useState<DiseaseReport[]>(mockReports);
  const [alerts, setAlerts] = useState<DiseaseAlert[]>(mockAlerts);

  const [selectedReport, setSelectedReport] = useState<DiseaseReport | null>(null);
  const [isBroadcastModalOpen, setIsBroadcastModalOpen] = useState(false);

  // Fetch initial data from Go backend (or mock fallback)
  useEffect(() => {
    if (!isAuthenticated) return;

    const loadData = async () => {
      try {
        const [statsData, pinsData, clustersData, reportsData, alertsData] = await Promise.all([
          api.getDashboardStats(),
          api.getMapPins(),
          api.getClusters(),
          api.getReports(),
          api.getAlerts(),
        ]);

        if (statsData) setStats(statsData);
        if (pinsData) setPins(pinsData);
        if (clustersData) setClusters(clustersData);
        if (reportsData) setReports(reportsData);
        if (alertsData) setAlerts(alertsData);
      } catch (err) {
        console.warn('[Dashboard] Data fetch fallback engaged:', err);
      }
    };

    loadData();
  }, [isAuthenticated]);

  if (authLoading) {
    return (
      <div className="min-h-screen bg-parchment flex items-center justify-center font-figtree">
        <div className="flex items-center gap-2 text-ink font-semibold">
          <div className="w-4 h-4 border-2 border-ink border-t-transparent rounded-full animate-spin"></div>
          Loading PashuRakshak Surveillance Network...
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <LoginPage />;
  }

  const handleCreateAlert = async (alertData: Partial<DiseaseAlert>) => {
    const created = await api.createAlert(alertData);
    setAlerts((prev) => [created, ...prev]);
  };

  const handleSelectCaseById = (reportId: string) => {
    const found = reports.find((r) => r.id === reportId);
    if (found) setSelectedReport(found);
  };

  return (
    <div className="min-h-screen bg-parchment flex flex-col font-figtree text-ink selection:bg-brand-primary selection:text-ink relative">
      {/* 0. Netflix-Style Cinematic Intro Splash Screen */}
      {showSplash && <SplashScreen onDismiss={() => setShowSplash(false)} />}

      {/* 1. Conditional Top Outbreak Risk Alert Banner */}
      <TopAlertBanner
        riskSummary={stats.ml_risk_summary}
        onViewDetails={() => setActiveTab('map')}
      />

      {/* 2. Top Header Navigation */}
      <Navbar
        onOpenBroadcast={() => setIsBroadcastModalOpen(true)}
        onNavigateToMap={() => setActiveTab('map')}
        onReplayIntro={() => setShowSplash(true)}
      />

      {/* 3. Main Body: Sidebar + Active Canvas */}
      <div className="flex-1 flex overflow-hidden">
        <Sidebar
          activeTab={activeTab}
          onTabChange={setActiveTab}
          pendingCount={stats.pending_reports}
          alertCount={alerts.length}
        />

        <main className="flex-1 p-6 overflow-y-auto max-w-7xl mx-auto w-full">
          {activeTab === 'overview' && (
            <OverviewPage
              stats={stats}
              pins={pins}
              clusters={clusters}
              reports={reports}
              onNavigateToMap={() => setActiveTab('map')}
              onNavigateToCases={() => setActiveTab('cases')}
              onSelectCase={handleSelectCaseById}
            />
          )}

          {activeTab === 'map' && (
            <SurveillanceMapPage
              pins={pins}
              clusters={clusters}
              onSelectCase={handleSelectCaseById}
              onNavigateOverview={() => setActiveTab('overview')}
            />
          )}

          {activeTab === 'protocols' && (
            <ProtocolsPage
              onNavigateToMapCluster={(_disease) => setActiveTab('map')}
            />
          )}

          {activeTab === 'cases' && (
            <CasesPage
              reports={reports}
              onSelectReport={setSelectedReport}
            />
          )}

          {activeTab === 'alerts' && (
            <AlertsPage
              alerts={alerts}
              onOpenBroadcast={() => setIsBroadcastModalOpen(true)}
            />
          )}
        </main>
      </div>

      {/* Slide-Over / Modal: Full Case Inspection */}
      <CaseDetailModal
        report={selectedReport}
        onClose={() => setSelectedReport(null)}
      />

      {/* Modal: Broadcast Alert to District */}
      <BroadcastAlertModal
        isOpen={isBroadcastModalOpen}
        onClose={() => setIsBroadcastModalOpen(false)}
        onSubmit={handleCreateAlert}
      />
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <AuthProvider>
      <DashboardContent />
    </AuthProvider>
  );
};

export default App;
