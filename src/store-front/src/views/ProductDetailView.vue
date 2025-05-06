<template>
  <div class="product-detail" v-if="productExists">
    <div class="product-image">
      <img :src="product.image" :alt="product.name" />
    </div>
    <div class="product-info">
      <h2>{{ product.name }}</h2>
      <small>Product ID: {{ product.id }}</small>
      <p>{{ product.description }}</p>
      <div class="product-controls">
        <p>
          <b
            >Price: <span class="price">{{ product.price }}</span></b
          >
        </p>
        <input type="number" v-model="quantity" min="1" class="quantity-input" />
        <button @click="addToCart">Add to Cart</button>
      </div>
    </div>
  </div>
  <div class="product-detail" v-else>
    <div class="product-image">
      <img src="../assets/404.jpg" alt="Product not found" />
    </div>
    <div class="product-info">
      <h2>Oops! That product was not found...</h2>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import { useProductStore, useCartStore } from '@/stores'
import type { Product, CartItem } from '@/types'

const productStore = useProductStore()
const cartStore = useCartStore()
const route = useRoute()
const productId = computed(() => route.params.id as string)

const product = computed(() => {
  return productStore.products.find((p: Product) => p.id == productId.value)!
})

const quantity = ref(1)
const productExists = computed(() => !!product.value)

const addToCart = () => {
  const cartItem: CartItem = {
    product: product.value,
    quantity: quantity.value,
  }
  cartStore.addItem(cartItem)
}
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

.product-image {
  flex: 1;
}

.product-image img {
  width: 100%;
  height: auto;
  border-radius: 5px; /* Add subtle rounded corners to the image */
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

/* Override the global a tag styling when in product detail */
.product-detail a:hover {
  color: var(--accent-color);
}

@media (max-width: 768px) {
  .product-detail {
    flex-direction: column;
  }
}
</style>
