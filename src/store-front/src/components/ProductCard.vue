<template>
  <div class="product-card">
    <img :src="product.image" alt="Product Image" @click="routeToProduct" />
    <h2 @click="routeToProduct">{{ product.name }}</h2>
    <p @click="routeToProduct">{{ product.description }}</p>
    <div class="product-details">
      <div class="product-price">
        <p class="price">{{ product.price }}</p>
      </div>
      <div class="product-controls">
        <input type="number" v-model="quantity" min="1" class="quantity-input" />
        <button @click="addToCart">Add to Cart</button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useProductStore, useCartStore } from '@/stores'
import type { Product, CartItem } from '@/types'

const productStore = useProductStore()
const cartStore = useCartStore()
const router = useRouter()

const props = defineProps<{
  product: Product
}>()

const product = ref<Product>(props.product)

const quantity = ref(1)

const addToCart = () => {
  const cartItem: CartItem = {
    product: product.value,
    quantity: quantity.value,
  }
  cartStore.addItem(cartItem)
}

const routeToProduct = () => {
  router.push(`/product/${product.value.id}`)
}

onMounted(() => {
  const fetchedProduct = productStore.products.find((p: Product) => p.id == props.product.id)
  if (fetchedProduct) {
    product.value = fetchedProduct
  }
})
</script>
