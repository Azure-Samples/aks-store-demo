import { ref, computed, watch } from 'vue'
import { defineStore } from 'pinia'
import type { Product, CartItem } from '@/types'

export const useProductStore = defineStore('product', () => {
  const products = ref<Product[]>([])
  const count = computed(() => products.value.length)
  const addProducts = (data: Product[]) => {
    products.value.push(...data)
  }
  return { products, count, addProducts }
})

export const useCartStore = defineStore('cart', () => {
  const storedCart = localStorage.getItem('cart')
  const items = ref<CartItem[]>(storedCart ? JSON.parse(storedCart) : [])
  const total = computed(() =>
    items.value.reduce((acc, item) => acc + item.product.price * item.quantity, 0),
  )
  const count = computed(() => items.value.reduce((acc, item) => acc + item.quantity, 0))
  const addItem = (item: CartItem) => {
    const existingItem = items.value.find((i) => i.product.id === item.product.id)
    if (existingItem) {
      existingItem.quantity += item.quantity
    } else {
      items.value.push(item)
    }
  }
  const removeItem = (id: number | string) => {
    const index = items.value.findIndex((i) => i.product.id === id)
    items.value.splice(index, 1)
  }
  const clear = () => {
    items.value = []
  }

  watch(
    items,
    (newItems) => {
      localStorage.setItem('cart', JSON.stringify(newItems))
    },
    { deep: true },
  )
  return { items, total, count, addItem, clear, removeItem }
})
