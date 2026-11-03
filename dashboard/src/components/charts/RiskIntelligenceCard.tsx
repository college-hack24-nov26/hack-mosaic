// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, 
  TrendingUp, 
  Cpu, 
  Syringe, 
  Send, 
  Sliders, 
  CheckCircle2, 
  Info,
  ChevronDown
} from 'lucide-react';
import { 
  predictDistrictOutbreakRisk, 
  DistrictRiskPrediction, 
  XGBOOST_METRICS,
  MAHARASHTRA_DISTRICT_VECTORS 
} from '../../services/outbreakModel';

interface RiskIntelligenceCardProps {
  initialDistrict?: string;
  onOpenAlertModal?: (prefill: { district: string; disease: string; severity: string; text: string }) => void;
  onDistrictSelect?: (district: string) => void;
}

export const RiskIntelligenceCard: React.FC<RiskIntelligenceCardProps> = ({ 
  initialDistrict = "Pune",
  onOpenAlertModal,
  onDistrictSelect
}) => {
  const [selectedDistrict, setSelectedDistrict] = useState<string>(initialDistrict);
  const [prediction, setPrediction] = useState<DistrictRiskPrediction | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [vaccineAllocated, setVaccineAllocated] = useState<boolean>(false);
  const [allocationToast, setAllocationToast] = useState<string | null>(null);
  const [isTestModalOpen, setIsTestModalOpen] = useState<boolean>(false);

  useEffect(() => {
    loadPrediction(selectedDistrict);
  }, [selectedDistrict]);

  const loadPrediction = async (district: string) => {
    setLoading(true);
    setVaccineAllocated(false);
    const result = await predictDistrictOutbreakRisk(district);
    setPrediction(result);
    setLoading(false);
  };

  const handleDistrictChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const dist = e.target.value;
    setSelectedDistrict(dist);
    if (onDistrictSelect) {
      onDistrictSelect(dist);
    }
  };

  const handleAllocateVaccines = () => {
    if (!prediction) return;
    setVaccineAllocated(true);
    const trackingId = `DISP-${selectedDistrict.substring(0, 3).toUpperCase()}-2026-${Math.floor(1000 + Math.random() * 9000)}`;
    setAllocationToast(`✓ Requisition ${trackingId} logged: ${prediction.recommended_vaccine_stock.toLocaleString()} doses allocated to ${selectedDistrict} Veterinary Depot.`);
    setTimeout(() => setAllocationToast(null), 5000);
  };

  const handleDraftAdvisory = () => {
    if (!prediction) return;
    const advisoryText = `PREVENTATIVE ADVISORY: XGBoost Outbreak Risk Model detected ${Math.round(prediction.risk_probability * 100)}% transmission probability for ${prediction.dominant_disease} in ${selectedDistrict} District. Farmers across ${prediction.target_talukas.join(', ')} are advised to report nodular lesions and implement vector containment.`;
    
    if (onOpenAlertModal) {
      onOpenAlertModal({
        district: selectedDistrict,
        disease: prediction.dominant_disease,
        severity: prediction.outbreak_risk_level.toLowerCase(),
        text: advisoryText
      });
    } else {
      alert(`Advisory Drafted:\n\n${advisoryText}`);
    }
  };

  const getRiskColor = (level: string) => {
    switch (level) {
      case 'HIGH':
        return {
          bg: 'bg-red-50 text-red-900 border-red-300',
          badge: 'bg-[#C62828] text-white',
          text: 'text-[#C62828]',
          bar: 'bg-[#C62828]'
        };
      case 'MEDIUM':
        return {
          bg: 'bg-amber-50 text-amber-900 border-amber-300',
          badge: 'bg-[#F2994A] text-white',
          text: 'text-[#F2994A]',
          bar: 'bg-[#F2994A]'
        };
      default:
        return {
          bg: 'bg-green-50 text-green-900 border-green-300',
          badge: 'bg-[#94e130] text-black',
          text: 'text-green-700',
          bar: 'bg-[#94e130]'
        };
    }
  };

  if (!prediction) {
    return (
      <div className="vetra-card p-6 flex items-center justify-center text-sm text-zinc-500">
        Loading XGBoost Outbreak Model...
      </div>
    );
  }

  const colors = getRiskColor(prediction.outbreak_risk_level);

  return (
    <div className="vetra-card flex flex-col justify-between">
      <div>
        {/* Model Header */}
        <div className="flex items-center justify-between pb-3 border-b border-black/5">
          <div className="flex items-center gap-2">
            <div className="p-2 bg-red-100 rounded-lg">
              <ShieldAlert className="w-5 h-5 text-[#C62828]" />
            </div>
            <div>
              <div className="flex items-center gap-1.5">
                <h3 className="font-figtree font-bold text-sm text-ink">
                  XGBoost Outbreak Risk Model
                </h3>
                <span className="text-[10px] px-1.5 py-0.5 rounded bg-blue-100 text-blue-900 font-mono font-semibold">
                  v1.0 (300 Trees)
                </span>
              </div>
              <p className="text-[11px] text-ink-metadata font-inter">
                96.27% Acc • 94.74% Recall • 0.9914 ROC-AUC
              </p>
            </div>
          </div>
          <span className={`text-[11px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider ${colors.badge}`}>
            {prediction.outbreak_risk_level} ({Math.round(prediction.risk_probability * 100)}%)
          </span>
        </div>

        {/* District Selector & Real-Time Probability Gauge */}
        <div className="mt-4 p-3 rounded-lg bg-parchment/60 border border-black/5">
          <div className="flex items-center justify-between mb-2">
            <label className="text-[11px] font-bold uppercase tracking-wider text-ink-secondary">
              Surveillance District:
            </label>
            <div className="relative">
              <select
                value={selectedDistrict}
                onChange={handleDistrictChange}
                className="appearance-none bg-white border border-black/15 text-xs font-bold text-ink rounded-md py-1 pl-2.5 pr-7 focus:outline-none focus:ring-1 focus:ring-black"
              >
                {Object.keys(MAHARASHTRA_DISTRICT_VECTORS).map(d => (
                  <option key={d} value={d}>
                    {d} District
                  </option>
                ))}
              </select>
              <ChevronDown className="w-3.5 h-3.5 text-zinc-500 absolute right-2 top-2 pointer-events-none" />
            </div>
          </div>

          <div className="flex items-baseline justify-between mt-1">
            <div>
              <span className={`text-3xl font-extrabold font-figtree ${colors.text}`}>
                {Math.round(prediction.risk_probability * 100)}%
              </span>
              <span className="text-xs text-ink-secondary ml-1.5 font-inter">
                Outbreak Probability
              </span>
            </div>
            <div className="text-right">
              <span className="text-[11px] font-mono text-zinc-600 block">
                Confidence: <strong>{Math.round(prediction.confidence * 100)}%</strong>
              </span>
              <span className="text-[10px] text-zinc-400 font-mono">
                Latency: {prediction.inference_latency_ms}ms
              </span>
            </div>
          </div>

          {/* Progress Indicator */}
          <div className="w-full bg-black/10 rounded-full h-2 mt-2 overflow-hidden">
            <div 
              className={`h-2 rounded-full transition-all duration-500 ${colors.bar}`}
              style={{ width: `${prediction.risk_probability * 100}%` }}
            />
          </div>
        </div>

        {/* 4 Explainable AI Driving Pillars */}
        <div className="mt-4">
          <div className="flex items-center justify-between mb-2">
            <h4 className="text-xs font-bold uppercase text-ink-secondary font-figtree">
              Key Transmission Drivers (SHAP Gain)
            </h4>
            <span className="text-[10px] text-zinc-400 font-mono">4-Pillar Evaluation</span>
          </div>

          <div className="space-y-2 text-xs font-inter">
            {prediction.pillars.map((pillar, idx) => (
              <div key={idx} className="p-2 rounded-lg bg-white border border-black/5 hover:border-black/15 transition-all">
                <div className="flex items-center justify-between mb-1">
                  <span className="font-semibold text-ink flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#F2994A]" />
                    {pillar.title}
                  </span>
                  <span className="font-mono font-bold text-xs text-zinc-700">
                    +{pillar.contribution_pct}% Gain
                  </span>
                </div>
                <div className="flex items-center justify-between text-[11px] text-ink-metadata mt-0.5">
                  <span>{pillar.detail}</span>
                  <span className="font-mono font-semibold text-ink bg-parchment px-1.5 py-0.2 rounded text-[10px]">
                    {pillar.metric_value}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Recommended Action Workflows (Making the Model Genuinely Useful!) */}
        <div className="mt-4 pt-3 border-t border-black/5 space-y-2">
          <div className="flex items-center justify-between">
            <h4 className="text-xs font-bold uppercase text-ink-secondary font-figtree">
              Preventative Dispatch SOPs
            </h4>
            <span className="text-[10px] font-mono text-zinc-500">Ring Containment</span>
          </div>

          <div className="grid grid-cols-2 gap-2">
            {/* Button 1: Allocate Vaccine Stock */}
            <button
              onClick={handleAllocateVaccines}
              disabled={vaccineAllocated}
              className={`flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg text-xs font-bold transition-all border ${
                vaccineAllocated 
                  ? 'bg-green-100 text-green-900 border-green-300' 
                  : 'bg-white hover:bg-parchment text-ink border-black/15 shadow-sm'
              }`}
            >
              <Syringe className="w-3.5 h-3.5 text-[#C62828]" />
              {vaccineAllocated ? 'Vaccine Dispatched' : `Allocate Stock (${prediction.recommended_vaccine_stock.toLocaleString()})`}
            </button>

            {/* Button 2: Draft Preventative Advisory */}
            <button
              onClick={handleDraftAdvisory}
              className="flex items-center justify-center gap-1.5 px-3 py-2 rounded-lg text-xs font-bold bg-[#94e130] hover:bg-[#86cd2a] text-ink border border-black/15 shadow-sm transition-all"
            >
              <Send className="w-3.5 h-3.5 text-ink" />
              Draft Advisory
            </button>
          </div>

          {allocationToast && (
            <div className="p-2 rounded bg-green-50 border border-green-200 text-green-800 text-[11px] font-inter animate-fadeIn">
              {allocationToast}
            </div>
          )}
        </div>
      </div>

      {/* Mandatory Safety Notice and Telemetry */}
      <div className="mt-4 pt-3 border-t border-black/5">
        <p className="text-[10px] text-zinc-500 italic font-inter leading-tight">
          "{prediction.disclaimer}"
        </p>
        <div className="mt-2 flex items-center justify-between text-[10px] text-ink-metadata font-mono">
          <span className="flex items-center gap-1">
            <Cpu className="w-3 h-3 text-zinc-600" /> {prediction.source === 'fastapi_microservice' ? 'FastAPI :8001' : 'Embedded Engine'}
          </span>
          <span>Target: {prediction.target_talukas.slice(0, 2).join(', ')} buffer</span>
        </div>
      </div>
    </div>
  );
};
