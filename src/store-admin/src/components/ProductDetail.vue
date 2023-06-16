<template>
  <div class="product-detail" v-if="productExists">
    <div class="action-button">
      <router-link :to="`/product/${this.$route.params.id}/edit`">
        <button class="button">Edit Product</button>
      </router-link>
    </div>
    <br/>
    <p>Product ID: {{ product.id }}</p>
    <h3>{{ product.name }} - {{ product.price }}</h3>
    <p><img :src="product.image" alt="Product Image"></p>
    <p>{{ product.description }}</p>
  </div>
  <div class="product-detail" v-else>
    <h3>Product not found</h3>
  </div>
</template>

<script>
  export default {
    name: 'ProductDetail',
    props: ['products'],
    computed: {
      product() {
        return this.products.find(product => product.id == this.$route.params.id)
      },
      productExists() {
        return !!this.product
      }
    },
  }
</script>

<style scoped>
/* a tag styles */
a {
  color: #0000FF;
  text-decoration: underline;
}
</style>