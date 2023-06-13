<template>
  <div class="product-detail" v-if="productExists">
    <p>Product ID: {{ product.id }}</p>
    <h3>{{ product.name }}</h3>
    <p>{{ product.description }}</p>
    <p>{{ product.price }}</p>
    <button @click="updateProduct" class="button">Update Product</button>
  </div>
  <div class="product-detail" v-else>
    <h3>Product not found</h3>
  </div>
</template>

<script>
  export default {
    name: 'ProductDetail',
    props: ['products'],
    emits: ['updateProduct'],
    computed: {
      product() {
        return this.products.find(product => product.id == this.$route.params.id)
      },
      productExists() {
        return !!this.product
      }
    },
    methods: {
      updateProduct() {
        this.$emit('updateProduct', this.product)
      }
    }
  }
</script>

<style scoped>
/* a tag styles */
a {
  color: #0000FF;
  text-decoration: underline;
}

.product-detail {
  margin: 2rem auto;
  text-align: left;
}
</style>