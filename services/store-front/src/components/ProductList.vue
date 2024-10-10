<template>
  <div class="product-list">
    <ProductCard
        v-for="product in products"
        :key="product.id"
        :product="product"
        @addToCart="addToCart"
      />
  </div>
</template>

<script>
  import ProductCard from '../components/ProductCard'

  export default {
    name: 'ProductList',
    props: ['products'],
    components: {
      ProductCard
    },
    methods: {
      addToCart({ productId, quantity }) {
        this.$emit('addToCart', {
          productId: productId,
          quantity: quantity
        })
      }
    }
  }
</script>