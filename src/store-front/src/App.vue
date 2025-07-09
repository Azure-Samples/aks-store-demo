<template>
  <TopNav />
  <RouterView />
</template>

<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { useProductStore } from '@/stores'
import type { Product } from '@/types'
import TopNav from './components/TopNav.vue'

const productStore = useProductStore()

onMounted(() => {
  if (productStore.count === 0) {
    console.log('Fetching products')
    fetch('/api/products')
      .then((response) => response.json())
      .then((data: Product[]) => {
        productStore.addProducts(data)
        console.log(`Fetched ${data.length} products`)
      })
      .catch((error) => {
        console.log(error)
        alert('Error occurred while fetching products')
      })
  }
})
</script>

<style scoped></style>
