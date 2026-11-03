// @ts-nocheck
import React, { useState, useEffect } from 'react';
import { 
  Syringe, 
  PlusCircle, 
  Download, 
  Search, 
  ShieldCheck, 
  Disc, 
  ThermometerSnowflake, 
  MapPin, 
  BarChart3, 
  PieChart, 
  X, 
  CheckCircle2 
} from 'lucide-react';

interface VaccinationRecord {
  id: string;
  species: string;
  farmer: string;
  district: string;
  taluka: string;
  vaccine: string;
  batch: string;
  temp: string;
  date: string;
  status: string;
  officer: string;
}

const DEFAULT_RECORDS: VaccinationRecord[] = [
  { id: "MH-PUN-08412", species: "Gir Cow", farmer: "Ramesh Jadhav", district: "Pune", taluka: "Haveli (Wagholi)", vaccine: "Goat Pox (LSD)", batch: "LSD-2026-99A", temp: "4.1°C", date: "Nov 3, 2026", status: "Completed", officer: "Dr. Anita Deshmukh" },
  { id: "MH-PUN-09124", species: "Murrah Buffalo", farmer: "Balasaheb Shinde", district: "Pune", taluka: "Shirur", vaccine: "FMD Trivalent", batch: "FMD-881B", temp: "3.8°C", date: "Nov 3, 2026", status: "Completed", officer: "Dr. Sanjay Thorat" },
  { id: "MH-AHM-04721", species: "Crossbred Holstein", farmer: "Eknath Vikhe", district: "Ahmednagar", taluka: "Rahata", vaccine: "Goat Pox (LSD)", batch: "LSD-2026-99A", temp: "4.4°C", date: "Nov 2, 2026", status: "Completed", officer: "Dr. Prashant Vikhe" },
  { id: "MH-SAT-02198", species: "Khillari Bull", farmer: "Anandrao Patil", district: "Satara", taluka: "Karad", vaccine: "Anthrax Spore", batch: "ANT-012X", temp: "4.0°C", date: "Nov 2, 2026", status: "Completed", officer: "Dr. Rajesh Gaikwad" },
  { id: "MH-SOL-06833", species: "Osmanabadi Goat", farmer: "Suresh Mali", district: "Solapur", taluka: "Pandharpur", vaccine: "PPR Sungri-96", batch: "PPR-554M", temp: "4.6°C", date: "Nov 1, 2026", status: "Completed", officer: "Dr. Sunil Mane" },
  { id: "MH-KOL-05112", species: "Pandharpuri Buffalo", farmer: "Santosh Kadam", district: "Kolhapur", taluka: "Karveer", vaccine: "FMD Trivalent", batch: "FMD-881B", temp: "3.9°C", date: "Nov 1, 2026", status: "Completed", officer: "Dr. Suresh Patil" },
  { id: "MH-NAS-07341", species: "Dangi Cow", farmer: "Vitthal Gite", district: "Nashik", taluka: "Sinnar", vaccine: "Goat Pox (LSD)", batch: "LSD-2026-99A", temp: "4.2°C", date: "Oct 31, 2026", status: "Completed", officer: "Dr. Nitin Aher" }
];

export const VaccinationPage: React.FC = () => {
  const [records, setRecords] = useState<VaccinationRecord[]>(() => {
    try {
      const saved = localStorage.getItem('pashuvani_vaccinations_db');
      if (saved) return JSON.parse(saved);
    } catch {}
    return DEFAULT_RECORDS;
  });

  const [districtFilter, setDistrictFilter] = useState<string>('all');
  const [vaccineFilter, setVaccineFilter] = useState<string>('all');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [isModalOpen, setIsModalOpen] = useState<boolean>(false);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Form State
  const [formTag, setFormTag] = useState('');
  const [formSpecies, setFormSpecies] = useState('Gir Cow');
  const [formFarmer, setFormFarmer] = useState('');
  const [formVaccine, setFormVaccine] = useState('Goat Pox (LSD)');
  const [formDistrict, setFormDistrict] = useState('Pune');
  const [formTaluka, setFormTaluka] = useState('');
  const [formBatch, setFormBatch] = useState('LSD-2026-99B');
  const [formTemp, setFormTemp] = useState('4.2');
  const [formOfficer, setFormOfficer] = useState('Dr. Anita Deshmukh (Haveli Unit)');

  useEffect(() => {
    try {
      localStorage.setItem('pashuvani_vaccinations_db', JSON.stringify(records));
    } catch {}
  }, [records]);

  const handleSave = (e: React.FormEvent) => {
    e.preventDefault();
    const newRec: VaccinationRecord = {
      id: formTag.trim(),
      species: formSpecies,
      farmer: formFarmer.trim(),
      district: formDistrict,
      taluka: formTaluka.trim() || 'Central Taluka',
      vaccine: formVaccine,
      batch: formBatch.trim(),
      temp: `${formTemp}°C`,
      date: 'Today, Just Now',
      status: 'Completed',
      officer: formOfficer.trim()
    };

    setRecords([newRec, ...records]);
    setIsModalOpen(false);
    setToastMessage(`✓ Vaccination record for ${newRec.id} (${newRec.species}) saved to ${newRec.district} (${newRec.taluka}) area registry.`);
    setTimeout(() => setToastMessage(null), 5000);

    // Reset Form
    setFormTag('');
    setFormFarmer('');
    setFormTaluka('');
  };

  const filteredRecords = records.filter(r => {
    const matchDist = districtFilter === 'all' || r.district.toLowerCase() === districtFilter.toLowerCase();
    const matchVax = vaccineFilter === 'all' || r.vaccine.toLowerCase().includes(vaccineFilter.toLowerCase());
    const matchQ = !searchQuery || 
      r.id.toLowerCase().includes(searchQuery.toLowerCase()) || 
      r.farmer.toLowerCase().includes(searchQuery.toLowerCase()) || 
      r.taluka.toLowerCase().includes(searchQuery.toLowerCase());
    return matchDist && matchVax && matchQ;
  });

  const exportCSV = () => {
    let csv = "Animal_Tag_ID,Species,Farmer_Name,District,Taluka,Vaccine,Batch,Cold_Chain_Temp,Date,Status,Administering_Officer\n";
    records.forEach(r => {
      csv += `"${r.id}","${r.species}","${r.farmer}","${r.district}","${r.taluka}","${r.vaccine}","${r.batch}","${r.temp}","${r.date}","${r.status}","${r.officer}"\n`;
    });
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const link = document.createElement("a");
    link.href = URL.createObjectURL(blob);
    link.setAttribute("download", "pashuvani_area_vaccinations_registry.csv");
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  };

  return (
    <div className="space-y-4">
      {/* Toast Notification */}
      {toastMessage && (
        <div className="p-3 bg-green-50 border border-green-300 text-green-900 rounded-lg text-xs font-inter flex items-center gap-2 animate-fadeIn">
          <CheckCircle2 className="w-4 h-4 text-green-700" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Header & Controls */}
      <div className="bg-white p-4 rounded-xl border border-black/10 shadow-sm space-y-3 font-figtree">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <div className="flex items-center gap-2">
              <div className="p-1.5 rounded-lg bg-green-100 text-green-800">
                <Syringe className="w-5 h-5 text-[#16a34a]" />
              </div>
              <h2 className="text-lg font-bold text-[#141414]">
                Area-Wise Livestock Vaccination & Cold Chain Registry
              </h2>
              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-green-50 text-green-800 border border-green-200 font-semibold">
                Ring Buffer & Routine Tracking
              </span>
            </div>
            <p className="text-xs text-zinc-500 font-inter mt-1">
              Area-wise animal immunization logs • 2°C–8°C Cold chain telemetry • High-risk ring perimeter quota management
            </p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <button
              onClick={() => setIsModalOpen(true)}
              className="px-3 py-2 rounded-lg bg-[#94e130] hover:bg-[#86cd2a] text-[#141414] font-bold text-xs shadow-sm flex items-center gap-1.5 cursor-pointer transition-all"
            >
              <PlusCircle className="w-4 h-4" /> Log Animal Vaccination
            </button>
            <button
              onClick={exportCSV}
              className="px-3 py-2 rounded-lg bg-white border border-black/15 hover:bg-parchment text-xs font-semibold flex items-center gap-1.5 cursor-pointer"
            >
              <Download className="w-4 h-4 text-zinc-600" /> Export Area CSV
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
              <option value="Pune">Pune District (Haveli/Shirur)</option>
              <option value="Ahmednagar">Ahmednagar District (Shrirampur)</option>
              <option value="Satara">Satara District (Karad/Phaltan)</option>
              <option value="Solapur">Solapur District (Pandharpur)</option>
              <option value="Kolhapur">Kolhapur District (Karveer)</option>
              <option value="Nashik">Nashik District (Niphad/Sinnar)</option>
              <option value="Sangli">Sangli District (Miraj)</option>
            </select>

            <select
              value={vaccineFilter}
              onChange={(e) => setVaccineFilter(e.target.value)}
              className="px-2.5 py-1.5 rounded-lg border border-black/15 bg-white text-xs"
            >
              <option value="all">All Vaccines</option>
              <option value="Goat Pox (LSD)">Goat Pox (LSD Live)</option>
              <option value="FMD Trivalent">FMD Trivalent</option>
              <option value="Anthrax Spore">Anthrax Spore Vaccine</option>
              <option value="PPR Sungri-96">PPR Small Ruminants</option>
            </select>
          </div>

          <div className="flex items-center gap-2">
            <div className="relative">
              <Search className="w-3.5 h-3.5 text-zinc-400 absolute left-2.5 top-2.5" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Search Tag ID or Farmer..."
                className="pl-8 pr-3 py-1.5 rounded-lg border border-black/15 bg-white text-xs w-56 focus:outline-none focus:border-[#94e130]"
              />
            </div>
            <span className="text-[11px] font-mono text-zinc-500 bg-parchment px-2 py-1 rounded">
              {filteredRecords.length} Records
            </span>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Total Inoculations</span>
            <ShieldCheck className="w-4 h-4 text-[#16a34a]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-ink">
              {(42850 + records.length - DEFAULT_RECORDS.length).toLocaleString()}
            </span>
            <span className="text-[11px] font-semibold text-[#16a34a] bg-green-100 px-1.5 py-0.5 rounded">+12.4% this week</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">Cattle, buffalo & small ruminants</p>
        </div>

        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Ring Buffer Target</span>
            <Disc className="w-4 h-4 text-[#C62828]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-[#C62828]">87.4%</span>
            <span className="text-[11px] font-semibold text-zinc-700 bg-parchment px-1.5 py-0.5 rounded">Target: 90%</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">10km perimeter containment quota</p>
        </div>

        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Cold Chain Integrity</span>
            <ThermometerSnowflake className="w-4 h-4 text-blue-600" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-blue-700">4.1°C Avg</span>
            <span className="text-[11px] font-semibold text-blue-700 bg-blue-100 px-1.5 py-0.5 rounded">99.2% Compliant</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">WHO spec: 2.0°C to 8.0°C active</p>
        </div>

        <div className="vetra-card p-4">
          <div className="flex items-center justify-between text-xs text-ink-metadata font-inter">
            <span className="font-bold uppercase tracking-wider">Active Ring Zones</span>
            <MapPin className="w-4 h-4 text-[#F2994A]" />
          </div>
          <div className="mt-2 flex items-baseline justify-between font-figtree">
            <span className="text-2xl font-extrabold text-ink">14 Talukas</span>
            <span className="text-[11px] font-semibold text-amber-800 bg-amber-100 px-1.5 py-0.5 rounded">High Priority</span>
          </div>
          <p className="text-[11px] text-zinc-500 font-inter mt-1">Haveli, Shirur, Karad, Shrirampur</p>
        </div>
      </div>

      {/* Visual Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4">
        {/* Chart 1: Area Coverage Bars */}
        <div className="vetra-card lg:col-span-2 p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-black/5 mb-3">
              <div className="flex items-center gap-2">
                <BarChart3 className="w-4 h-4 text-zinc-600" />
                <h3 className="font-bold text-sm text-ink font-figtree">Area-Wise Vaccination Quota vs Administered</h3>
              </div>
              <span className="text-[11px] text-ink-metadata font-mono">Real-Time Sync</span>
            </div>

            <div className="space-y-3 font-inter text-xs">
              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Pune District (Haveli & Shirur Hotspots)</span>
                  <span className="font-mono font-bold text-zinc-700">18,400 / 21,000 doses <strong className="text-[#C62828] ml-1">(87.6%)</strong></span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#C62828] h-2.5 rounded-full" style={{ width: '87.6%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Ahmednagar District (Shrirampur Dairy Belt)</span>
                  <span className="font-mono font-bold text-zinc-700">12,800 / 15,500 doses <strong className="text-[#F2994A] ml-1">(82.5%)</strong></span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#F2994A] h-2.5 rounded-full" style={{ width: '82.5%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Satara District (Karad Pastoral Corridor)</span>
                  <span className="font-mono font-bold text-zinc-700">9,400 / 11,200 doses <strong className="text-[#16a34a] ml-1">(83.9%)</strong></span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#16a34a] h-2.5 rounded-full" style={{ width: '83.9%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Kolhapur District (Karveer High-Coverage Zone)</span>
                  <span className="font-mono font-bold text-zinc-700">11,200 / 12,000 doses <strong className="text-[#16a34a] ml-1">(93.3%)</strong></span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-[#94e130] h-2.5 rounded-full" style={{ width: '93.3%' }} />
                </div>
              </div>

              <div>
                <div className="flex justify-between items-center mb-1">
                  <span className="font-semibold text-ink">Solapur District (Pandharpur Border Checkpost)</span>
                  <span className="font-mono font-bold text-zinc-700">7,650 / 10,000 doses <strong className="text-zinc-600 ml-1">(76.5%)</strong></span>
                </div>
                <div className="w-full bg-black/10 rounded-full h-2.5 overflow-hidden">
                  <div className="bg-zinc-500 h-2.5 rounded-full" style={{ width: '76.5%' }} />
                </div>
              </div>
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-black/5 flex justify-between text-[11px] text-ink-metadata font-mono">
            <span>Vaccine Stock Reserve: 28,500 Vials in Central Depot</span>
            <span>Ring Execution SOP v2.4</span>
          </div>
        </div>

        {/* Chart 2: Vaccine Breakdown */}
        <div className="vetra-card p-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-black/5 mb-3">
              <div className="flex items-center gap-2">
                <PieChart className="w-4 h-4 text-zinc-600" />
                <h3 className="font-bold text-sm text-ink font-figtree">Vaccine Distribution Mix</h3>
              </div>
              <span className="chip-active text-[9px]">4 Pathologies</span>
            </div>

            <div className="space-y-2 text-xs font-inter">
              <div className="p-2 rounded-lg bg-red-50 border border-red-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-red-950 block">Goat Pox / LSD Live</span>
                  <span className="text-[10px] text-red-700">Heterologous Capripox</span>
                </div>
                <div className="text-right">
                  <span className="font-mono font-bold text-red-900 block">19,700 (46%)</span>
                  <span className="text-[9px] text-red-600">Buffer Priority</span>
                </div>
              </div>

              <div className="p-2 rounded-lg bg-orange-50 border border-orange-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-orange-950 block">FMD Trivalent Inactivated</span>
                  <span className="text-[10px] text-orange-700">O, A, Asia-1 Strains</span>
                </div>
                <div className="text-right">
                  <span className="font-mono font-bold text-orange-900 block">13,700 (32%)</span>
                  <span className="text-[9px] text-orange-600">Bovine Ring</span>
                </div>
              </div>

              <div className="p-2 rounded-lg bg-blue-50 border border-blue-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-blue-950 block">Anthrax Spore Vaccine</span>
                  <span className="text-[10px] text-blue-700">Sterne 34F2 Strain</span>
                </div>
                <div className="text-right">
                  <span className="font-mono font-bold text-blue-900 block">5,570 (13%)</span>
                  <span className="text-[9px] text-blue-600">Endemic Zones</span>
                </div>
              </div>

              <div className="p-2 rounded-lg bg-purple-50 border border-purple-200 flex justify-between items-center">
                <div>
                  <span className="font-bold text-purple-950 block">PPR Small Ruminants</span>
                  <span className="text-[10px] text-purple-700">Sungri 96 Live</span>
                </div>
                <div className="text-right">
                  <span className="font-mono font-bold text-purple-900 block">3,880 (9%)</span>
                  <span className="text-[9px] text-purple-600">Sheep & Goat</span>
                </div>
              </div>
            </div>
          </div>

          <div className="mt-3 pt-2 border-t border-black/5 text-[11px] text-zinc-500 font-mono text-center">
            All batches QR-verified on Bharat Pashudhan (INAPH)
          </div>
        </div>
      </div>

      {/* Persistent Area Table */}
      <div className="vetra-card overflow-hidden">
        <div className="p-4 border-b border-black/5 flex flex-wrap items-center justify-between gap-3 bg-parchment/40">
          <div>
            <h3 className="font-bold text-base text-ink font-figtree">Area-Wise Animal Inoculation Records</h3>
            <p className="text-xs text-ink-metadata font-inter">Live persistent database of individual animal ear-tag credentials and cold storage audit</p>
          </div>
          <div className="text-xs font-mono text-zinc-600">
            Auto-persisted to local registry
          </div>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs font-inter border-collapse">
            <thead className="bg-parchment/80 text-ink-secondary uppercase text-[10px] tracking-wider border-b border-black/10">
              <tr>
                <th className="py-3 px-4 font-bold">Animal Tag ID</th>
                <th className="py-3 px-4 font-bold">Species / Breed</th>
                <th className="py-3 px-4 font-bold">Farmer Name</th>
                <th className="py-3 px-4 font-bold">District & Taluka</th>
                <th className="py-3 px-4 font-bold">Vaccine Administered</th>
                <th className="py-3 px-4 font-bold">Batch & Cold Chain</th>
                <th className="py-3 px-4 font-bold">Inoculation Date</th>
                <th className="py-3 px-4 font-bold text-center">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-black/5">
              {filteredRecords.map((r, idx) => (
                <tr key={idx} className="hover:bg-parchment/40 transition-colors">
                  <td className="py-3 px-4 font-mono font-bold text-ink">{r.id}</td>
                  <td className="py-3 px-4 font-semibold text-ink">{r.species}</td>
                  <td className="py-3 px-4 text-zinc-700">{r.farmer}</td>
                  <td className="py-3 px-4 font-medium text-zinc-600">
                    {r.district} <span className="text-zinc-400 font-mono">({r.taluka})</span>
                  </td>
                  <td className="py-3 px-4">
                    <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-900 border border-blue-200 font-semibold text-[11px]">
                      {r.vaccine}
                    </span>
                  </td>
                  <td className="py-3 px-4 font-mono text-[11px] text-zinc-600">
                    {r.batch} <span className="text-blue-700 font-bold ml-1">({r.temp})</span>
                  </td>
                  <td className="py-3 px-4 text-zinc-500 font-mono">{r.date}</td>
                  <td className="py-3 px-4 text-center">
                    <span className="chip-resolved text-[10px]">{r.status}</span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Modal: Log New Vaccination */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-lg w-full p-6 shadow-2xl border border-black/15 font-figtree animate-fadeIn">
            <div className="flex items-center justify-between pb-3 border-b border-black/10">
              <div className="flex items-center gap-2">
                <div className="p-2 bg-green-100 rounded-lg">
                  <Syringe className="w-5 h-5 text-[#16a34a]" />
                </div>
                <div>
                  <h3 className="font-bold text-lg text-ink">Log Animal Vaccination</h3>
                  <p className="text-xs text-ink-metadata font-inter">Record individual immunization into area registry</p>
                </div>
              </div>
              <button onClick={() => setIsModalOpen(false)} className="p-1 text-ink-metadata hover:text-ink cursor-pointer">
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSave} className="mt-4 space-y-3 text-xs font-inter">
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">Animal Tag ID *</label>
                  <input
                    type="text"
                    required
                    value={formTag}
                    onChange={(e) => setFormTag(e.target.value)}
                    placeholder="e.g. MH-PUN-09942"
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-mono focus:outline-none focus:border-[#94e130]"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-ink mb-1">Species & Breed *</label>
                  <select
                    value={formSpecies}
                    onChange={(e) => setFormSpecies(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none"
                  >
                    <option value="Gir Cow">Cow (Gir Indigenous)</option>
                    <option value="Murrah Buffalo">Buffalo (Murrah)</option>
                    <option value="Jersey Cross">Jersey / HF Crossbred</option>
                    <option value="Khillari Bull">Khillari Draught</option>
                    <option value="Osmanabadi Goat">Osmanabadi Goat</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">Farmer / Owner Name *</label>
                  <input
                    type="text"
                    required
                    value={formFarmer}
                    onChange={(e) => setFormFarmer(e.target.value)}
                    placeholder="e.g. Sanjay Patil"
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none focus:border-[#94e130]"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-ink mb-1">Vaccine Type *</label>
                  <select
                    value={formVaccine}
                    onChange={(e) => setFormVaccine(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-semibold focus:outline-none"
                  >
                    <option value="Goat Pox (LSD)">Goat Pox (LSD Heterologous)</option>
                    <option value="FMD Trivalent">FMD Trivalent (O, A, Asia-1)</option>
                    <option value="Anthrax Spore">Anthrax Spore Vaccine</option>
                    <option value="PPR Sungri-96">PPR Small Ruminants</option>
                  </select>
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">District *</label>
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
                  <label className="block font-semibold text-ink mb-1">Taluka / Block *</label>
                  <input
                    type="text"
                    required
                    value={formTaluka}
                    onChange={(e) => setFormTaluka(e.target.value)}
                    placeholder="e.g. Haveli (Wagholi village)"
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none focus:border-[#94e130]"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block font-semibold text-ink mb-1">Batch Number *</label>
                  <input
                    type="text"
                    required
                    value={formBatch}
                    onChange={(e) => setFormBatch(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-mono focus:outline-none"
                  />
                </div>
                <div>
                  <label className="block font-semibold text-ink mb-1">Cold Storage Temp (°C)</label>
                  <input
                    type="number"
                    step="0.1"
                    required
                    value={formTemp}
                    onChange={(e) => setFormTemp(e.target.value)}
                    className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white font-mono focus:outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block font-semibold text-ink mb-1">Administering Officer</label>
                <input
                  type="text"
                  required
                  value={formOfficer}
                  onChange={(e) => setFormOfficer(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-black/15 bg-white focus:outline-none"
                />
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
                  className="px-5 py-2 bg-[#94e130] hover:bg-[#86cd2a] text-[#141414] font-bold rounded-lg cursor-pointer"
                >
                  Save to Area Registry
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

