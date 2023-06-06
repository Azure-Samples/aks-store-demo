<template>
  <br>
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
          <b>Price: <span class="price">{{ product.price }}</span></b>
        </p>
        <input type="number" v-model="quantity" min="1" class="quantity-input" />
        <button @click="addToCart">Add to Cart</button>
      </div>
    </div>
  </div>
  <div class="product-detail" v-else>
    <img src="../assets/404.jpg" alt="Product not found" />
    <h3>Opps! That product was not found...</h3>
  </div>
</template>

<script>
export default {
  name: 'ProductDetail',
  props: ['products'],
  data() {
    return {
      quantity: 1
    }
  },
  computed: {
    product() {
      return this.products.find(product => product.id == this.$route.params.id);
    },
    productExists() {
      return !!this.product;
    }
  },
  methods: {
    addToCart() {
      // Add the product and quantity to the cart
      this.$emit('addToCart', {
        productId: this.product.id,
        quantity: this.quantity
      })
    }
  }
}
</script>