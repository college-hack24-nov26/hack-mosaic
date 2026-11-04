// @ts-nocheck
import React, { useState } from 'react';
import { MapCasePin, OutbreakCluster } from '../types';
import { SurveillanceMap } from '../components/map/SurveillanceMap';
import { MapPin, Map, Table, Download, RefreshCw, ChevronLeft } from 'lucide-react';

interface SurveillanceMapPageProps {
  pins: MapCasePin[];
  clusters: OutbreakCluster[];
  onSelectCase: (reportId: string) => void;
  onNavigateOverview?: () => void;
}

export const SurveillanceMapPage: React.FC<SurveillanceMapPageProps> = ({
  pins,
  clusters,
  onSelectCase,
  onNavigateOverview,
}) => {
  const [viewMode, setViewMode] = useState<'map' | 'table'>('map');

  const exportCSV = () => {
    let csv = 'ID,Disease,District,Latitude,Longitude,Status\n';
    pins.forEach((p) => {
      csv += `${p.report_id},${p.disease_name},"${p.district}",${p.latitude},${p.longitude},${p.status}\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'pashuvani_vector_points.csv';
    link.click();
  };

  return (
    <div className="space-y-3 animate-fadeIn font-figtree">
      {/* Subheader & Action Bar from Reference Screenshot 1 */}
      <div className="bg-surface-card p-4 rounded-xl border border-black/10 shadow-sm space-y-3">
        <div className="flex items-start justify-between gap-4">
          <div>
            <div className="flex items-center gap-2">
              {onNavigateOverview && (
                <button
                  onClick={onNavigateOverview}
                  className="text-xs font-semibold px-2.5 py-1 rounded bg-parchment border border-black/10 hover:bg-white flex items-center gap-1"
                >
                  <ChevronLeft className="w-3.5 h-3.5" /> Overview
                </button>
              )}
              <div className="p-1 rounded bg-blue-50 text-vet-accent">
                <Map className="w-4 h-4" />
              </div>
              <h2 className="text-base font-bold text-ink font-figtree">
                Live GIS Epidemiological Surveillance Map
              </h2>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-50 text-vet-accent border border-blue-200 font-semibold">
                PostGIS RFC 7946 Stream
              </span>
            </div>
            <p className="text-xs text-ink-metadata font-inter mt-1">
              Statewide spatial cluster tracking • WGS84 GeoJSON vectors • Administrative boundary layers
            </p>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-2 text-xs font-inter">
            <button
              onClick={() => setViewMode('map')}
              className={`px-3 py-1.5 rounded-lg border font-bold shadow-sm flex items-center gap-1.5 transition-all ${
                viewMode === 'map'
                  ? 'bg-white border-black/20 text-ink'
                  : 'bg-parchment/60 border-black/10 text-ink-secondary hover:text-ink'
              }`}
            >
              <MapPin className="w-3.5 h-3.5 text-vet-accent" />
              <span>Spatial Map View</span>
            </button>
            <button
              onClick={() => setViewMode('table')}
              className={`px-3 py-1.5 rounded-lg border font-semibold flex items-center gap-1.5 transition-all ${
                viewMode === 'table'
                  ? 'bg-white border-black/20 text-ink font-bold'
                  : 'bg-parchment/60 border-black/10 text-ink-secondary hover:text-ink'
              }`}
            >
              <Table className="w-3.5 h-3.5" />
              <span>Accessible Table (WCAG)</span>
            </button>
            <button
              onClick={exportCSV}
              className="px-3 py-1.5 rounded-lg bg-[#107c41] hover:bg-[#158b4a] text-white font-bold shadow-sm flex items-center gap-1.5 cursor-pointer"
            >
              <Download className="w-3.5 h-3.5" />
              <span>Export GIS (CSV)</span>
            </button>
            <button
              onClick={() => alert('PostGIS spatial stream synced.')}
              className="px-3 py-1.5 rounded-lg bg-[#107c41] hover:bg-[#158b4a] text-white font-bold shadow-sm flex items-center gap-1.5 cursor-pointer"
            >
              <RefreshCw className="w-3.5 h-3.5" />
              <span>Sync</span>
            </button>
          </div>
        </div>
      </div>

      {viewMode === 'map' ? (
        <SurveillanceMap pins={pins} clusters={clusters} onSelectCase={onSelectCase} />
      ) : (
        <div className="vetra-card p-0 overflow-hidden">
          <div className="p-4 border-b border-black/10 bg-white flex justify-between items-center">
            <span className="font-bold text-sm text-ink">WCAG Accessible Outbreak Spatial Records</span>
            <span className="text-xs text-ink-metadata font-mono">Standard GeoJSON Attributes</span>
          </div>
          <table className="w-full text-left font-inter text-xs">
            <thead className="bg-parchment text-[11px] uppercase font-bold text-ink-secondary">
              <tr>
                <th className="py-3 px-4">Case ID</th>
                <th className="py-3 px-4">Disease</th>
                <th className="py-3 px-4">District</th>
                <th className="py-3 px-4">Coordinates</th>
                <th className="py-3 px-4">Status</th>
                <th className="py-3 px-4 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/5">
              {pins.map((pin) => (
                <tr key={pin.report_id} className="hover:bg-parchment/40">
                  <td className="py-3 px-4 font-mono font-bold">{pin.report_id}</td>
                  <td className="py-3 px-4 font-semibold text-ink">{pin.disease_name}</td>
                  <td className="py-3 px-4 text-ink-secondary">{pin.district}</td>
                  <td className="py-3 px-4 font-mono text-ink-metadata">
                    {pin.latitude.toFixed(4)}, {pin.longitude.toFixed(4)}
                  </td>
                  <td className="py-3 px-4">
                    <span
                      className={`px-2 py-0.5 rounded-pill font-bold text-[10px] ${
                        pin.status === 'verified'
                          ? 'chip-critical'
                          : 'chip-caution'
                      }`}
                    >
                      {pin.status.toUpperCase()}
                    </span>
                  </td>
                  <td className="py-3 px-4 text-right">
                    <button
                      onClick={() => onSelectCase(pin.report_id)}
                      className="px-2.5 py-1 bg-white border border-black/15 rounded text-xs font-bold hover:bg-parchment"
                    >
                      Inspect
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
};
