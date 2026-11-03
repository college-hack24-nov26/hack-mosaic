// @ts-nocheck
import React, { useState } from 'react';
import { DiseaseReport, ReportStatus } from '../../types';
import { Search, Eye, Filter, CheckCircle2, AlertTriangle, Clock } from 'lucide-react';

interface CaseTableProps {
  reports: DiseaseReport[];
  onSelectReport: (report: DiseaseReport) => void;
}

export const CaseTable: React.FC<CaseTableProps> = ({ reports, onSelectReport }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [districtFilter, setDistrictFilter] = useState<string>('all');

  const filteredReports = reports.filter((r) => {
    const matchesSearch =
      r.animal_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.id.toLowerCase().includes(searchTerm.toLowerCase()) ||
      r.farmer_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      (r.tag_number && r.tag_number.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesStatus = statusFilter === 'all' || r.status === statusFilter;
    const matchesDistrict = districtFilter === 'all' || r.district === districtFilter;

    return matchesSearch && matchesStatus && matchesDistrict;
  });

  const getStatusBadge = (status: ReportStatus) => {
    switch (status) {
      case 'verified':
        return (
          <span className="chip-critical">
            <CheckCircle2 className="w-3 h-3" /> Confirmed
          </span>
        );
      case 'submitted':
      case 'under_review':
        return (
          <span className="chip-caution">
            <Clock className="w-3 h-3" /> Pending Review
          </span>
        );
      case 'resolved':
        return (
          <span className="chip-healthy">
            <CheckCircle2 className="w-3 h-3" /> Resolved
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-pill text-xs font-semibold bg-gray-100 text-gray-700">
            {status}
          </span>
        );
    }
  };

  return (
    <div className="vetra-card p-0 overflow-hidden">
      {/* Table Header & Search Controls */}
      <div className="p-4 bg-surface-card border-b border-black/10 flex flex-wrap items-center justify-between gap-3 font-figtree">
        <div>
          <h3 className="font-semibold text-base text-ink">Livestock Case Management</h3>
          <p className="text-xs text-ink-metadata font-inter">
            Filter and inspect field-reported livestock symptoms and veterinary verifications
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Search Input */}
          <div className="relative">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-ink-metadata" />
            <input
              type="text"
              placeholder="Search Tag, Animal, Farmer..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-9 pr-3 py-1.5 text-xs rounded-sm border border-border-hairline bg-parchment text-ink font-inter focus:outline-none focus:border-brand-primary w-56"
            />
          </div>

          {/* Status Filter */}
          <div className="flex items-center gap-1.5 text-xs font-inter text-ink-secondary">
            <Filter className="w-3.5 h-3.5" />
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="py-1.5 px-2 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
            >
              <option value="all">All Statuses</option>
              <option value="verified">Confirmed Outbreak</option>
              <option value="submitted">Pending Review</option>
              <option value="resolved">Resolved</option>
            </select>
          </div>

          {/* District Filter */}
          <select
            value={districtFilter}
            onChange={(e) => setDistrictFilter(e.target.value)}
            className="py-1.5 px-2 text-xs rounded-sm border border-border-hairline bg-parchment text-ink font-inter focus:outline-none focus:border-brand-primary"
          >
            <option value="all">All Districts</option>
            <option value="Pune">Pune</option>
            <option value="Ahmednagar">Ahmednagar</option>
            <option value="Satara">Satara</option>
            <option value="Solapur">Solapur</option>
          </select>
        </div>
      </div>

      {/* Table Element */}
      <div className="overflow-x-auto">
        <table className="w-full text-left border-collapse font-inter text-sm">
          <thead>
            <tr className="bg-parchment/70 text-ink-secondary border-b border-black/10 text-xs font-semibold uppercase tracking-wider font-figtree">
              <th className="py-3 px-4">Case ID & Animal</th>
              <th className="py-3 px-4">Species & Breed</th>
              <th className="py-3 px-4">Reported Symptoms</th>
              <th className="py-3 px-4">Location</th>
              <th className="py-3 px-4">AI Screening</th>
              <th className="py-3 px-4">Status</th>
              <th className="py-3 px-4 text-right">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-black/5">
            {filteredReports.map((report) => {
              const primaryImage = report.images[0];
              const aiPrediction = primaryImage?.tflite_result?.predicted_class || 'Awaiting Analysis';
              const aiConf = primaryImage?.tflite_confidence
                ? `${Math.round(primaryImage.tflite_confidence * 100)}%`
                : '--';

              return (
                <tr
                  key={report.id}
                  onClick={() => onSelectReport(report)}
                  className="hover:bg-parchment/40 cursor-pointer transition-colors"
                >
                  <td className="py-3.5 px-4">
                    <div className="font-figtree font-semibold text-ink">{report.animal_name}</div>
                    <div className="text-xs text-ink-metadata font-mono">
                      {report.tag_number || report.id}
                    </div>
                  </td>
                  <td className="py-3.5 px-4 text-xs text-ink-secondary">
                    {report.animal_species}
                  </td>
                  <td className="py-3.5 px-4">
                    <div className="flex flex-wrap gap-1 max-w-xs">
                      {report.symptoms.slice(0, 2).map((s, idx) => (
                        <span
                          key={idx}
                          className="px-2 py-0.5 rounded-sm bg-black/5 text-[11px] text-ink-secondary"
                        >
                          {s}
                        </span>
                      ))}
                      {report.symptoms.length > 2 && (
                        <span className="text-[11px] text-ink-metadata self-center">
                          +{report.symptoms.length - 2} more
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="py-3.5 px-4 text-xs">
                    <div className="font-medium text-ink">{report.village}</div>
                    <div className="text-ink-metadata">{report.district} District</div>
                  </td>
                  <td className="py-3.5 px-4 text-xs">
                    <div className="font-medium text-ink capitalize">
                      {aiPrediction.replace(/_/g, ' ')}
                    </div>
                    <div className="text-ink-metadata">Confidence: {aiConf}</div>
                  </td>
                  <td className="py-3.5 px-4">{getStatusBadge(report.status)}</td>
                  <td className="py-3.5 px-4 text-right">
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        onSelectReport(report);
                      }}
                      className="inline-flex items-center gap-1 px-3 py-1.5 rounded-sm border border-border-hairline hover:bg-white text-xs font-semibold text-ink transition-colors"
                    >
                      <Eye className="w-3.5 h-3.5" /> Inspect
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>

        {filteredReports.length === 0 && (
          <div className="py-12 text-center text-ink-metadata font-inter text-sm">
            <AlertTriangle className="w-8 h-8 mx-auto mb-2 text-caution-amber" />
            No animal health reports found matching current filters.
          </div>
        )}
      </div>

      <div className="p-3 bg-surface-card border-t border-black/5 flex items-center justify-between text-xs text-ink-metadata font-inter">
        <span>Showing {filteredReports.length} reports</span>
        <span>Standard Refresh: Real-Time Synced</span>
      </div>
    </div>
  );
};

