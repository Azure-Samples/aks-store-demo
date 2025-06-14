import { fileURLToPath, URL } from 'node:url'
import { defineConfig, loadEnv, ConfigEnv, UserConfig, Plugin } from 'vite'
import vue from '@vitejs/plugin-vue'
import vueJsx from '@vitejs/plugin-vue-jsx'
import vueDevTools from 'vite-plugin-vue-devtools'
import bodyParser from 'body-parser'
import fetch from 'node-fetch'
import type { IncomingMessage, ServerResponse } from 'http'
import type { ViteDevServer } from 'vite'
import type { Response } from 'node-fetch'
import type { Product } from './src/types'

interface IncomingMessageWithBody extends IncomingMessage {
  body?: string;
}

// https://vite.dev/config/
export default defineConfig(({ mode }: ConfigEnv): UserConfig => {
  // Load env files
  const env = loadEnv(mode, process.cwd())

  const PRODUCT_SERVICE_URL = env.VITE_PRODUCT_SERVICE_URL || "http://localhost:3002/"
  const ORDER_SERVICE_URL = env.VITE_ORDER_SERVICE_URL || "http://localhost:3000/"

  const middlewarePlugin: Plugin = {
    name: 'configure-server',
    configureServer(server: ViteDevServer) {
      server.middlewares.use(bodyParser.json())

      // Health check
      server.middlewares.use('/health', (req: IncomingMessage, res: ServerResponse) => {
        if (req.method === 'GET') {
          const version = process.env.APP_VERSION || '0.1.0'
          res.setHeader('Content-Type', 'application/json')
          res.end(JSON.stringify({ status: 'ok', version: version }))
        }
      })

      // Get all products
      server.middlewares.use('/api/products', (req: IncomingMessage, res: ServerResponse) => {
        if (req.method === 'GET') {
          fetch(`${PRODUCT_SERVICE_URL}`)
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const products = data as Product[]
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(products))
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to fetch products' }))
            })
        }
      })

      // Submit order
      server.middlewares.use('/api/orders', (req: IncomingMessageWithBody, res: ServerResponse) => {
        if (req.method === 'POST') {
          const order = req.body
          fetch(`${ORDER_SERVICE_URL}`, {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
            },
            body: JSON.stringify(order),
          })
            .then(() => {
              res.statusCode = 201
              res.end()
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to submit order' }))
            })
        }
      })
    }
  }
  return {
    plugins: [
      vue(),
      vueJsx(),
      vueDevTools(),
      middlewarePlugin,
    ],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      },
    },
    server: {
      port: 8080,
      open: true,
      host: '0.0.0.0',
      cors: true,
      strictPort: true,
      proxy: {},
    }
  }
})
