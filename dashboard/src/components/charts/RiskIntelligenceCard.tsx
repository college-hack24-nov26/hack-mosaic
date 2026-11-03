import React from 'react';
import { ShieldAlert, TrendingUp, Cpu } from 'lucide-react';
import { MLRiskSummary } from '../../types';

interface RiskIntelligenceCardProps {
  summary: MLRiskSummary;
}

export const RiskIntelligenceCard: React.FC<RiskIntelligenceCardProps> = ({ summary }) => {
  const getBadgeClass = (level: string) => {
    switch (level) {
      case 'critical':
        return 'bg-alert-critical text-white';
      case 'high':
        return 'bg-caution-amber text-ink font-semibold';
      case 'medium':
        return 'bg-yellow-100 text-yellow-900 border border-yellow-300';
      default:
        return 'bg-brand-primary/20 text-ink border border-brand-primary';
    }
  };

  return (
    <div className="vetra-card flex flex-col justify-between">
      <div>
        <div className="flex items-center justify-between pb-3 border-b border-black/5">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-alert-light rounded-sm">
              <ShieldAlert className="w-5 h-5 text-alert-critical" />
            </div>
            <div>
              <h3 className="font-figtree font-semibold text-base text-ink">
                AI Outbreak Risk Intelligence
              </h3>
              <p className="text-xs text-ink-metadata font-inter">
                Powered by {summary.model_version}
              </p>
            </div>
          </div>
          <span className={`text-xs px-2.5 py-1 rounded-pill uppercase tracking-wider font-figtree font-bold ${getBadgeClass(summary.risk_level)}`}>
            {summary.risk_level} Risk
          </span>
        </div>

        {/* Gauge / Score */}
        <div className="mt-4 flex items-baseline justify-between">
          <div>
            <span className="text-3xl font-extrabold text-ink font-figtree">
              {Math.round(summary.overall_risk_score * 100)}%
            </span>
            <span className="text-xs text-ink-secondary ml-1.5 font-inter">
              14-Day Outbreak Probability
            </span>
          </div>
          <div className="text-right">
            <span className="inline-flex items-center gap-1 text-xs text-alert-critical font-semibold">
              <TrendingUp className="w-3.5 h-3.5" /> High Velocity
            </span>
          </div>
        </div>

        {/* Top At-Risk Districts */}
        <div className="mt-4">
          <h4 className="text-xs font-semibold uppercase text-ink-secondary tracking-wider mb-2 font-figtree">
            Highest Risk Regions
          </h4>
          <div className="space-y-1.5">
            {summary.high_risk_districts.map((item, idx) => (
              <div key={idx} className="flex items-center justify-between text-sm py-1.5 px-2.5 rounded-sm bg-parchment/60 font-inter">
                <span className="font-medium text-ink">{item.district} District</span>
                <div className="flex items-center gap-2">
                  <span className="text-xs text-ink-metadata">{item.dominant_threat}</span>
                  <span className="font-semibold text-xs text-alert-critical">
                    {Math.round(item.risk_score * 100)}%
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Key Transmission Factors */}
        <div className="mt-4">
          <h4 className="text-xs font-semibold uppercase text-ink-secondary tracking-wider mb-2 font-figtree">
            Top Driving Indicators
          </h4>
          <ul className="space-y-1 text-xs text-ink-secondary font-inter">
            {summary.key_factors.map((factor, idx) => (
              <li key={idx} className="flex items-start gap-1.5">
                <span className="text-caution-amber font-bold">•</span>
                <span>{factor}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>

      <div className="mt-4 pt-3 border-t border-black/5 flex items-center justify-between text-xs text-ink-metadata font-inter">
        <span className="flex items-center gap-1">
          <Cpu className="w-3.5 h-3.5" /> XGBoost Gradient Boosting
        </span>
        <span>Updated: {new Date(summary.last_updated).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
      </div>
    </div>
  );
};

