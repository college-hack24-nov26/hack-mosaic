// @ts-nocheck
import React from 'react';
import { DashboardStats, MapCasePin, OutbreakCluster, DiseaseReport } from '../types';
import { RiskIntelligenceCard } from '../components/charts/RiskIntelligenceCard';
import { SurveillanceMap } from '../components/map/SurveillanceMap';
import { ClipboardList, AlertCircle, CheckCircle2, Clock, ShieldAlert, ArrowRight } from 'lucide-react';

interface OverviewPageProps {
  stats: DashboardStats;
  pins: MapCasePin[];
  clusters: OutbreakCluster[];
  reports: DiseaseReport[];
  onNavigateToMap: () => void;
  onNavigateToCases: () => void;
  onSelectCase: (reportId: string) => void;
}

export const OverviewPage: React.FC<OverviewPageProps> = ({
  stats,
  pins,
  clusters,
  reports: _reports,
  onNavigateToMap,
  onNavigateToCases,
  onSelectCase,
}) => {
  return (
    <div className="space-y-6 animate-fadeIn font-figtree">
      {/* Page Title & District Context */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-ink">District Surveillance Overview</h1>
          <p className="text-sm text-ink-secondary font-inter">
            Integrated livestock health monitoring, epidemic risk indicators, and veterinary verifications
          </p>
        </div>
        <div className="flex items-center gap-2 text-xs font-inter bg-surface-card px-3 py-1.5 rounded-sm border border-black/10">
          <span className="text-ink-metadata">Region:</span>
          <span className="font-bold text-ink">Pune Division, Maharashtra</span>
          <span className="text-ink-metadata ml-2">Sync:</span>
          <span className="text-emerald-700 font-semibold">Active</span>
        </div>
      </div>

      {/* KPI Summary Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Total Reports */}
        <div className="vetra-card flex items-center justify-between">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-ink-secondary">
              Total Reports
            </span>
            <div className="text-3xl font-extrabold text-ink mt-1">
              {stats.total_reports}
            </div>
            <span className="text-xs text-ink-metadata font-inter mt-1 block">
              Logged across 5 districts
            </span>
          </div>
          <div className="p-3 bg-black/5 rounded-sm">
            <ClipboardList className="w-6 h-6 text-ink" />
          </div>
        </div>

        {/* Confirmed Outbreaks */}
        <div className="vetra-card flex items-center justify-between border-l-4 border-l-alert-critical">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-alert-critical">
              Confirmed Outbreaks
            </span>
            <div className="text-3xl font-extrabold text-alert-critical mt-1">
              {stats.verified_cases}
            </div>
            <span className="text-xs text-ink-metadata font-inter mt-1 block">
              Verified by Field Vets
            </span>
          </div>
          <div className="p-3 bg-alert-light rounded-sm">
            <AlertCircle className="w-6 h-6 text-alert-critical" />
          </div>
        </div>

        {/* Pending Verification */}
        <div className="vetra-card flex items-center justify-between border-l-4 border-l-caution-amber">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-caution-amber">
              Pending Review
            </span>
            <div className="text-3xl font-extrabold text-ink mt-1">
              {stats.pending_reports}
            </div>
            <span className="text-xs text-ink-metadata font-inter mt-1 block">
              Awaiting Vet Inspection
            </span>
          </div>
          <div className="p-3 bg-caution-light rounded-sm">
            <Clock className="w-6 h-6 text-caution-amber" />
          </div>
        </div>

        {/* Resolved / Quarantined */}
        <div className="vetra-card flex items-center justify-between border-l-4 border-l-brand-primary">
          <div>
            <span className="text-xs font-semibold uppercase tracking-wider text-emerald-800">
              Resolved Cases
            </span>
            <div className="text-3xl font-extrabold text-ink mt-1">
              {stats.resolved_cases}
            </div>
            <span className="text-xs text-ink-metadata font-inter mt-1 block">
              Treated / Contained
            </span>
          </div>
          <div className="p-3 bg-brand-primary/20 rounded-sm">
            <CheckCircle2 className="w-6 h-6 text-emerald-800" />
          </div>
        </div>
      </div>

      {/* Main Grid: Outbreak Map & Risk Intelligence */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* 2 Cols: Live Map */}
        <div className="lg:col-span-2 space-y-2">
          <SurveillanceMap
            pins={pins}
            clusters={clusters}
            onSelectCase={onSelectCase}
          />
          <div className="flex justify-end">
            <button
              onClick={onNavigateToMap}
              className="text-xs font-semibold text-ink hover:text-black flex items-center gap-1 hover:underline pt-1"
            >
              Open Full Surveillance GIS Canvas <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>

        {/* 1 Col: AI / ML Outbreak Intelligence */}
        <div className="space-y-4">
          <RiskIntelligenceCard summary={stats.ml_risk_summary} />

          {/* Quick Action Box */}
          <div className="vetra-card bg-parchment/60 border-dashed border-black/20 p-4">
            <div className="flex items-center gap-2 text-alert-critical font-bold text-sm mb-1">
              <ShieldAlert className="w-4 h-4" /> Epidemic Protocol Action
            </div>
            <p className="text-xs text-ink-secondary font-inter mb-3">
              Veterinary officers in Haveli & Shirur blocks are advised to enforce ring vaccination and monitor transport permits.
            </p>
            <button
              onClick={onNavigateToCases}
              className="w-full text-xs font-semibold py-2 bg-surface-card border border-border-hairline hover:bg-white text-ink rounded-sm transition-colors flex items-center justify-center gap-1"
            >
              Review Pending Case Queue <ArrowRight className="w-3.5 h-3.5" />
            </button>
          </div>
        </div>
      </div>

      {/* Disease Distribution & District Breakdown */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Top Pathologies */}
        <div className="vetra-card">
          <h3 className="font-semibold text-base text-ink mb-1">
            Dominant Pathologies Breakdown
          </h3>
          <p className="text-xs text-ink-metadata font-inter mb-4">
            Prevalence across active reported livestock cases
          </p>

          <div className="space-y-3 font-inter">
            {stats.top_diseases.map((d, idx) => (
              <div key={idx}>
                <div className="flex justify-between text-xs font-medium text-ink mb-1">
                  <span>{d.disease_name}</span>
                  <span className="font-bold">{d.count} cases ({d.percentage}%)</span>
                </div>
                <div className="w-full bg-parchment h-2 rounded-full overflow-hidden border border-black/5">
                  <div
                    className={`h-full rounded-full ${
                      idx === 0
                        ? 'bg-alert-critical'
                        : idx === 1
                        ? 'bg-caution-amber'
                        : 'bg-ink-secondary'
                    }`}
                    style={{ width: `${d.percentage}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* District Risk Table */}
        <div className="vetra-card">
          <h3 className="font-semibold text-base text-ink mb-1">
            District Cluster Density
          </h3>
          <p className="text-xs text-ink-metadata font-inter mb-4">
            Geographic case load and assigned alert status
          </p>

          <div className="space-y-2 font-inter text-xs">
            {stats.district_breakdown.map((item, idx) => (
              <div
                key={idx}
                className="flex items-center justify-between p-2.5 rounded-sm bg-parchment/50 border border-black/5"
              >
                <div className="font-semibold text-ink font-figtree text-sm">
                  {item.district} District
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-ink-secondary font-medium">
                    {item.case_count} Reported Cases
                  </span>
                  <span
                    className={`px-2 py-0.5 rounded-pill uppercase text-[10px] font-bold ${
                      item.risk_level === 'critical'
                        ? 'bg-alert-critical text-white'
                        : item.risk_level === 'high'
                        ? 'bg-caution-amber text-ink font-bold'
                        : 'bg-brand-primary/20 text-ink'
                    }`}
                  >
                    {item.risk_level}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
};

