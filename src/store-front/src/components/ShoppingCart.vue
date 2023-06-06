<template>
  <div class="shopping-cart" v-if="hasCartItems">
    <table class="shopping-cart-table">
      <thead>
        <tr>
          <th>Item</th>
          <th>Quantity</th>
          <th>Price</th>
          <th>Total</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in cartItems" :key="item.product.id">
          <td>{{ item.product.name }}</td>
          <td>{{ item.quantity }}</td>
          <td>{{ item.product.price }}</td>
          <td>{{ getItemTotal(item) }}</td>
          <td><button @click="removeFromCart(item)">Remove</button></td>
        </tr>
      </tbody>
    </table>
    <button class="checkout-button" @click="submitOrder">Checkout</button>
  </div>
  <div class="shopping-cart" v-else>
    <h3>Your shopping cart is empty</h3>
  </div>
</template>

<script>
export default {
  name: 'ShoppingCart',
  props: ['cartItems'],
  computed: {
    hasCartItems() {
      return this.cartItems.length > 0
    },
  },
  methods: {
    getItemTotal(item) {
      const quantity = item.quantity
      const price = item.product.price
      const total = quantity * price
      return total.toFixed(2)
    },
    removeFromCart(item) {
      const index = this.cartItems.indexOf(item)
      if (index > -1) {
        this.$emit('removeFromCart', index)
      }
    },
    submitOrder() {
      this.$emit('submitOrder')
    }
  }
}
</script>
