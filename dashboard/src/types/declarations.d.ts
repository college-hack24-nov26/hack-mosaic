// Ambient type declarations for environment and libraries

declare module 'lucide-react' {
  import * as React from 'react';
  export interface LucideProps extends React.SVGProps<SVGSVGElement> {
    size?: string | number;
    color?: string;
    strokeWidth?: string | number;
    className?: string;
  }
  export type Icon = React.FC<LucideProps>;

  export const Layers: Icon;
  export const ShieldCheck: Icon;
  export const AlertCircle: Icon;
  export const Clock: Icon;
  export const Eye: Icon;
  export const Map: Icon;
  export const Globe: Icon;
  export const Compass: Icon;
  export const Sun: Icon;
  export const MapPin: Icon;
  export const Table: Icon;
  export const Download: Icon;
  export const RefreshCw: Icon;
  export const ChevronLeft: Icon;
  export const Search: Icon;
  export const Filter: Icon;
  export const Plus: Icon;
  export const Check: Icon;
  export const X: Icon;
  export const AlertTriangle: Icon;
  export const Activity: Icon;
  export const FileText: Icon;
  export const Send: Icon;
  export const Users: Icon;
  export const BookOpen: Icon;
  export const Settings: Icon;
  export const LogOut: Icon;
  export const ArrowRight: Icon;
  export const Info: Icon;
}

declare module 'leaflet' {
  export interface DivIconOptions {
    className?: string;
    html?: string;
    iconSize?: [number, number];
    iconAnchor?: [number, number];
    popupAnchor?: [number, number];
  }
  export interface DivIcon {
    options: DivIconOptions;
  }
  export function divIcon(options: DivIconOptions): DivIcon;

  export interface Map {
    invalidateSize(): void;
    setView(center: [number, number], zoom: number): void;
    remove(): void;
  }

  export interface Layer {
    bindTooltip(content: string, options?: any): Layer;
    bindPopup(content: string, options?: any): Layer;
    openPopup(): Layer;
  }
}

declare module 'react-leaflet' {
  import * as React from 'react';

  export interface MapContainerProps {
    center: [number, number];
    zoom: number;
    scrollWheelZoom?: boolean;
    className?: string;
    style?: React.CSSProperties;
    children?: React.ReactNode;
  }
  export const MapContainer: React.FC<MapContainerProps>;

  export interface TileLayerProps {
    url: string;
    attribution?: string;
    maxZoom?: number;
    key?: string | number;
  }
  export const TileLayer: React.FC<TileLayerProps>;

  export interface MarkerProps {
    position: [number, number];
    icon?: any;
    children?: React.ReactNode;
    key?: string | number;
  }
  export const Marker: React.FC<MarkerProps>;

  export interface PopupProps {
    children?: React.ReactNode;
  }
  export const Popup: React.FC<PopupProps>;

  export interface CircleProps {
    center: [number, number];
    radius: number;
    pathOptions?: {
      color?: string;
      fillColor?: string;
      fillOpacity?: number;
      weight?: number;
      dashArray?: string;
    };
    children?: React.ReactNode;
    key?: string | number;
  }
  export const Circle: React.FC<CircleProps>;

  export interface GeoJSONProps {
    data: any;
    style?: any;
    onEachFeature?: (feature: any, layer: any) => void;
  }
  export const GeoJSON: React.FC<GeoJSONProps>;

  export function useMap(): any;
}

declare module '*.json' {
  const value: any;
  export default value;
}

declare module '/geo/districts.json' {
  const value: any;
  export default value;
}
