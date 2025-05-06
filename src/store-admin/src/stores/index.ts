import { ref, computed } from 'vue'
import { defineStore } from 'pinia'
import type { Product, Order } from '@/types'

export const useProductStore = defineStore('product', () => {
  const products = ref<Product[]>([])
  const count = computed(() => products.value.length)
  const addProducts = (data: Product[]) => {
    products.value.push(...data)
  }
  const addProduct = (product: Product) => {
    products.value.push(product)
  }
  const updateProduct = (product: Product) => {
    const index = products.value.findIndex((p) => p.id === product.id)
    if (index === -1) return
    products.value[index] = product
  }
  const removeProduct = (product: Product) => {
    const index = products.value.findIndex((p) => p.id === product.id)
    if (index === -1) return
    products.value.splice(index, 1)
  }

  return { products, count, addProducts, addProduct, updateProduct, removeProduct }
})

export const useOrderStore = defineStore('order', () => {
  const orders = ref<Order[]>([])
  const initialized = ref(false)
  const count = computed(() => orders.value.length)
  const addOrders = (data: Order[]) => {
    orders.value.push(...data)
  }
  const addOrder = (order: Order) => {
    orders.value.push(order)
    initialized.value = true
  }
  const removeOrder = (order: Order) => {
    const index = orders.value.findIndex((o) => o.id === order.id)
    if (index === -1) return
    orders.value.splice(index, 1)
  }

  return { orders, count, initialized, addOrders, addOrder, removeOrder }
})
