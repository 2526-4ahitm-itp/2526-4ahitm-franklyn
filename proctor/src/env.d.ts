/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_KCLK_URL: string
  readonly VITE_KCLK_REALM: string
  readonly VITE_KCLK_CLIENT_ID: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
