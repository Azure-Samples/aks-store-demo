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
import type { Product, Order, HealthResponse, AIGenerationResponse, } from './src/types'

interface IncomingMessageWithBody extends IncomingMessage {
  body?: string;
}

// https://vite.dev/config/
export default defineConfig(({ mode }: ConfigEnv): UserConfig => {
  // Load env files
  const env = loadEnv(mode, process.cwd())

  const PRODUCT_SERVICE_URL = env.VITE_PRODUCT_SERVICE_URL || "http://localhost:3002/"
  const MAKELINE_SERVICE_URL = env.VITE_MAKELINE_SERVICE_URL || "http://localhost:3001/"

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

      // Get all orders
      server.middlewares.use('/api/makeline/order/fetch', (req: IncomingMessage, res: ServerResponse) => {
        if (req.method === 'GET') {
          fetch(`${MAKELINE_SERVICE_URL}order/fetch`)
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const orders = data as Order[]
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(orders))
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to fetch orders' }))
            })
        }
      })

      // Complete an order
      server.middlewares.use('/api/makeline/order', (req: IncomingMessageWithBody, res: ServerResponse) => {
        if (req.method === 'PUT') {
          const order = req.body
          fetch(`${MAKELINE_SERVICE_URL}order`, {
            method: 'PUT',
            body: JSON.stringify(order),
            headers: { 'Content-Type': 'application/json' }
          })
            .then(() => {
              res.statusCode = 200
              res.end()
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to process order' }))
            })
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

      // Upsert a product
      server.middlewares.use('/api/product', (req: IncomingMessageWithBody, res: ServerResponse) => {
        if (req.method === 'POST') { // Add a product
          const product = req.body
          fetch(`${PRODUCT_SERVICE_URL}`, {
            method: 'POST',
            body: JSON.stringify(product),
            headers: { 'Content-Type': 'application/json' }
          })
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const newProduct = data as Product
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(newProduct))
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to add product' }))
            })
        } else if (req.method === 'PUT') { // Update a product
          const product = req.body
          fetch(`${PRODUCT_SERVICE_URL}`, {
            method: 'PUT',
            body: JSON.stringify(product),
            headers: { 'Content-Type': 'application/json' }
          })
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const updatedProduct = data as Product
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(updatedProduct))
            })
            .catch((error: Error) => {
              console.error(error) // Changed from console.log to console.error
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to update product' }))
            })
        }
      })

      // Get AI service health
      server.middlewares.use('/api/ai/health', (req: IncomingMessage, res: ServerResponse) => {
        if (req.method === 'GET') {
          fetch(`${PRODUCT_SERVICE_URL}ai/health`)
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const health = data as HealthResponse
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(health))
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Health check failed' }))
            })
        }
      })

      // Generate product description
      server.middlewares.use('/api/ai/generate/description', (req: IncomingMessageWithBody, res: ServerResponse) => {
        if (req.method === 'POST') {
          const body = req.body
          fetch(`${PRODUCT_SERVICE_URL}ai/generate/description`, {
            method: 'POST',
            body: JSON.stringify(body),
            headers: { 'Content-Type': 'application/json' }
          })
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const description = data as AIGenerationResponse
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(description))
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to generate description' }))
            })
        }
      })

      // Generate product image
      server.middlewares.use('/api/ai/generate/image', (req: IncomingMessageWithBody, res: ServerResponse) => {
        if (req.method === 'POST') {
          const body = req.body
          fetch(`${PRODUCT_SERVICE_URL}ai/generate/image`, {
            method: 'POST',
            body: JSON.stringify(body),
            headers: { 'Content-Type': 'application/json' }
          })
            .then((response: Response) => response.json())
            .then((data: unknown) => {
              const image = data as AIGenerationResponse
              res.setHeader('Content-Type', 'application/json')
              res.end(JSON.stringify(image))
            })
            .catch((error: Error) => {
              console.error(error)
              res.statusCode = 500
              res.end(JSON.stringify({ error: 'Failed to generate image' }))
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
      port: 8081,
      open: true,
      host: '0.0.0.0',
      cors: true,
      strictPort: true,
      proxy: {},
    }
  }
})
