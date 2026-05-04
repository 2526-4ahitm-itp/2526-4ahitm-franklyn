import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueDevTools from 'vite-plugin-vue-devtools'
import { execSync } from 'node:child_process'
import path from 'path'
import { cpSync, readFileSync } from 'fs'

const version = readFileSync("../VERSION", "utf-8").trim()

const genTsPath = process.env.PROTOBUF_GEN_PATH
  ? path.join(process.env.PROTOBUF_GEN_PATH, 'ts')
  : path.resolve(__dirname, '../protobuf/gen/ts')

const bufGenerate = () => ({
  name: 'buf-generate' as const,
  buildStart() {
    const genTsPath = process.env.PROTOBUF_GEN_PATH
      ? path.join(process.env.PROTOBUF_GEN_PATH, 'ts')
      : (() => {
          const protobufRoot = process.env.PROTOBUF_PATH ?? path.resolve(__dirname, '../protobuf')
          execSync('buf generate .', { cwd: protobufRoot, stdio: 'inherit' })
          return path.join(protobufRoot, 'gen/ts')
        })()

    const dest = path.resolve(__dirname, 'src/proto')
    cpSync(genTsPath, dest, { recursive: true })
  },
})


// https://vite.dev/config/
export default defineConfig({
  define: {
    __APP_VERSION__: JSON.stringify(version)
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:5050',
        changeOrigin: true,
        ws: true
      },
    },
  },
  plugins: [
    vue(),
    vueDevTools(),
    bufGenerate()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
      '@proto': genTsPath,
    },
  },
})
