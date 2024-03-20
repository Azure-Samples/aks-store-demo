<template>
  <div class="action-button">
    <router-link to="/product/add">
      <button class="button">Add Product</button>
    </router-link>
  </div>
  <div class="product-list">
    <table>
      <thead>
        <tr>
          <th>Product ID</th>
          <th>Product Name</th>
          <th>Product Description</th>
          <th>Price</th>
        </tr>
      </thead>
      <tr v-for="product in products" :key="product.productId">
        <td><router-link :to="`/product/${product.id}`">{{ product.id }}</router-link></td>
        <td>{{ product.name }}</td>
        <td>{{ product.description }}</td>
        <td>{{ product.price }}</td>
      </tr>
    </table>
  </div>
</template>

<script>
  export default {
    name: 'ProductList',
    props: ['products'],
    mounted() {
      this.$emit('getProducts')
    }
  }
</script>

<style scoped>
a {
  color: #0000FF;
  text-decoration: underline;
}

.product-list {
  text-align: left;
}
</style>