// @ts-nocheck
import React from 'react';
import { DiseaseAlert } from '../types';
import { AlertOctagon, Send, ShieldAlert, CheckCircle, Calendar, MapPin } from 'lucide-react';

interface AlertsPageProps {
  alerts: DiseaseAlert[];
  onOpenBroadcast: () => void;
}

export const AlertsPage: React.FC<AlertsPageProps> = ({ alerts, onOpenBroadcast }) => {
  return (
    <div className="space-y-6 animate-fadeIn font-figtree">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-ink">Epidemic Alerts & Quarantine Advisories</h1>
          <p className="text-sm text-ink-secondary font-inter">
            Active district-wide containment notices dispatched to farmers and veterinary clinics
          </p>
        </div>

        <button
          onClick={onOpenBroadcast}
          className="btn-primary text-xs h-10 px-4"
        >
          <Send className="w-3.5 h-3.5" /> Broadcast New Alert
        </button>
      </div>

      <div className="space-y-4">
        {alerts.map((alert) => (
          <div
            key={alert.id}
            className={`vetra-card border-l-4 ${
              alert.severity === 'critical'
                ? 'border-l-alert-critical'
                : alert.severity === 'high'
                ? 'border-l-caution-amber'
                : 'border-l-brand-primary'
            }`}
          >
            <div className="flex flex-wrap items-center justify-between gap-2 pb-2 border-b border-black/5">
              <div className="flex items-center gap-2">
                <span
                  className={`text-[11px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-sm ${
                    alert.severity === 'critical'
                      ? 'bg-alert-critical text-white'
                      : alert.severity === 'high'
                      ? 'bg-caution-amber text-ink'
                      : 'bg-brand-primary/20 text-ink'
                  }`}
                >
                  {alert.severity} Severity
                </span>
                <span className="text-xs text-ink font-semibold flex items-center gap-1 font-inter">
                  <MapPin className="w-3.5 h-3.5 text-ink-metadata" />
                  {alert.affected_district} District
                </span>
                <span className="text-xs text-ink-metadata font-inter">
                  • Target Pathology: <strong>{alert.disease_name}</strong>
                </span>
              </div>

              <div className="flex items-center gap-2 text-xs text-ink-metadata font-inter">
                <Calendar className="w-3.5 h-3.5" />
                Dispatched: {new Date(alert.created_at).toLocaleDateString()}
              </div>
            </div>

            <h3 className="font-bold text-base text-ink mt-3">
              {alert.title}
            </h3>
            <p className="text-xs text-ink-secondary font-inter mt-1.5 leading-relaxed bg-parchment/50 p-3 rounded-sm border border-black/5">
              {alert.message}
            </p>

            <div className="mt-3 flex items-center justify-between text-xs font-inter pt-2 border-t border-black/5">
              <span className="text-emerald-700 font-semibold flex items-center gap-1 text-[11px]">
                <CheckCircle className="w-3.5 h-3.5" /> Broadcast Active (Targeted SMS & App Push Delivered)
              </span>
              {alert.expires_at && (
                <span className="text-ink-metadata text-[11px]">
                  Valid until: {new Date(alert.expires_at).toLocaleDateString()}
                </span>
              )}
            </div>
          </div>
        ))}

        {alerts.length === 0 && (
          <div className="vetra-card text-center py-12 text-ink-metadata">
            <ShieldAlert className="w-8 h-8 mx-auto mb-2 text-ink-metadata" />
            No active epidemic alerts issued for this division.
          </div>
        )}
      </div>
    </div>
  );
};

