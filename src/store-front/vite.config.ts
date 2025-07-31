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

      // Runtime configuration endpoint
      server.middlewares.use('/api/config', (req: IncomingMessage, res: ServerResponse) => {
        if (req.method === 'GET') {
          // Support both proper case environment variables and lowercase for backwards compatibility
          const companyName = process.env.COMPANY_NAME || env.VITE_COMPANY_NAME || 'Contoso'
          res.setHeader('Content-Type', 'application/json')
          res.end(JSON.stringify({ 
            companyName: companyName
          }))
        }
      })

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
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify({ error: 'Failed to fetch products' }))
            })
        }
      })

      // Proxy all other /api requests to the respective services
      server.middlewares.use('/api/orders', (req: IncomingMessageWithBody, res: ServerResponse) => {
        if (req.method === 'POST') {
          let body = ''
          req.on('data', (chunk: Buffer) => {
            body += chunk.toString()
          })
          req.on('end', () => {
            fetch(`${ORDER_SERVICE_URL}v1/order`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: body,
            })
              .then((response: Response) => response.json())
              .then((data: unknown) => {
                res.setHeader('Content-Type', 'application/json')
                res.end(JSON.stringify(data))
              })
              .catch((error: Error) => {
                console.error(error)
                res.statusCode = 500
                res.setHeader('Content-Type', 'application/json')
                res.end(JSON.stringify({ error: 'Failed to place order' }))
              })
          })
        }
      })
    },
  }

  return {
    plugins: [vue(), vueJsx(), vueDevTools(), middlewarePlugin],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url)),
      },
    },
  }
})
