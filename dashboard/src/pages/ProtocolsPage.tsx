import React, { useState } from 'react';
import {
  BookOpen,
  Book,
  ShieldAlert,
  AlertTriangle,
  Flame,
  Search,
  RotateCcw,
  RefreshCw,
  ArrowRight,
  X,
} from 'lucide-react';

interface ProtocolsPageProps {
  onNavigateToMapCluster: (disease: string) => void;
}

interface PathogenProtocol {
  id: string;
  name: string;
  subtitle: string;
  severity: 'critical' | 'high' | 'medium';
  isZoonotic: boolean;
  radius: string;
  clusterMin: string;
  window: string;
  species: string[];
  reportable: string;
  clusterStatus: {
    level: string;
    badgeColor: string;
  };
  details: {
    scientific: string;
    steps: string[];
  };
}

const pathogenProtocols: PathogenProtocol[] = [
  {
    id: 'fmd',
    name: 'Foot-and-Mouth Disease (FMD)',
    subtitle: 'Notifiable Pathogen (Disease Registry)',
    severity: 'high',
    isZoonotic: false,
    radius: '±25 km',
    clusterMin: '≥3 Cases',
    window: 'N/A',
    species: ['Cattle', 'Buffalo', 'Sheep', 'Goat', 'Pig'],
    reportable: 'Yes (Mandatory)',
    clusterStatus: {
      level: 'CRITICAL',
      badgeColor: 'text-[#C62828] bg-orange-50 border-orange-200',
    },
    details: {
      scientific: 'Aphthovirus (Picornaviridae) • Acute Vesicular Disease',
      steps: [
        'Establish 10km radius containment zone around infected village; prohibit livestock transit.',
        'Deploy bivalent/trivalent FMD vaccine to all cattle, buffalo, sheep and goats in a 25km ring.',
        'Disinfect barns and feed troughs with 4% sodium carbonate or 2% sodium hydroxide solution.',
        'Submit Form 1A notification to State Animal Disease Diagnostic Laboratory within 4 hours.',
      ],
    },
  },
  {
    id: 'lsd',
    name: 'Lumpy Skin Disease (LSD)',
    subtitle: 'Notifiable Pathogen (Disease Registry)',
    severity: 'high',
    isZoonotic: false,
    radius: '±25 km',
    clusterMin: '≥3 Cases',
    window: 'N/A',
    species: ['Cattle', 'Buffalo'],
    reportable: 'Yes (Mandatory)',
    clusterStatus: {
      level: 'HIGH',
      badgeColor: 'text-[#F2994A] bg-orange-50 border-orange-200',
    },
    details: {
      scientific: 'Capripoxvirus (Poxviridae) • Arthropod-Borne Disease',
      steps: [
        'Apply synthetic pyrethroids or 5% neem seed kernel extract spray across sheds to suppress biting flies.',
        'Administer homologous Goat Pox vaccine (Uttarkashi strain) at 10^3.5 TCID50 per animal.',
        'Treat infected cutaneous nodules with antiseptic zinc oxide and iodoform spray.',
        'Enforce 21-day quarantine prohibiting entry into local weekly animal markets.',
      ],
    },
  },
  {
    id: 'anthrax',
    name: 'Anthrax Suspicion',
    subtitle: 'Zoonotic Pathogen (Disease Registry)',
    severity: 'critical',
    isZoonotic: true,
    radius: '±25 km',
    clusterMin: '≥1 Case',
    window: 'N/A',
    species: ['Cattle', 'Buffalo', 'Sheep', 'Goat', 'Human'],
    reportable: 'Yes (Immediate)',
    clusterStatus: {
      level: 'CRITICAL',
      badgeColor: 'text-[#C62828] bg-red-50 border-red-200',
    },
    details: {
      scientific: 'Bacillus anthracis • Spore-Forming Zoonotic Bacterium',
      steps: [
        'STRICT BAN ON POST-MORTEM: Do NOT open the carcass. Oxygen contact causes rapid sporulation.',
        'Deep burial SOP: Minimum 6 feet deep, layered completely with quicklime (calcium oxide).',
        'Immediate emergency notification to District Health Officer (DHO) for human prophylactic ciprofloxacin.',
        'Attending veterinary team must wear full Level B PPE, heavy nitrile gloves, and N95 masks.',
      ],
    },
  },
  {
    id: 'ppr',
    name: 'Peste des Petits Ruminants (PPR)',
    subtitle: 'Notifiable Pathogen (Disease Registry)',
    severity: 'medium',
    isZoonotic: false,
    radius: '±15 km',
    clusterMin: '≥3 Cases',
    window: 'N/A',
    species: ['Sheep', 'Goat'],
    reportable: 'Yes (Mandatory)',
    clusterStatus: {
      level: 'MEDIUM',
      badgeColor: 'text-[#F2994A] bg-yellow-50 border-yellow-200',
    },
    details: {
      scientific: 'Small Ruminant Morbillivirus • High Mortality in Small Ruminants',
      steps: [
        'Immediately segregate coughing or diarrheic goats into separate shaded enclosures.',
        'Deploy live attenuated PPR vaccine (Sungri 96 strain) to all small ruminants within 15km perimeter.',
        'Administer intensive electrolyte rehydration and broad-spectrum antibiotics for secondary infection.',
        'Safe disposal of aborted fetuses and discharges with 2% sodium hypochlorite.',
      ],
    },
  },
];

export const ProtocolsPage: React.FC<ProtocolsPageProps> = ({
  onNavigateToMapCluster,
}) => {
  const [searchTerm, setSearchTerm] = useState('');
  const [zoonoticOnly, setZoonoticOnly] = useState(false);
  const [severityFilter, setSeverityFilter] = useState('all');
  const [zoonoticFilter, setZoonoticFilter] = useState('all');
  const [selectedProtocol, setSelectedProtocol] = useState<PathogenProtocol | null>(null);

  const filteredProtocols = pathogenProtocols.filter((p) => {
    const matchesSearch =
      searchTerm === '' ||
      p.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.species.some((s) => s.toLowerCase().includes(searchTerm.toLowerCase()));

    const matchesSeverity =
      severityFilter === 'all' || p.severity === severityFilter;

    const matchesZoonoticToggle = !zoonoticOnly || p.isZoonotic;

    const matchesZoonoticSelect =
      zoonoticFilter === 'all' ||
      (zoonoticFilter === 'zoonotic' && p.isZoonotic) ||
      (zoonoticFilter === 'animal-only' && !p.isZoonotic);

    return (
      matchesSearch &&
      matchesSeverity &&
      matchesZoonoticToggle &&
      matchesZoonoticSelect
    );
  });

  const handleResetFilters = () => {
    setSearchTerm('');
    setZoonoticOnly(false);
    setSeverityFilter('all');
    setZoonoticFilter('all');
  };

  return (
    <div className="space-y-4 font-figtree">
      {/* 1. Header & Sync Bar (From Reference Screenshot 2) */}
      <div className="bg-white p-4 rounded-xl border border-black/10 shadow-sm flex flex-wrap items-center justify-between gap-3">
        <div>
          <div className="flex items-center gap-2">
            <div className="p-1.5 rounded-lg bg-blue-50 text-vet-accent">
              <BookOpen className="w-5 h-5" />
            </div>
            <h2 className="text-lg font-bold text-ink">
              Veterinary Biosecurity Protocol Reference
            </h2>
          </div>
          <p className="text-xs text-ink-metadata font-inter mt-1">
            PASHUVANI Disease Registry catalog, pathogen surveillance parameters, and departmental protocol reference.
          </p>
        </div>

        <div className="flex items-center gap-3 text-xs font-inter">
          <span className="text-ink-metadata">
            <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block mr-1"></span>
            Scope: <strong>Maharashtra (Statewide)</strong> • Synced: <strong>14:28:41 IST</strong>
          </span>
          <button
            onClick={() => alert('Pathogen registry synchronized with DAHD Central Database.')}
            className="px-3 py-1.5 rounded-lg bg-parchment border border-black/10 font-semibold hover:bg-white flex items-center gap-1.5 text-ink-secondary"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span>Refresh Registry</span>
          </button>
        </div>
      </div>

      {/* 2. 4 Top Metric KPI Blocks (From Reference Screenshot 2) */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        {/* KPI 1 */}
        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-ink-metadata text-[11px] font-bold uppercase tracking-wider">
            <span>REGISTERED PATHOGENS</span>
            <Book className="w-4 h-4 text-vet-accent" />
          </div>
          <div className="text-2xl font-black text-ink mt-1 font-figtree">
            5 <span className="text-xs font-normal text-ink-metadata">Pathogen Profiles</span>
          </div>
          <div className="text-[10px] font-mono text-ink-metadata mt-1">
            Status: REFERENCE_CONTENT
          </div>
        </div>

        {/* KPI 2 */}
        <div className="vetra-card p-4 border-l-4 border-l-alert-critical">
          <div className="flex items-center justify-between text-ink-metadata text-[11px] font-bold uppercase tracking-wider">
            <span>NOTIFIABLE / REPORTABLE</span>
            <ShieldAlert className="w-4 h-4 text-alert-critical" />
          </div>
          <div className="text-2xl font-black text-alert-critical mt-1 font-figtree">
            5 of 5 <span className="text-xs font-normal text-ink-metadata">Pathogens</span>
          </div>
          <div className="text-[10px] font-mono text-ink-metadata mt-1">
            Recorded in Disease Registry
          </div>
        </div>

        {/* KPI 3 */}
        <div className="vetra-card p-4 border-l-4 border-l-caution-amber">
          <div className="flex items-center justify-between text-ink-metadata text-[11px] font-bold uppercase tracking-wider">
            <span>ZOONOTIC POTENTIAL</span>
            <AlertTriangle className="w-4 h-4 text-caution-amber" />
          </div>
          <div className="text-2xl font-black text-ink mt-1 font-figtree">
            2 <span className="text-xs font-normal text-ink-metadata">Human Transmission Risk</span>
          </div>
          <div className="text-[10px] font-mono text-ink-metadata mt-1">
            Recorded in Disease Registry
          </div>
        </div>

        {/* KPI 4 */}
        <div className="vetra-card p-4 border-l-4 border-l-brand-primary">
          <div className="flex items-center justify-between text-ink-metadata text-[11px] font-bold uppercase tracking-wider">
            <span>ACTIVE OUTBREAK CLUSTERS</span>
            <Flame className="w-4 h-4 text-emerald-600" />
          </div>
          <div className="text-2xl font-black text-ink mt-1 font-figtree">
            5 <span className="text-xs font-normal text-ink-metadata">Pathogens Active</span>
          </div>
          <div className="text-[10px] font-mono text-ink-metadata mt-1">
            Correlated from Surveillance Feed
          </div>
        </div>
      </div>

      {/* 3. Search & Filter Controls (From Reference Screenshot 2) */}
      <div className="bg-white p-3.5 rounded-xl border border-black/10 shadow-sm space-y-3 text-xs font-inter">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="relative flex-1 min-w-[280px]">
            <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-ink-metadata" />
            <input
              type="text"
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              placeholder="Search by Disease Name, Category, or Susceptible Species..."
              className="w-full pl-9 pr-3 py-2 rounded-lg border border-black/15 bg-parchment/60 focus:outline-none focus:border-brand-primary"
            />
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setZoonoticOnly(!zoonoticOnly)}
              className={`px-3.5 py-2 rounded-lg border font-semibold flex items-center gap-1.5 transition-all ${
                zoonoticOnly
                  ? 'bg-orange-100 border-orange-400 text-orange-950 font-bold'
                  : 'border-black/15 text-ink-secondary hover:bg-parchment'
              }`}
            >
              <AlertTriangle className="w-3.5 h-3.5 text-caution-amber" />
              <span>Filter: Zoonotic</span>
            </button>

            <button
              onClick={handleResetFilters}
              className="text-ink-metadata hover:text-ink flex items-center gap-1 px-2 py-1"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Reset</span>
            </button>
          </div>
        </div>

        {/* Filter Dropdowns Row */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 pt-2 border-t border-black/5 text-[11px]">
          <div>
            <span className="text-ink-metadata font-bold block mb-1">
              SEVERITY CLASSIFICATION:
            </span>
            <select
              value={severityFilter}
              onChange={(e) => setSeverityFilter(e.target.value)}
              className="w-full p-2 bg-parchment rounded-lg border border-black/10 font-semibold focus:outline-none"
            >
              <option value="all">All Severity Levels</option>
              <option value="critical">Critical</option>
              <option value="high">High Severity</option>
              <option value="medium">Medium</option>
            </select>
          </div>

          <div>
            <span className="text-ink-metadata font-bold block mb-1">
              ZOONOTIC STATUS:
            </span>
            <select
              value={zoonoticFilter}
              onChange={(e) => setZoonoticFilter(e.target.value)}
              className="w-full p-2 bg-parchment rounded-lg border border-black/10 font-semibold focus:outline-none"
            >
              <option value="all">All Transmission Modes</option>
              <option value="zoonotic">Zoonotic (Human Risk)</option>
              <option value="animal-only">Non-Zoonotic (Animal Only)</option>
            </select>
          </div>

          <div>
            <span className="text-ink-metadata font-bold block mb-1">
              STATUTORY MANDATE:
            </span>
            <select className="w-full p-2 bg-parchment rounded-lg border border-black/10 font-semibold focus:outline-none">
              <option>All Reporting Mandates</option>
              <option>Reportable: Yes (Mandatory)</option>
            </select>
          </div>
        </div>
      </div>

      {/* 4. Protocol Cards Grid (Directly matching Reference Screenshot 2) */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {filteredProtocols.map((p) => (
          <div
            key={p.id}
            className={`vetra-card p-4 flex flex-col justify-between ${
              p.isZoonotic ? 'border-2 border-red-200' : ''
            }`}
          >
            <div>
              <div className="flex items-center justify-between text-[10px] font-mono text-ink-metadata mb-2">
                <span>REFERENCE_CONTENT</span>
                <div className="flex items-center gap-1">
                  <span
                    className={`px-2 py-0.5 rounded font-bold uppercase ${
                      p.severity === 'critical'
                        ? 'bg-red-100 text-alert-critical'
                        : p.severity === 'high'
                        ? 'bg-orange-100 text-orange-900'
                        : 'bg-blue-100 text-blue-900'
                    }`}
                  >
                    {p.severity}
                  </span>
                  {p.isZoonotic && (
                    <span className="px-1.5 py-0.5 rounded bg-yellow-100 text-amber-900 font-bold">
                      ZOONOTIC
                    </span>
                  )}
                </div>
              </div>

              <h3 className="font-bold text-base text-ink font-figtree">
                {p.name}
              </h3>
              <p className="text-[11px] text-ink-metadata font-inter">
                {p.subtitle}
              </p>

              {/* Stats Box */}
              <div className="grid grid-cols-3 gap-2 my-3 p-2 bg-parchment/60 rounded-lg border border-black/5 text-[11px] font-inter text-center">
                <div>
                  <span className="text-ink-metadata block text-[9px]">Radius:</span>
                  <strong>{p.radius}</strong>
                </div>
                <div>
                  <span className="text-ink-metadata block text-[9px]">Cluster Min:</span>
                  <strong>{p.clusterMin}</strong>
                </div>
                <div>
                  <span className="text-ink-metadata block text-[9px]">Window:</span>
                  <strong>{p.window}</strong>
                </div>
              </div>

              <div className="text-xs font-inter space-y-1 text-ink-secondary">
                <div>
                  <span className="text-ink-metadata">Species: </span>
                  {p.species.join(', ')}
                </div>
                <div>
                  <span className="text-ink-metadata">Reportable: </span>
                  <strong>{p.reportable}</strong>
                </div>
              </div>
            </div>

            <div className="mt-4 space-y-2">
              <div
                onClick={() => onNavigateToMapCluster(p.id)}
                className={`p-2 rounded-lg border flex items-center justify-between text-xs cursor-pointer hover:opacity-90 transition-opacity ${p.clusterStatus.badgeColor}`}
              >
                <span className="font-bold text-[11px] flex items-center gap-1">
                  <AlertTriangle className="w-3.5 h-3.5" />
                  Active Cluster ({p.clusterStatus.level})
                </span>
                <span className="font-semibold text-[11px] hover:underline flex items-center gap-0.5 text-ink">
                  View Cluster <ArrowRight className="w-3 h-3" />
                </span>
              </div>

              <button
                onClick={() => setSelectedProtocol(p)}
                className="w-full py-2 bg-white border border-black/15 hover:bg-parchment rounded-lg text-xs font-bold text-ink-secondary hover:text-ink flex items-center justify-center gap-1 transition-colors"
              >
                <Book className="w-3.5 h-3.5" />
                <span>Open Protocol Reference &rarr;</span>
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Protocol Details Modal */}
      {selectedProtocol && (
        <div className="fixed inset-0 bg-black/65 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-2xl w-full p-6 shadow-2xl border border-black/15 font-figtree animate-fadeIn max-h-[90vh] flex flex-col justify-between">
            <div className="flex items-center justify-between pb-3 border-b border-black/10">
              <div className="flex items-center gap-2.5">
                <div className="p-2 bg-blue-50 rounded-lg text-vet-accent">
                  <BookOpen className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="font-bold text-lg text-ink">
                    {selectedProtocol.name} — SOP Directive
                  </h3>
                  <p className="text-xs text-ink-metadata font-inter">
                    {selectedProtocol.details.scientific}
                  </p>
                </div>
              </div>
              <button
                onClick={() => setSelectedProtocol(null)}
                className="p-1.5 text-ink-metadata hover:text-ink cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="my-4 overflow-y-auto space-y-3 font-inter text-xs text-ink-secondary pr-1">
              {selectedProtocol.details.steps.map((step, idx) => (
                <div
                  key={idx}
                  className="p-3 rounded-lg bg-parchment/60 border border-black/5 leading-relaxed"
                >
                  <span className="font-bold text-ink mr-1">
                    Step {idx + 1}:
                  </span>
                  {step}
                </div>
              ))}
            </div>

            <div className="pt-3 border-t border-black/10 flex justify-between items-center text-xs">
              <span className="text-ink-metadata">
                Statutory Authority: Prevention & Control of Infectious Diseases Act
              </span>
              <button
                onClick={() => setSelectedProtocol(null)}
                className="px-4 py-2 bg-ink text-white rounded-lg font-semibold hover:bg-black cursor-pointer"
              >
                Acknowledge & Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

