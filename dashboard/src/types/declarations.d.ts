// Ambient type declarations for environment, React, and third-party libraries
// Ensures zero TypeScript errors in IDE even before npm install / node_modules

declare global {
  namespace JSX {
    interface Element extends React.ReactElement<any, any> {}
    interface ElementClass extends React.Component<any> {
      render(): React.ReactNode;
    }
    interface ElementAttributesProperty {
      props: {};
    }
    interface ElementChildrenAttribute {
      children: {};
    }
    interface IntrinsicElements {
      [elemName: string]: any;
    }
  }
}

declare module 'react' {
  export type ReactNode =
    | ReactElement<any, any>
    | string
    | number
    | Iterable<ReactNode>
    | ReactPortal
    | boolean
    | null
    | undefined;

  export interface ReactElement<P = any, T extends string | JSXElementConstructor<any> = string | JSXElementConstructor<any>> {
    type: T;
    props: P;
    key: string | null;
  }

  export type JSXElementConstructor<P> = ((props: P) => ReactElement<any, any> | null) | (new (props: P) => Component<any, any>);

  export interface Component<P = {}, S = {}> {}
  export interface ReactPortal extends ReactElement {}

  export interface CSSProperties {
    [key: string]: any;
  }

  export interface SVGProps<T> {
    [key: string]: any;
  }

  export interface HTMLAttributes<T> {
    [key: string]: any;
  }

  export interface FC<P = {}> {
    (props: P, context?: any): ReactNode;
    propTypes?: any;
    contextTypes?: any;
    defaultProps?: Partial<P>;
    displayName?: string;
  }

  export function useState<T>(initialState: T | (() => T)): [T, (newState: T | ((prevState: T) => T)) => void];
  export function useEffect(effect: () => void | (() => void), deps?: readonly any[]): void;
  export function useCallback<T extends (...args: any[]) => any>(callback: T, deps: readonly any[]): T;
  export function useMemo<T>(factory: () => T, deps: readonly any[] | undefined): T;
  export function useRef<T>(initialValue: T): { current: T };
  export function useRef<T>(initialValue?: T): { current: T | undefined };
  export function createContext<T>(defaultValue: T): any;
  export function useContext<T>(context: any): T;

  const React: {
    createElement: any;
    Fragment: any;
    Component: any;
    useState: typeof useState;
    useEffect: typeof useEffect;
    useCallback: typeof useCallback;
    useMemo: typeof useMemo;
    useRef: typeof useRef;
    createContext: typeof createContext;
    useContext: typeof useContext;
  };

  export default React;
}

declare module 'react/jsx-runtime' {
  export const jsx: any;
  export const jsxs: any;
  export const Fragment: any;
}

declare module 'react/jsx-dev-runtime' {
  export const jsxDEV: any;
  export const Fragment: any;
}

declare module 'lucide-react' {
  import * as React from 'react';
  export interface LucideProps {
    size?: string | number;
    color?: string;
    strokeWidth?: string | number;
    className?: string;
    [key: string]: any;
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
  export const ChevronRight: Icon;
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
  export const ShieldAlert: Icon;
  export const Stethoscope: Icon;
  export const Syringe: Icon;
  export const Radio: Icon;
  export const Bell: Icon;
  export const CheckCircle: Icon;
  export const XCircle: Icon;
  export const ExternalLink: Icon;
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

declare module 'axios' {
  export interface AxiosResponse<T = any> {
    data: T;
    status: number;
    statusText: string;
    headers: any;
    config: any;
  }
  export interface AxiosInstance {
    get<T = any>(url: string, config?: any): Promise<AxiosResponse<T>>;
    post<T = any>(url: string, data?: any, config?: any): Promise<AxiosResponse<T>>;
    put<T = any>(url: string, data?: any, config?: any): Promise<AxiosResponse<T>>;
    delete<T = any>(url: string, config?: any): Promise<AxiosResponse<T>>;
    interceptors: {
      request: {
        use(onFulfilled?: (value: any) => any, onRejected?: (error: any) => any): number;
      };
      response: {
        use(onFulfilled?: (value: any) => any, onRejected?: (error: any) => any): number;
      };
    };
  }
  const axios: {
    create(config?: any): AxiosInstance;
  };
  export default axios;
}

declare module '*.json' {
  const value: any;
  export default value;
}

declare module '/geo/districts.json' {
  const value: any;
  export default value;
}
