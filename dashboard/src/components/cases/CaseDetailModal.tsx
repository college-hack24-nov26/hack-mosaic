import React from 'react';
import { DiseaseReport } from '../../types';
import { X, ShieldCheck, Cpu, Sparkles, MapPin, Phone, User, Calendar, Tag } from 'lucide-react';

interface CaseDetailModalProps {
  report: DiseaseReport | null;
  onClose: () => void;
}

export const CaseDetailModal: React.FC<CaseDetailModalProps> = ({ report, onClose }) => {
  if (!report) return null;

  const primaryImage = report.images[0];
  const tflite = primaryImage?.tflite_result;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 overflow-y-auto animate-fadeIn font-figtree">
      <div className="bg-surface-card rounded-md max-w-2xl w-full max-h-[90vh] overflow-y-auto border border-black/15 shadow-2xl relative">
        {/* Header */}
        <div className="sticky top-0 bg-surface-card p-5 border-b border-black/10 flex items-center justify-between z-10">
          <div>
            <div className="flex items-center gap-2">
              <span className="text-xs font-mono bg-parchment px-2 py-0.5 rounded text-ink-metadata">
                {report.id}
              </span>
              {report.status === 'verified' && (
                <span className="chip-critical">
                  <ShieldCheck className="w-3.5 h-3.5" /> Vet Confirmed Outbreak
                </span>
              )}
              {report.status === 'submitted' && (
                <span className="chip-caution">Pending Review</span>
              )}
              {report.status === 'resolved' && (
                <span className="chip-healthy">Resolved</span>
              )}
            </div>
            <h2 className="text-xl font-bold text-ink mt-1">
              {report.animal_name} — {report.animal_species}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="p-2 text-ink-metadata hover:text-ink hover:bg-parchment rounded-sm transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-6 space-y-6">
          {/* Top Info Grid */}
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 bg-parchment/60 p-4 rounded-sm border border-black/5 text-xs font-inter">
            <div>
              <span className="text-ink-metadata block flex items-center gap-1">
                <Tag className="w-3 h-3" /> Tag Number
              </span>
              <strong className="text-ink font-mono">{report.tag_number || 'N/A'}</strong>
            </div>
            <div>
              <span className="text-ink-metadata block flex items-center gap-1">
                <User className="w-3 h-3" /> Farmer
              </span>
              <strong className="text-ink">{report.farmer_name}</strong>
            </div>
            <div>
              <span className="text-ink-metadata block flex items-center gap-1">
                <MapPin className="w-3 h-3" /> Location
              </span>
              <strong className="text-ink">{report.village}, {report.district}</strong>
            </div>
            <div>
              <span className="text-ink-metadata block flex items-center gap-1">
                <Calendar className="w-3 h-3" /> Reported Date
              </span>
              <strong className="text-ink">
                {new Date(report.created_at).toLocaleDateString()}
              </strong>
            </div>
          </div>

          {/* Photo and Symptoms */}
          <div>
            <h3 className="text-sm font-semibold uppercase tracking-wider text-ink-secondary mb-2">
              Clinical Image & Reported Symptoms
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {primaryImage && (
                <div className="relative rounded-sm overflow-hidden border border-black/10 h-48 bg-black/5">
                  <img
                    src={primaryImage.image_url}
                    alt="Clinical Presentation"
                    className="w-full h-full object-cover"
                  />
                  <div className="absolute bottom-2 left-2 bg-black/70 backdrop-blur-sm text-white text-[11px] px-2 py-0.5 rounded">
                    Field Photo
                  </div>
                </div>
              )}
              <div className="space-y-3 font-inter">
                <div>
                  <span className="text-xs text-ink-metadata block mb-1">Identified Symptoms:</span>
                  <div className="flex flex-wrap gap-1.5">
                    {report.symptoms.map((s, idx) => (
                      <span
                        key={idx}
                        className="px-2.5 py-1 rounded-sm bg-caution-amber/15 border border-caution-amber/30 text-ink text-xs font-medium"
                      >
                        {s}
                      </span>
                    ))}
                  </div>
                </div>
                <div>
                  <span className="text-xs text-ink-metadata block mb-1">Farmer Description:</span>
                  <p className="text-xs text-ink bg-parchment/70 p-3 rounded-sm border border-black/5">
                    "{report.description}"
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* AI / ML Diagnosis Card */}
          <div className="bg-gradient-to-br from-parchment to-white p-4 rounded-sm border border-black/10 space-y-3 font-inter">
            <div className="flex items-center justify-between border-b border-black/5 pb-2">
              <span className="font-figtree font-bold text-sm text-ink flex items-center gap-1.5">
                <Cpu className="w-4 h-4 text-brand-hover" />
                MobileNetV3 Edge Inference Screening
              </span>
              {tflite && (
                <span className="chip-healthy text-xs">
                  {Math.round(tflite.confidence * 100)}% Match
                </span>
              )}
            </div>

            {tflite && (
              <div className="text-xs text-ink">
                Predicted Pathology:{' '}
                <strong className="capitalize text-sm font-figtree font-bold text-alert-critical">
                  {tflite.predicted_class.replace(/_/g, ' ')}
                </strong>
              </div>
            )}

            {/* Gemini Observation fallback */}
            {report.ml_analyses?.find((m) => m.model_type === 'gemini') && (
              <div className="mt-2 text-xs bg-white p-2.5 rounded-sm border border-black/5 flex items-start gap-2">
                <Sparkles className="w-4 h-4 text-yellow-600 shrink-0 mt-0.5" />
                <div>
                  <strong className="text-ink block font-figtree">Gemini Multimodal Verification:</strong>
                  <span className="text-ink-secondary">
                    {report.ml_analyses.find((m) => m.model_type === 'gemini')?.result.gemini_observations}
                  </span>
                </div>
              </div>
            )}
          </div>

          {/* Veterinarian Verification Section */}
          {report.verification && (
            <div className="bg-vet-light/40 border border-vet-accent/30 p-4 rounded-sm space-y-2 font-inter">
              <div className="flex items-center justify-between pb-2 border-b border-vet-accent/20">
                <div className="flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4 text-vet-accent" />
                  <span className="font-figtree font-bold text-sm text-ink">
                    Official Veterinary Diagnosis
                  </span>
                </div>
                <span className="text-xs text-ink-metadata">
                  Verified by: <strong>{report.verification.vet_name}</strong>
                </span>
              </div>
              <div className="text-xs space-y-1">
                <div>
                  <span className="text-ink-metadata">Confirmed Disease:</span>{' '}
                  <strong className="text-alert-critical font-figtree text-sm">
                    {report.verification.suspected_disease}
                  </strong>
                </div>
                <div>
                  <span className="text-ink-metadata">Clinical Notes:</span>{' '}
                  <span className="text-ink">{report.verification.diagnosis_notes}</span>
                </div>
                <div>
                  <span className="text-ink-metadata">Prescribed Protocol:</span>{' '}
                  <span className="text-ink">{report.verification.treatment_notes}</span>
                </div>
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 bg-parchment/50 border-t border-black/10 flex items-center justify-between">
          <a
            href={`tel:${report.farmer_phone}`}
            className="text-xs font-semibold text-ink flex items-center gap-1.5 hover:underline"
          >
            <Phone className="w-3.5 h-3.5" /> Contact Farmer ({report.farmer_phone})
          </a>
          <button
            onClick={onClose}
            className="px-4 py-2 bg-ink text-white text-xs font-semibold rounded-sm hover:bg-black transition-colors"
          >
            Close Inspector
          </button>
        </div>
      </div>
    </div>
  );
};

