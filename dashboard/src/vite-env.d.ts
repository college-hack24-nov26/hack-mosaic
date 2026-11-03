/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_BASE_URL: string;
  readonly VITE_APP_NAME: string;
  readonly VITE_APP_VERSION: string;
  readonly VITE_MAPTILER_KEY?: string;
  readonly VITE_MAP_DEFAULT_LAT?: string;
  readonly VITE_MAP_DEFAULT_LNG?: string;
  readonly VITE_MAP_DEFAULT_ZOOM?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}

