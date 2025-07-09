export interface Product {
  id: number | string
  name: string
  price: number
  description?: string
  image?: string
  [key: string]: string | number | boolean | object | null | undefined
}

export interface OrderItem {
  productId: number | string
  quantity: number
  price: number
}

export interface Order {
  customerId: string
  items: OrderItem[]
  orderId?: string
  status?: number
  [key: string]: string | number | boolean | object | null | undefined
}

export interface HealthResponse {
  status: string
  version: string
  [key: string]: string | number | boolean | object | null
}

export interface AIGenerationResponse {
  result: string
  version: string
  [key: string]: string | number | boolean | object | null
}

export interface OrderProcessingResponse {
  success: boolean
  [key: string]: string | number | boolean | object | null
}
