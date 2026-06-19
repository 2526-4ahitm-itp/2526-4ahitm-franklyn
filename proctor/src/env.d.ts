/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_KCLK_URL: string
  readonly VITE_KCLK_REALM: string
  readonly VITE_KCLK_CLIENT_ID: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

// Injected at build time by Vite's `define` (see vite.config.ts).
// eslint-disable-next-line @typescript-eslint/naming-convention
declare const __APP_VERSION__: string
