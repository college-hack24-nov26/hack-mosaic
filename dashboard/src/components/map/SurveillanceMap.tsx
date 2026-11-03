import React, { useState, useEffect } from 'react';
import { MapContainer, TileLayer, Marker, Popup, Circle, GeoJSON, useMap } from 'react-leaflet';
import L from 'leaflet';
import { MapCasePin, OutbreakCluster } from '../../types';
import { Layers, ShieldCheck, AlertCircle, Clock, Eye, Map, Globe, Compass } from 'lucide-react';
import districtGeoJSON from '../../data/districts.json';

interface SurveillanceMapProps {
  pins: MapCasePin[];
  clusters: OutbreakCluster[];
  onSelectCase?: (reportId: string) => void;
}

// Tile Layer Configuration (MapTiler + OpenStreetMap)
type TileLayerType = 'maptiler' | 'osm' | 'voyager' | 'satellite';

const MAPTILER_KEY = import.meta.env.VITE_MAPTILER_KEY || 'cKTaQaghkXlhl6xd2pWw';

const TILE_SOURCES: Record<TileLayerType, { url: string; attribution: string; maxZoom?: number }> = {
  maptiler: {
    url: `https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${MAPTILER_KEY}`,
    attribution: '&copy; <a href="https://www.maptiler.com/">MapTiler</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    maxZoom: 19,
  },
  osm: {
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 19,
  },
  voyager: {
    url: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
    attribution: '&copy; OpenStreetMap contributors &copy; CARTO',
    maxZoom: 19,
  },
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: 'Tiles &copy; Esri &mdash; Source: Esri, USGS, AeroGRID',
    maxZoom: 18,
  },
};

// Helper component to smoothly invalidate map sizing whenever tabs/container resize
const MapResizer: React.FC = () => {
  const map = useMap();
  useEffect(() => {
    const timer = setTimeout(() => {
      if (map && typeof map.invalidateSize === 'function') {
        map.invalidateSize();
      }
    }, 100);
    return () => clearTimeout(timer);
  }, [map]);
  return null;
};

// Function to generate Vetra SVG pin icons
const createVetraIcon = (status: string) => {
  let color = '#F2994A'; // Amber for submitted/under_review
  if (status === 'verified') color = '#C62828'; // Critical red
  if (status === 'resolved') color = '#94e130'; // Chartreuse

  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="32" height="32">
      <circle cx="12" cy="10" r="8" fill="${color}" stroke="#141414" stroke-width="1.5"/>
      <polygon points="8,15 16,15 12,22" fill="${color}" stroke="#141414" stroke-width="1.5"/>
      <circle cx="12" cy="10" r="3.5" fill="#ffffff" />
    </svg>
  `;

  return L.divIcon({
    className: 'custom-vetra-marker',
    html: svg,
    iconSize: [32, 32],
    iconAnchor: [16, 32],
    popupAnchor: [0, -30],
  });
};

export const SurveillanceMap: React.FC<SurveillanceMapProps> = ({ pins, clusters, onSelectCase }) => {
  const [activeTile, setActiveTile] = useState<TileLayerType>('maptiler');
  const [showClusters, setShowClusters] = useState(true);
  const [showDistricts, setShowDistricts] = useState(true);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [districtFilter, setDistrictFilter] = useState<string>('all');

  const filteredPins = pins.filter((pin) => {
    if (statusFilter !== 'all' && pin.status !== statusFilter) return false;
    if (districtFilter !== 'all' && pin.district !== districtFilter) return false;
    return true;
  });

  return (
    <div className="vetra-card p-0 overflow-hidden relative shadow-sm">
      {/* Map Control Header */}
      <div className="p-4 bg-surface-card border-b border-black/10 flex flex-wrap items-center justify-between gap-3 font-figtree">
        <div>
          <h3 className="font-semibold text-base text-ink flex items-center gap-2">
            <span className="w-2.5 h-2.5 rounded-full bg-alert-critical animate-pulse"></span>
            Real-Time Outbreak Surveillance Map
          </h3>
          <p className="text-xs text-ink-metadata font-inter">
            Active geo-referenced veterinary cases across Maharashtra State • MapTiler &amp; OpenStreetMap
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2 text-xs">
          {/* Map Tile Switcher */}
          <div className="flex items-center gap-1 bg-parchment p-1 rounded-sm border border-black/10 font-inter">
            <button
              onClick={() => setActiveTile('maptiler')}
              className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 transition-all ${
                activeTile === 'maptiler'
                  ? 'bg-white text-ink shadow-sm'
                  : 'text-ink-secondary hover:text-ink'
              }`}
            >
              <Map className="w-3.5 h-3.5 text-blue-600" /> MapTiler
            </button>
            <button
              onClick={() => setActiveTile('osm')}
              className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 transition-all ${
                activeTile === 'osm'
                  ? 'bg-white text-ink shadow-sm'
                  : 'text-ink-secondary hover:text-ink'
              }`}
            >
              <Compass className="w-3.5 h-3.5 text-emerald-600" /> OpenStreetMap
            </button>
            <button
              onClick={() => setActiveTile('satellite')}
              className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 transition-all ${
                activeTile === 'satellite'
                  ? 'bg-white text-ink shadow-sm'
                  : 'text-ink-secondary hover:text-ink'
              }`}
            >
              <Globe className="w-3.5 h-3.5 text-amber-600" /> Satellite
            </button>
          </div>

          {/* Status Filter */}
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-2.5 py-1.5 rounded-sm border border-border-hairline bg-parchment text-ink font-inter focus:outline-none focus:border-brand-primary"
          >
            <option value="all">All Case Statuses</option>
            <option value="verified">Verified Outbreaks (Red)</option>
            <option value="submitted">Pending Review (Amber)</option>
            <option value="resolved">Resolved / Healthy (Green)</option>
          </select>

          {/* District Filter */}
          <select
            value={districtFilter}
            onChange={(e) => setDistrictFilter(e.target.value)}
            className="px-2.5 py-1.5 rounded-sm border border-border-hairline bg-parchment text-ink font-inter focus:outline-none focus:border-brand-primary"
          >
            <option value="all">All Districts</option>
            <option value="Pune">Pune District</option>
            <option value="Ahmednagar">Ahmednagar District</option>
            <option value="Satara">Satara District</option>
            <option value="Solapur">Solapur District</option>
            <option value="Kolhapur">Kolhapur District</option>
          </select>

          {/* Cluster Hotspot Toggle */}
          <label className="flex items-center gap-1.5 px-3 py-1.5 rounded-sm bg-parchment border border-border-hairline cursor-pointer select-none">
            <input
              type="checkbox"
              checked={showClusters}
              onChange={(e) => setShowClusters(e.target.checked)}
              className="accent-brand-primary"
            />
            <Layers className="w-3.5 h-3.5 text-ink-secondary" />
            <span className="font-semibold text-ink">ML Hotspots</span>
          </label>

          {/* District Boundaries Toggle */}
          <label className="flex items-center gap-1.5 px-3 py-1.5 rounded-sm bg-parchment border border-border-hairline cursor-pointer select-none">
            <input
              type="checkbox"
              checked={showDistricts}
              onChange={(e) => setShowDistricts(e.target.checked)}
              className="accent-brand-primary"
            />
            <span className="w-2.5 h-2.5 rounded-sm bg-[#16a34a]/30 border border-[#16a34a]"></span>
            <span className="font-semibold text-ink">District Boundaries</span>
          </label>
        </div>
      </div>

      {/* Map Container with Smooth Dynamic Tiles */}
      <div className="h-[460px] w-full relative z-0">
        <MapContainer
          center={[18.5204, 74.2000]}
          zoom={8}
          scrollWheelZoom={true}
          className="h-full w-full"
        >
          <MapResizer />
          <TileLayer
            key={activeTile}
            attribution={TILE_SOURCES[activeTile].attribution}
            url={TILE_SOURCES[activeTile].url}
            maxZoom={TILE_SOURCES[activeTile].maxZoom || 18}
          />

          {/* Administrative District GeoJSON Boundaries */}
          {showDistricts && (
            <GeoJSON 
              data={districtGeoJSON as any} 
              style={{ color: '#16a34a', weight: 1, fillOpacity: 0.1 }}
              onEachFeature={(feature: any, layer: any) => {
                if (feature && feature.properties && feature.properties.name && typeof layer.bindTooltip === 'function') {
                  layer.bindTooltip(
                    `<div style="font-family: 'Figtree', sans-serif; font-size: 12px; padding: 2px;">
                      <div style="font-weight: 700; color: #16a34a;">${feature.properties.name} District</div>
                      <div style="color: #555; font-size: 11px;">Status: <strong>${feature.properties.surveillance_status || 'Monitored'}</strong></div>
                      <div style="color: #777; font-size: 11px;">Active Cases: <strong>${feature.properties.active_cases || 0}</strong> • Risk: <strong>${feature.properties.risk_level || 'Normal'}</strong></div>
                    </div>`,
                    { sticky: true }
                  );
                }
              }}
            />
          )}

          {/* ML Cluster Hotspots */}
          {showClusters &&
            clusters.map((cluster) => {
              const fillColor = cluster.risk_level === 'critical' ? '#C62828' : '#F2994A';
              return (
                <Circle
                  key={cluster.cluster_id}
                  center={[cluster.center_latitude, cluster.center_longitude]}
                  radius={cluster.radius_km * 1000}
                  pathOptions={{
                    color: fillColor,
                    fillColor: fillColor,
                    fillOpacity: 0.18,
                    weight: 2,
                    dashArray: '5, 5',
                  }}
                >
                  <Popup>
                    <div className="p-1 font-figtree">
                      <div className="flex items-center gap-1.5 text-alert-critical font-bold text-xs uppercase mb-1">
                        <AlertCircle className="w-3.5 h-3.5" />
                        Predicted Cluster ({cluster.risk_level})
                      </div>
                      <div className="text-sm font-semibold text-ink">{cluster.primary_disease}</div>
                      <div className="text-xs text-ink-secondary mt-1 font-inter">
                        <strong>{cluster.case_count} cases</strong> concentrated within {cluster.radius_km}km radius in {cluster.district}.
                      </div>
                    </div>
                  </Popup>
                </Circle>
              );
            })}

          {/* Case Pins */}
          {filteredPins.map((pin) => (
            <Marker
              key={pin.report_id}
              position={[pin.latitude, pin.longitude]}
              icon={createVetraIcon(pin.status)}
            >
              <Popup>
                <div className="p-2 font-figtree min-w-[200px]">
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-[10px] font-mono bg-black/5 px-1.5 py-0.5 rounded text-ink-metadata">
                      {pin.report_id}
                    </span>
                    {pin.status === 'verified' && (
                      <span className="chip-critical text-[10px] py-0.5">
                        <ShieldCheck className="w-3 h-3" /> Confirmed
                      </span>
                    )}
                    {pin.status === 'submitted' && (
                      <span className="chip-caution text-[10px] py-0.5">
                        <Clock className="w-3 h-3" /> Pending Vet
                      </span>
                    )}
                    {pin.status === 'resolved' && (
                      <span className="chip-healthy text-[10px] py-0.5">
                        Resolved
                      </span>
                    )}
                  </div>
                  <h4 className="font-bold text-sm text-ink">{pin.disease_name}</h4>
                  <p className="text-xs text-ink-secondary font-inter mt-0.5">
                    Species: {pin.animal_species}
                  </p>
                  <p className="text-xs text-ink-metadata font-inter">
                    {pin.district} District • {pin.reported_date}
                  </p>
                  {pin.confidence && (
                    <div className="mt-2 text-[11px] text-ink-secondary bg-parchment px-2 py-1 rounded-sm font-inter">
                      AI Confidence: <strong>{Math.round(pin.confidence * 100)}%</strong>
                    </div>
                  )}
                  {onSelectCase && (
                    <button
                      onClick={() => onSelectCase(pin.report_id)}
                      className="mt-2 w-full text-xs font-semibold py-1.5 px-2 bg-brand-primary text-ink rounded-sm hover:bg-brand-hover transition-colors flex items-center justify-center gap-1 shadow-sm"
                    >
                      <Eye className="w-3.5 h-3.5" /> Full Case Details
                    </button>
                  )}
                </div>
              </Popup>
            </Marker>
          ))}
        </MapContainer>
      </div>

      {/* Map Legend Footer */}
      <div className="px-4 py-2.5 bg-surface-card border-t border-black/5 flex flex-wrap items-center justify-between text-xs font-inter text-ink-secondary">
        <div className="flex items-center gap-4">
          <span className="font-semibold text-ink font-figtree">Legend:</span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-alert-critical"></span> Confirmed Outbreak
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-caution-amber"></span> Pending Verification
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-brand-primary"></span> Resolved
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-3.5 h-3.5 rounded-full border border-dashed border-alert-critical bg-alert-critical/20"></span> ML Risk Cluster
          </span>
        </div>
        <div>
          Active Base: <strong className="capitalize">{activeTile}</strong>
        </div>
      </div>
    </div>
  );
};
