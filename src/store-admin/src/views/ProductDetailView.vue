<template>
  <div class="action-button">
    <router-link :to="`/product/${productId}/edit`">
      <button class="button">Edit Product</button>
    </router-link>
  </div>
  <div class="product-detail" v-if="productExists">
    <div class="product-image">
      <img :src="product?.image" alt="Product Image" />
    </div>
    <div class="product-info">
      <h2>{{ product?.name }} - {{ product?.price }}</h2>
      <small>Product ID: {{ product?.id }}</small>
      <p>{{ product?.description }}</p>
    </div>
  </div>
  <div class="product-detail" v-else>
    <h3>Product not found</h3>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useProductStore } from '@/stores'

const productStore = useProductStore()
const route = useRoute()
const productId = computed(() => route.params.id as string)

const product = computed(() => {
  return productStore.products.find((product) => product.id == productId.value)
})

const productExists = computed(() => !!product.value)
</script>

<style scoped>
.product-detail {
  text-align: left;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  gap: 1rem;
  margin: 1rem;
}

.product-image,
.product-info {
  flex: 1;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
}

.product-image img {
  width: 100%;
  height: auto;
  border-radius: 5px;
  display: block;
  margin-top: 20px;
}

.product-info {
  flex: 1;
  text-align: left;
}

.product-info h2 {
  font-size: 24px;
  margin-bottom: 10px;
}

.product-info p {
  font-size: 16px;
  margin-bottom: 20px;
}

.product-detail a {
  color: var(--accent-color-dark);
  text-decoration: underline;
}

.action-button {
  text-align: right;
  margin: 1.5rem;
}

@media (max-width: 768px) {
  .product-detail {
    flex-direction: column;
  }
}
</style>
