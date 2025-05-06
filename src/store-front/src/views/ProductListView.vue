<template>
  <div class="product-list">
    <ProductCard v-for="product in products" :key="product.id" :product="product" />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useProductStore } from '@/stores'
import ProductCard from '@/components/ProductCard.vue'

const productStore = useProductStore()
const products = computed(() => productStore.products)
</script>
