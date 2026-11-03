// @ts-nocheck
import React, { useState, useEffect, useRef } from 'react';
import { MapCasePin, OutbreakCluster } from '../../types';
import districtGeoJSON from '../../data/districts.json';

interface SurveillanceMapProps {
  pins: MapCasePin[];
  clusters: OutbreakCluster[];
  onSelectCase?: (reportId: string) => void;
}

type TileLayerType = 'osm' | 'maptiler' | 'satellite';

const MAPTILER_KEY = 'cKTaQaghkXIhI6xd2pWw';

const TILE_SOURCES: Record<TileLayerType, { url: string; attribution: string; maxZoom: number }> = {
  osm: {
    url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
    maxZoom: 19,
  },
  maptiler: {
    url: `https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=${MAPTILER_KEY}`,
    attribution: '&copy; <a href="https://www.maptiler.com/">MapTiler</a> &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    maxZoom: 19,
  },
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: 'Tiles &copy; Esri &mdash; Source: Esri, USGS, AeroGRID',
    maxZoom: 18,
  },
};

export const SurveillanceMap: React.FC<SurveillanceMapProps> = ({ pins = [], clusters = [], onSelectCase }) => {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const tileLayerRef = useRef<any>(null);
  const markersLayerRef = useRef<any>(null);
  const clustersLayerRef = useRef<any>(null);
  const districtsLayerRef = useRef<any>(null);

  const [activeTile, setActiveTile] = useState<TileLayerType>('maptiler');
  const [showClusters, setShowClusters] = useState(true);
  const [showDistricts, setShowDistricts] = useState(false);
  const [statusFilter, setStatusFilter] = useState<string>('all');
  const [districtFilter, setDistrictFilter] = useState<string>('all');

  // Filter Pins
  const filteredPins = pins.filter((pin) => {
    if (statusFilter !== 'all' && pin.status !== statusFilter) return false;
    if (districtFilter !== 'all' && pin.district !== districtFilter) return false;
    return true;
  });

  // Initialize Leaflet Map
  useEffect(() => {
    if (!mapContainerRef.current) return;

    const L = (window as any).L;
    if (!L) return;

    if (!mapInstanceRef.current) {
      const map = L.map(mapContainerRef.current, {
        center: [18.5204, 74.2000],
        zoom: 8,
        scrollWheelZoom: true,
      });

      mapInstanceRef.current = map;

      // Base Tile Layer
      const initialSource = TILE_SOURCES[activeTile];
      tileLayerRef.current = L.tileLayer(initialSource.url, {
        attribution: initialSource.attribution,
        maxZoom: initialSource.maxZoom,
      }).addTo(map);

      // Automatic fallback if tile provider fails
      tileLayerRef.current.on('tileerror', () => {
        console.warn('Tile load error on current layer, falling back to OpenStreetMap');
        if (tileLayerRef.current && activeTile !== 'osm') {
          tileLayerRef.current.setUrl(TILE_SOURCES.osm.url);
        }
      });

      // Layer Groups
      districtsLayerRef.current = L.layerGroup().addTo(map);
      clustersLayerRef.current = L.layerGroup().addTo(map);
      markersLayerRef.current = L.layerGroup().addTo(map);

      // Invalidate map sizing after layout settles
      setTimeout(() => {
        map.invalidateSize();
      }, 200);
    }

    return () => {
      if (mapInstanceRef.current) {
        mapInstanceRef.current.remove();
        mapInstanceRef.current = null;
      }
    };
  }, []);

  // Update Base Tile Layer when activeTile changes
  useEffect(() => {
    const L = (window as any).L;
    if (!mapInstanceRef.current || !tileLayerRef.current || !L) return;

    const source = TILE_SOURCES[activeTile];
    tileLayerRef.current.setUrl(source.url);
  }, [activeTile]);

  // Update District Boundaries Layer
  useEffect(() => {
    const L = (window as any).L;
    if (!mapInstanceRef.current || !districtsLayerRef.current || !L) return;

    districtsLayerRef.current.clearLayers();

    if (showDistricts && districtGeoJSON) {
      const geoLayer = L.geoJSON(districtGeoJSON, {
        style: {
          color: '#94a3b8',
          weight: 1,
          fillColor: 'transparent',
          fillOpacity: 0,
        },
        onEachFeature: (feature: any, layer: any) => {
          if (feature && feature.properties && feature.properties.name) {
            layer.bindTooltip(
              `<div style="font-family: 'Figtree', sans-serif; font-size: 12px; padding: 2px;">
                <div style="font-weight: 700; color: #334155;">${feature.properties.name} District</div>
                <div style="color: #555; font-size: 11px;">Status: <strong>${feature.properties.surveillance_status || 'Monitored'}</strong></div>
                <div style="color: #777; font-size: 11px;">Active Cases: <strong>${feature.properties.active_cases || 0}</strong> • Risk: <strong>${feature.properties.risk_level || 'Normal'}</strong></div>
              </div>`,
              { sticky: true }
            );
          }
        },
      });

      districtsLayerRef.current.addLayer(geoLayer);
    }
  }, [showDistricts]);

  // Update Outbreak Clusters Layer
  useEffect(() => {
    const L = (window as any).L;
    if (!mapInstanceRef.current || !clustersLayerRef.current || !L) return;

    clustersLayerRef.current.clearLayers();

    if (showClusters && clusters.length > 0) {
      clusters.forEach((cluster) => {
        const fillColor = cluster.risk_level === 'critical' ? '#C62828' : '#F2994A';
        const circle = L.circle([cluster.center_latitude, cluster.center_longitude], {
          color: fillColor,
          fillColor: fillColor,
          fillOpacity: 0.18,
          weight: 2,
          dashArray: '5, 5',
          radius: cluster.radius_km * 1000,
        });

        circle.bindPopup(`
          <div style="font-family: 'Figtree', sans-serif; padding: 4px;">
            <div style="color: #C62828; font-weight: bold; font-size: 11px; text-transform: uppercase;">
              ⚠️ Predicted Cluster (${cluster.risk_level})
            </div>
            <div style="font-size: 13px; font-weight: 600; color: #141414; margin-top: 2px;">${cluster.primary_disease}</div>
            <div style="font-size: 11px; color: #666; margin-top: 4px;">
              <strong>${cluster.case_count} cases</strong> concentrated within ${cluster.radius_km}km in ${cluster.district}.
            </div>
          </div>
        `);

        clustersLayerRef.current.addLayer(circle);
      });
    }
  }, [showClusters, clusters]);

  // Update Case Pins Layer
  useEffect(() => {
    const L = (window as any).L;
    if (!mapInstanceRef.current || !markersLayerRef.current || !L) return;

    markersLayerRef.current.clearLayers();

    filteredPins.forEach((pin) => {
      let color = '#F2994A';
      if (pin.status === 'verified') color = '#C62828';
      if (pin.status === 'resolved') color = '#94e130';

      const svgHtml = `
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" width="30" height="30">
          <circle cx="12" cy="10" r="8" fill="${color}" stroke="#141414" stroke-width="1.5"/>
          <polygon points="8,15 16,15 12,22" fill="${color}" stroke="#141414" stroke-width="1.5"/>
          <circle cx="12" cy="10" r="3" fill="#ffffff" />
        </svg>
      `;

      const customIcon = L.divIcon({
        className: 'custom-pin-marker',
        html: svgHtml,
        iconSize: [30, 30],
        iconAnchor: [15, 30],
        popupAnchor: [0, -28],
      });

      const marker = L.marker([pin.latitude, pin.longitude], { icon: customIcon });

      const statusBadge =
        pin.status === 'verified'
          ? '<span style="background: #fee2e2; color: #991b1b; padding: 2px 6px; border-radius: 9999px; font-size: 10px; font-weight: bold;">Confirmed</span>'
          : pin.status === 'submitted'
          ? '<span style="background: #fef3c7; color: #92400e; padding: 2px 6px; border-radius: 9999px; font-size: 10px; font-weight: bold;">Pending Vet</span>'
          : '<span style="background: #dcfce7; color: #166534; padding: 2px 6px; border-radius: 9999px; font-size: 10px; font-weight: bold;">Resolved</span>';

      const popupContent = `
        <div style="font-family: 'Figtree', sans-serif; min-width: 190px; padding: 4px;">
          <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 4px;">
            <span style="font-family: monospace; font-size: 10px; background: rgba(0,0,0,0.06); padding: 1px 4px; border-radius: 3px;">${pin.report_id}</span>
            ${statusBadge}
          </div>
          <div style="font-weight: 700; font-size: 13px; color: #141414; margin-top: 2px;">${pin.disease_name}</div>
          <div style="font-size: 11px; color: #555; margin-top: 2px;">Species: ${pin.animal_species}</div>
          <div style="font-size: 11px; color: #888;">${pin.district} District • ${pin.reported_date}</div>
          ${
            pin.confidence
              ? `<div style="margin-top: 6px; font-size: 11px; color: #555; background: #f5f5f5; padding: 3px 6px; border-radius: 3px;">AI Confidence: <strong>${Math.round(
                  pin.confidence * 100
                )}%</strong></div>`
              : ''
          }
        </div>
      `;

      marker.bindPopup(popupContent);
      markersLayerRef.current.addLayer(marker);
    });
  }, [filteredPins]);

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
              onClick={() => setActiveTile('osm')}
              className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 transition-all ${
                activeTile === 'osm'
                  ? 'bg-white text-ink shadow-sm'
                  : 'text-ink-secondary hover:text-ink'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-emerald-600 inline-block"></span>
              OpenStreetMap
            </button>
            <button
              onClick={() => setActiveTile('maptiler')}
              className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 transition-all ${
                activeTile === 'maptiler'
                  ? 'bg-white text-ink shadow-sm'
                  : 'text-ink-secondary hover:text-ink'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-blue-600 inline-block"></span>
              MapTiler
            </button>
            <button
              onClick={() => setActiveTile('satellite')}
              className={`px-2.5 py-1 rounded text-xs font-semibold flex items-center gap-1 transition-all ${
                activeTile === 'satellite'
                  ? 'bg-white text-ink shadow-sm'
                  : 'text-ink-secondary hover:text-ink'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-amber-600 inline-block"></span>
              Satellite
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
            <span className="w-2.5 h-2.5 rounded-sm bg-slate-200 border border-slate-400"></span>
            <span className="font-semibold text-ink">District Boundaries</span>
          </label>
        </div>
      </div>

      {/* Direct Leaflet Map Canvas Container */}
      <div className="h-[520px] w-full relative z-0">
        <div ref={mapContainerRef} className="h-full w-full" />
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
          <span className="flex items-center gap-1.5">
            <span className="w-3 h-2 border border-slate-400 bg-slate-200 rounded-xs"></span> District Boundaries
          </span>
        </div>
        <div>
          Active Base: <strong className="capitalize">{activeTile}</strong>
        </div>
      </div>
    </div>
  );
};
