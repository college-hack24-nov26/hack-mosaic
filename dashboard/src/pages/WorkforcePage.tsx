// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { 
  Users, 
  UserPlus, 
  Download, 
  Search, 
  UserCheck, 
  Truck, 
  ClipboardCheck, 
  Clock, 
  ShieldAlert, 
  Layers, 
  X, 
  CheckCircle2,
  Send
} from 'lucide-react';

interface OfficerRecord {
  name: string;
  role: string;
  district: string;
  taluka: string;
  phone: string;
  target: string;
  status: string;
  statusClass?: string;
}

const DEFAULT_OFFICERS: OfficerRecord[] = [
  { name: "Dr. Anita Deshmukh", role: "Senior Veterinary Officer", district: "Pune", taluka: "Haveli Block", phone: "+91 98220 11442", target: "85 Animals/day", status: "Active on Patrol", statusClass: "chip-critical" },
  { name: "Dr. Sanjay Thorat", role: "Mobile Epidemic Squad Lead", district: "Pune", taluka: "Shirur Corridor", phone: "+91 98224 88319", target: "120 Animals/day", status: "In Transit to Buffer", statusClass: "chip-caution" },
  { name: "Dr. Prashant Vikhe", role: "District Epidemiologist", district: "Ahmednagar", taluka: "Shrirampur Dairy Belt", phone: "+91 94222 34109", target: "90 Animals/day", status: "Active on Patrol", statusClass: "chip-critical" },
  { name: "Dr. Rajesh Gaikwad", role: "Senior Veterinary Officer", district: "Satara", taluka: "Karad Block", phone: "+91 98500 77123", target: "75 Animals/day", status: "Quarantine Enforcement", statusClass: "chip-caution" },
  { name: "Smt. Rekha Chavan", role: "Paravet Vaccinator Lead", district: "Pune", taluka: "Khed Ring Buffer", phone: "+91 97631 44521", target: "150 Animals/day", status: "Active on Patrol", statusClass: "chip-resolved" },
  { name: "Dr. Milind Shinde", role: "Laboratory Pathologist", district: "Pune", taluka: "Central DADDL Lab", phone: "+91 98811 99042", target: "40 Samples/day", status: "Active on Patrol", statusClass: "chip-resolved" },
  { name: "Dr. Sunil Mane", role: "Mobile Epidemic Squad Lead", district: "Solapur", taluka: "Pandharpur Checkpost", phone: "+91 94233 11890", target: "110 Animals/day", status: "Active on Patrol", statusClass: "chip-resolved" }
];

export const WorkforcePage: React.FC = () => {
  const [roster, setRoster] = useState<OfficerRecord[]>(() => {
    try {
      const saved = localStorage.getItem('pashuvani_workforce_db');
      if (saved) return JSON.parse(saved);
    } catch {}
    return DEFAULT_OFFICERS;
  });

  const [districtFilter, setDistrictFilter] = useState<string>('all');
  const [roleFilter, setRoleFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form State
  const [formName, setFormName] = useState('');
  const [formRole, setFormRole] = useState('Senior Veterinary Officer');
  const [formPhone, setFormPhone] = useState('+91 98220 ');
  const [formDistrict, setFormDistrict] = useState('Pune');
  const [formTaluka, setFormTaluka] = useState('');
  const [formTarget, setFormTarget] = useState('90');
  const [formStatus, setFormStatus] = useState('Active on Patrol');

  useEffect(() => {
    try {
      localStorage.setItem('pashuvani_workforce_db', JSON.stringify(roster));
    } catch {}
  }, [roster]);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    const newOfficer: OfficerRecord = {
      name: formName.trim(),
      role: formRole,
      district: formDistrict,
      taluka: formTaluka.trim() || 'Central Taluka',
      phone: formPhone.trim(),
      target: `${formTarget} Animals/day`,
      status: formStatus,
      statusClass: formStatus === 'Active on Patrol' ? 'chip-critical' : 'chip-caution'
    };

    setRoster([newOfficer, ...roster]);
    setIsModalOpen(false);
    setToastMessage(`✓ Officer ${newOfficer.name} deployed to ${newOfficer.district} (${newOfficer.taluka}) field area.`);
    setTimeout(() => setToastMessage(null), 5000);

    // Reset Form
    setFormName('');
    setFormTaluka('');
  };

  const handleDispatch = (name: string, district: string) => {
    setToastMessage(`Mobile Alert Dispatched: ${name} assigned to rapid response unit in ${district} District.`);
    setTimeout(() => setToastMessage(null), 5000);
  };

  const filteredRoster = roster.filter(o => {
    const matchDist = districtFilter === 'all' || o.district.toLowerCase() === districtFilter.toLowerCase();
    const matchRole = roleFilter === 'all' || o.role.toLowerCase() === roleFilter.toLowerCase();
    const matchQ = !searchQuery || 
      o.name.toLowerCase().includes(searchQuery.toLowerCase()) || 
      o.taluka.toLowerCase().includes(searchQuery.toLowerCase()) || 
      o.role.toLowerCase().includes(searchQuery.toLowerCase());
    return matchDist && matchRole && matchQ;
  });

  const exportCSV = () => {
    let csv = "Officer_Name,Designation,District,Taluka,Phone,Daily_Target,Status\n";
    roster.forEach(o => {
      csv += `"${o.name}","${o.role}","${o.district}","${o.taluka}","${o.phone}","${o.target}","${o.status}"\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.setAttribute("download", "pashuvani_workforce_roster.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-4">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="p-3 bg-blue-50 border border-blue-300 text-blue-900 rounded-lg text-xs font-inter flex items-center gap-2 animate-fadeIn">
          <CheckCircle2 className="w-4 h-4 text-blue-700" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header & Controls */}
      <div className="bg-white p-4 rounded-xl border border-black/10 shadow-sm space-y-3 font-figtree">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <div className="p-1.5 rounded-lg bg-blue-100 text-blue-800">
                <Users className="w-5 h-5 text-[#2F6FDE]" />
              </div>
              <h2 className="text-lg font-bold text-[#141414]">
                Statewide Veterinary Field Workforce & Mobile Squads
              </h2>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-50 text-blue-800 border border-blue-200 font-semibold">
                Field Operations Command
              </span>
            </div>
            <p className="text-xs text-zinc-500 font-inter mt-1">
              Area-wise veterinary doctor assignments • Mobile clinical units • Real-time taluka inspection velocity
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-3 py-2 rounded-lg bg-[#2F6FDE] hover:bg-[#255bb5] text-white font-bold text-xs shadow-sm flex items-center gap-1.5 cursor-pointer transition-all"
            >
              <UserPlus className="w-4 h-4" /> Deploy / Register Officer
            </button>
            <button
              onClick={exportCSV}
              className="px-3 py-2 rounded-lg bg-white border border-black/15 hover:bg-parchment text-xs font-semibold flex items-center gap-1.5 cursor-pointer"
            >
              <Download className="w-4 h-4 text-zinc-600" /> Export Roster CSV
            </button>
          </div>
        </div>

        {/* Filters Row */}
        <div className="pt-3 border-t border-black/5 flex flex-wrap items-center justify-between gap-3 text-xs font-inter">
          <div className="flex flex-wrap items-center gap-2">
            <label className="font-semibold text-zinc-700">Filter Area:</label>
            <select
              value={districtFilter}
              onChange={(e) => setDistrictFilter(e.target.value)}
              className="px-2.5 py-1.5 rounded-lg border border-black/15 bg-parchment font-bold text-xs focus:outline-none"
            >
              <option value="all">All Maharashtra Districts</option>
              <option value="Pune">Pune District</option>
              <option value="Ahmednagar">Ahmednagar District</option>
              <option value="Satara">Satara District</option>
              <option value="Solapur">Solapur District</option>
              <option value="Kolhapur">Kolhapur District</option>
              <option value="Nashik">Nashik District</option>
            </select>

            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="px-2.5 py-1.5 rounded-lg border border-black/15 bg-white text-xs"
            >
              <option value="all">All Designations</option>
              <option value="Senior Veterinary Officer">Senior Veterinary Officer</option>
              <option value="Mobile Epidemic Squad Lead">Mobile Epidemic Squad Lead</option>
              <option value="District Epidemiologist">District Epidemiologist</option>
              <option value="Paravet Vaccinator Lead">Paravet Vaccinator Lead</option>
              <option value="Laboratory Pathologist">Laboratory Pathologist</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-zinc-400 absolute left-2.5 top-2.5" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search Officer or Taluka..."
                className="pl-8 pr-3 py-1.5 rounded-lg border border-black/15 bg-white text-xs w-56 focus:outline-none focus:border-[#2F6FDE]"
              />
            </div>
            <span className="text-[11px] font-mono text-zinc-500 bg-parchment px-2 py-1 rounded">
              {filteredRoster.length} Officers
            </span>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Active Field Personnel</span>
            <UserCheck className="w-4 h-4 text-blue-600" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-ink">
              {48 + roster.length - DEFAULT_OFFICERS.length} Officers
            </span>
            <span className="text-[11px] font-semibold text-blue-700 bg-blue-100 px-1.5 py-0.5 rounded">100% Deployed</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">Veterinarians & paravet staff</p>
        </div>

        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Mobile Response Vans</span>
            <Truck className="w-4 h-4 text-[#16a34a]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-[#16a34a]">12 Mobile Units</span>
            <span className="text-[11px] font-semibold text-green-800 bg-green-100 px-1.5 py-0.5 rounded">Equipped</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">Equipped with portable cold chain</p>
        </div>

        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Weekly Taluka Audits</span>
            <ClipboardCheck className="w-4 h-4 text-amber-600" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-amber-700">184 / 210</span>
            <span className="text-[11px] font-semibold text-amber-800 bg-amber-100 px-1.5 py-0.5 rounded">87.6% Velocity</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">On schedule across active blocks</p>
        </div>

        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Hotspot Response SLA</span>
            <Clock className="w-4 h-4 text-[#C62828]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-[#C62828]">2.8 Hours</span>
            <span className="text-[11px] font-semibold text-green-800 bg-green-100 px-1.5 py-0.5 rounded">&lt; 4hr Target</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">Average clinical squad dispatch</p>
        </div>
      </div>

      {/* Visual Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Chart 1: Staffing vs Outbreak Threat Score */}
        <div className="vetra-card lg:col-span-2 p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-black/5 mb-3">
              <div className="flex items-center gap-2">
                <ShieldAlert className="w-4 h-4 text-[#C62828]" />
                <h3 className="font-bold text-sm text-ink font-figtree">Workforce Density vs Disease Threat Score</h3>
              </div>
              <span className="text-[11px] text-ink-metadata font-mono">Resource Balance</span>
            </div>

            <div className="space-y-3 font-inter text-xs">
              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Pune District (14 Officers • 4 Mobile Units)</span>
                  <span className="font-mono font-bold text-[#C62828]">Threat: 87% (HIGH)</span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#C62828] h-2.5 rounded-full" style={{ width: '87%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Ahmednagar District (11 Officers • 3 Mobile Units)</span>
                  <span className="font-mono font-bold text-[#F2994A]">Threat: 82% (HIGH)</span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#F2994A] h-2.5 rounded-full" style={{ width: '82%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Satara District (8 Officers • 2 Mobile Units)</span>
                  <span className="font-mono font-bold text-[#F2994A]">Threat: 79% (HIGH)</span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#F2994A] h-2.5 rounded-full" style={{ width: '79%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Solapur District (6 Officers • 1 Mobile Unit)</span>
                  <span className="font-mono font-bold text-amber-700">Threat: 64% (MEDIUM)</span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-amber-500 h-2.5 rounded-full" style={{ width: '64%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Kolhapur District (5 Officers • 1 Mobile Unit)</span>
                  <span className="font-mono font-bold text-[#16a34a]">Threat: 31% (LOW)</span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#16a34a] h-2.5 rounded-full" style={{ width: '31%' }} />
                </div>
              </div>
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-black/5 flex justify-between text-[11px] text-ink-metadata font-mono">
            <span>Dynamic Rebalancing via XGBoost Risk Horizon</span>
            <span>GPS Tracking Active</span>
          </div>
        </div>

        {/* Chart 2: Specialization Breakdown */}
        <div className="vetra-card p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-black/5 mb-3">
              <div className="flex items-center gap-2">
                <Layers className="w-4 h-4 text-zinc-600" />
                <h3 className="font-bold text-sm text-ink font-figtree">Specialization Breakdown</h3>
              </div>
              <span className="chip-active text-[9px]">48 Roster</span>
            </div>

            <div className="space-y-2 text-xs font-inter">
              <div className="p-2 rounded-lg bg-blue-50 border border-blue-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-blue-950 block">Veterinary Surgeons</span>
                  <span className="text-[10px] text-blue-700">Diagnosis & Clinical Swabs</span>
                </div>
                <span className="font-mono font-bold text-blue-900">20 (42%)</span>
              </div>

              <div className="p-2 rounded-lg bg-green-50 border border-green-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-green-950 block">Paravet Vaccinators</span>
                  <span className="text-[10px] text-green-700">Ring Inoculation Squads</span>
                </div>
                <span className="font-mono font-bold text-green-900">15 (31%)</span>
              </div>

              <div className="p-2 rounded-lg bg-purple-50 border border-purple-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-purple-950 block">Field Epidemiologists</span>
                  <span className="text-[10px] text-purple-700">Spatial GIS & Contact Tracing</span>
                </div>
                <span className="font-mono font-bold text-purple-900">7 (15%)</span>
              </div>

              <div className="p-2 rounded-lg bg-amber-50 border border-amber-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-amber-950 block">Diagnostic Pathologists</span>
                  <span className="text-[10px] text-amber-700">DADDL Swab & Blood Tests</span>
                </div>
                <span className="font-mono font-bold text-amber-900">6 (12%)</span>
              </div>
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-black/5 text-[11px] text-zinc-500 font-mono text-center">
            State Veterinary Council Accredited
          </div>
        </div>
      </div>

      {/* Persistent Area Table */}
      <div className="vetra-card overflow-hidden">
        <div className="p-4 border-b border-black/5 flex flex-wrap items-center justify-between gap-3 bg-parchment/40">
          <div>
            <h3 className="font-bold text-base text-ink font-figtree">Area-Wise Field Deployment Roster</h3>
            <p className="text-xs text-ink-metadata font-inter">Live persistent database of government veterinary officers and real-time duty status</p>
          </div>
          <div className="text-xs font-mono text-zinc-600">
            Direct Emergency Dispatch
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs font-inter border-collapse">
            <thead className="bg-parchment/80 text-ink-secondary uppercase text-[10px] tracking-wider border-b border-black/10">
              <tr>
                <th className="py-3 px-4 font-bold">Officer Name</th>
                <th className="py-3 px-4 font-bold">Designation</th>
                <th className="py-3 px-4 font-bold">Assigned District & Taluka</th>
                <th className="py-3 px-4 font-bold">Contact Phone</th>
                <th className="py-3 px-4 font-bold">Daily Animal Quota</th>
                <th className="py-3 px-4 font-bold text-center">Duty Status</th>
                <th className="py-3 px-4 font-bold text-right">Quick Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/5">
              {filteredRoster.map((o, idx) => (
                <tr key={idx} className="hover:bg-parchment/40 transition-colors">
                  <td className="py-3 px-4 font-bold text-ink flex items-center gap-2">
                    <div className="w-7 h-7 rounded-full bg-blue-100 text-blue-900 font-bold flex items-center justify-center text-[10px] font-mono">
                      {o.name.split(' ').map(n=>n[0]).join('')}
                    </div>
                    <span>{o.name}</span>
                  </td>
                  <td className="py-3 px-4 text-zinc-700 font-medium">{o.role}</td>
                  <td className="py-3 px-4 font-medium text-zinc-600">
                    {o.district} <span className="text-zinc-400 font-mono">({o.taluka})</span>
                  </td>
                  <td className="py-3 px-4 font-mono text-zinc-600">{o.phone}</td>
                  <td className="py-3 px-4 font-mono text-[11px] text-zinc-700">{o.target}</td>
                  <td className="py-3 px-4 text-center">
                    <span className={`${o.statusClass || 'chip-resolved'} text-[10px]`}>{o.status}</span>
                  </td>
                  <td className="py-3 px-4 text-right">
                    <button
                      onClick={() => handleDispatch(o.name, o.district)}
                      className="px-2.5 py-1 bg-white border border-black/15 hover:bg-[#94e130] hover:text-black rounded text-[11px] font-bold cursor-pointer transition-all"
                    >
                      Dispatch
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: Deploy Officer */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-lg w-full p-6 shadow-2xl border border-black/15 font-figtree animate-fadeIn">
            <div className="flex items-center justify-between pb-3 border-b border-black/10">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-blue-100 rounded-lg">
                  <UserPlus className="w-5 h-5 text-[#2F6FDE]" />
                </div>
                <div>
                  <h3 className="font-bold text-lg text-ink">Deploy / Register Field Officer</h3>
                  <p className="text-xs text-ink-metadata font-inter">Assign veterinarian or paravet staff to target taluka</p>
                </div>
              </div>
              <button onClick={() => setIsModalOpen(false)} className="p-1 text-ink-metadata hover:text-ink cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSave} className="mt-4 space-y-3 text-xs font-inter">
              <div>
                <label className="block font-semibold text-ink mb-1">Officer Full Name *</label>
                <input
                  type="text"
                  required
                  value={formName}
                  onChange={(e) => setFormName(e.target.value)}
                  placeholder="e.g. Dr. Ramesh Gaikwad"
                  className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none focus:border-[#2F6FDE]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">Designation / Role *</label>
                  <select
                    value={formRole}
                    onChange={(e) => setFormRole(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none"
                  >
                    <option value="Senior Veterinary Officer">Senior Veterinary Officer</option>
                    <option value="Mobile Epidemic Squad Lead">Mobile Epidemic Squad Lead</option>
                    <option value="District Epidemiologist">District Epidemiologist</option>
                    <option value="Paravet Vaccinator Lead">Paravet Vaccinator Lead</option>
                    <option value="Laboratory Pathologist">Laboratory Pathologist</option>
                  </select>
                </div>
                <div>
                  <label className="block font-semibold text-ink mb-1">Contact Phone *</label>
                  <input
                    type="text"
                    required
                    value={formPhone}
                    onChange={(e) => setFormPhone(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-mono focus:outline-none"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">Assigned District *</label>
                  <select
                    value={formDistrict}
                    onChange={(e) => setFormDistrict(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-bold focus:outline-none"
                  >
                    <option value="Pune">Pune</option>
                    <option value="Ahmednagar">Ahmednagar</option>
                    <option value="Satara">Satara</option>
                    <option value="Solapur">Solapur</option>
                    <option value="Kolhapur">Kolhapur</option>
                    <option value="Nashik">Nashik</option>
                  </select>
                </div>
                <div>
                  <label className="block font-semibold text-ink mb-1">Assigned Taluka / Block *</label>
                  <input
                    type="text"
                    required
                    value={formTaluka}
                    onChange={(e) => setFormTaluka(e.target.value)}
                    placeholder="e.g. Haveli Block"
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none focus:border-[#2F6FDE]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">Daily Animal Target</label>
                  <input
                    type="number"
                    required
                    value={formTarget}
                    onChange={(e) => setFormTarget(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-mono focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-ink mb-1">Duty Status *</label>
                  <select
                    value={formStatus}
                    onChange={(e) => setFormStatus(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-semibold text-[#16a34a] focus:outline-none"
                  >
                    <option value="Active on Patrol">Active on Patrol</option>
                    <option value="Assigned to Hotspot">Assigned to Hotspot Cluster</option>
                    <option value="In Transit to Buffer">In Transit to Buffer</option>
                    <option value="Quarantine Enforcement">Quarantine Enforcement</option>
                  </select>
                </div>
              </div>

              <div className="pt-3 border-t border-black/10 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setIsModalOpen(false)}
                  className="px-4 py-2 font-semibold text-ink-secondary hover:text-ink cursor-pointer"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 bg-[#2F6FDE] hover:bg-[#255bb5] text-white font-bold rounded-lg cursor-pointer"
                >
                  Deploy to Field
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

