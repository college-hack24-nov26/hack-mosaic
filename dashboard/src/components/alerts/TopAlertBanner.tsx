// @ts-nocheck
import React from 'react';
import { AlertTriangle, ChevronRight } from 'lucide-react';
import { MLRiskSummary } from '../../types';

interface TopAlertBannerProps {
  riskSummary: MLRiskSummary;
  onViewDetails?: () => void;
}

export const TopAlertBanner: React.FC<TopAlertBannerProps> = ({ riskSummary, onViewDetails }) => {
  if (riskSummary.risk_level !== 'critical' && riskSummary.risk_level !== 'high') {
    return null;
  }

  const highDistricts = riskSummary.high_risk_districts.map(d => d.district).join(', ');

  return (
    <div className="w-full bg-alert-critical text-white px-4 py-3 shadow-md flex flex-wrap items-center justify-between gap-3 font-figtree animate-fadeIn">
      <div className="flex items-center gap-3">
        <div className="p-1.5 bg-white/20 rounded-sm">
          <AlertTriangle className="w-5 h-5 fill-white text-alert-critical" />
        </div>
        <div>
          <span className="font-bold text-sm tracking-wide uppercase mr-2 bg-black/25 px-2 py-0.5 rounded-sm">
            URGENT EPIDEMIC ALERT
          </span>
          <span className="text-sm font-medium">
            High Outbreak Probability in <strong>{highDistricts}</strong> — Elevated transmission trajectory detected by {riskSummary.model_version}.
          </span>
        </div>
      </div>
      {onViewDetails && (
        <button
          onClick={onViewDetails}
          className="text-xs font-semibold uppercase tracking-wider bg-white text-alert-critical px-3 py-1.5 rounded-sm hover:bg-white/90 transition-colors flex items-center gap-1 shrink-0"
        >
          View Hotspot Clusters <ChevronRight className="w-3.5 h-3.5" />
        </button>
      )}
    </div>
  );
};

