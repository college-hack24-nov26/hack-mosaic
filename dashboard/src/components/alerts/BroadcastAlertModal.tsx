// @ts-nocheck
import React, { useState } from 'react';
import { X, Send, AlertTriangle } from 'lucide-react';
import { DiseaseAlert } from '../../types';

interface BroadcastAlertModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (alert: Partial<DiseaseAlert>) => void;
}

export const BroadcastAlertModal: React.FC<BroadcastAlertModalProps> = ({ isOpen, onClose, onSubmit }) => {
  const [title, setTitle] = useState('');
  const [district, setDistrict] = useState('Pune');
  const [diseaseName, setDiseaseName] = useState('Foot and Mouth Disease');
  const [severity, setSeverity] = useState<'low' | 'medium' | 'high' | 'critical'>('high');
  const [message, setMessage] = useState('');

  if (!isOpen) return null;

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    onSubmit({
      title,
      affected_district: district,
      disease_name: diseaseName,
      severity,
      message,
    });
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4 animate-fadeIn font-figtree">
      <div className="bg-surface-card rounded-md max-w-lg w-full border border-black/15 shadow-2xl p-6">
        <div className="flex items-center justify-between pb-4 border-b border-black/10">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-alert-light rounded-sm">
              <AlertTriangle className="w-5 h-5 text-alert-critical" />
            </div>
            <div>
              <h3 className="font-bold text-lg text-ink">Broadcast Outbreak Alert</h3>
              <p className="text-xs text-ink-metadata font-inter">
                Dispatches targeted SMS & app warnings to registered farmers in the target district
              </p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 text-ink-metadata hover:text-ink hover:bg-parchment rounded-sm transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="mt-4 space-y-4 text-xs font-inter">
          <div>
            <label className="block text-ink-secondary font-medium mb-1">Alert Headline / Title</label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="e.g. Mandatory Ring Vaccination Order in Haveli Block"
              className="w-full px-3 py-2 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-ink-secondary font-medium mb-1">Target District</label>
              <select
                value={district}
                onChange={(e) => setDistrict(e.target.value)}
                className="w-full px-3 py-2 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
              >
                <option value="Pune">Pune District</option>
                <option value="Ahmednagar">Ahmednagar District</option>
                <option value="Satara">Satara District</option>
                <option value="Solapur">Solapur District</option>
                <option value="Kolhapur">Kolhapur District</option>
              </select>
            </div>

            <div>
              <label className="block text-ink-secondary font-medium mb-1">Alert Severity</label>
              <select
                value={severity}
                onChange={(e) => setSeverity(e.target.value as any)}
                className="w-full px-3 py-2 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary font-semibold"
              >
                <option value="critical">Critical (Immediate Quarantine)</option>
                <option value="high">High (Vector Warning)</option>
                <option value="medium">Medium (Advisory)</option>
                <option value="low">Low (Information)</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-ink-secondary font-medium mb-1">Disease Classification</label>
            <input
              type="text"
              required
              value={diseaseName}
              onChange={(e) => setDiseaseName(e.target.value)}
              placeholder="Foot and Mouth Disease / Lumpy Skin / Anthrax"
              className="w-full px-3 py-2 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
            />
          </div>

          <div>
            <label className="block text-ink-secondary font-medium mb-1">
              Advisory Message & Veterinary Instructions
            </label>
            <textarea
              required
              rows={4}
              value={message}
              onChange={(e) => setMessage(e.target.value)}
              placeholder="Provide explicit instructions for animal isolation, sanitation protocols, and local veterinary dispensary contact numbers..."
              className="w-full px-3 py-2 rounded-sm border border-border-hairline bg-parchment text-ink focus:outline-none focus:border-brand-primary"
            />
          </div>

          <div className="pt-3 border-t border-black/10 flex items-center justify-end gap-2">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-ink-secondary hover:text-ink"
            >
              Cancel
            </button>
            <button
              type="submit"
              className="btn-primary h-10 px-5 text-xs text-ink"
            >
              <Send className="w-3.5 h-3.5" /> Broadcast to Network
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};

