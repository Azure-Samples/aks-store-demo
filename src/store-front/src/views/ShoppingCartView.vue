<template>
  <div class="shopping-cart" v-if="hasCartItems">
    <h2>Shopping Cart</h2>
    <div class="cart-header">
      <div class="cart-column product-name">Product Name</div>
      <div class="cart-column quantity">Quantity</div>
      <div class="cart-column price">Price</div>
      <div class="cart-column price">Total</div>
    </div>
    <div class="cart-items">
      <div class="cart-item" v-for="item in cartItems" :key="item.product.id">
        <div class="cart-column product-name">{{ item.product.name }}</div>
        <div class="cart-column quantity">
          <div class="quantity-control">
            <button class="remove-button" @click="removeFromCart(item)">X</button>
            <input
              type="number"
              class="quantity-input"
              v-model.number="item.quantity"
              min="1"
              @change="updateQuantity(item)"
            />
            <button class="quantity-btn" @click="incrementQuantity(item)">+</button>
          </div>
        </div>
        <div class="cart-column price">{{ item.product.price.toFixed(2) }}</div>
        <div class="cart-column price">{{ getItemTotal(item) }}</div>
      </div>
    </div>
    <div class="cart-summary">
      <div class="summary-row">
        <span>Subtotal:</span>
        <span>{{ calculateSubtotal().toFixed(2) }}</span>
      </div>
      <div class="summary-row">
        <span>Shipping:</span>
        <span>Free</span>
      </div>
      <div class="summary-row total">
        <span>Total:</span>
        <span>{{ calculateSubtotal().toFixed(2) }}</span>
      </div>
    </div>
    <div class="cart-actions">
      <button class="continue-button" @click="continueShopping">Continue Shopping</button>
      <button class="checkout-button" @click="submitOrder">Proceed to Checkout</button>
    </div>
  </div>
  <div class="shopping-cart empty-cart" v-else>
    <h3>Your shopping cart is empty</h3>
    <button class="continue-button" @click="continueShopping">Continue Shopping</button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useCartStore } from '@/stores'
import { useRouter } from 'vue-router'
import type { CartItem } from '@/types'

const cartStore = useCartStore()
const router = useRouter()

const cartItems = computed(() => cartStore.items)
const hasCartItems = computed(() => cartItems.value.length > 0)

const getItemTotal = (item: CartItem) => (item.product.price * item.quantity).toFixed(2)

const calculateSubtotal = () => {
  return cartItems.value.reduce((total, item) => {
    return total + item.product.price * item.quantity
  }, 0)
}

const updateQuantity = (item: CartItem) => {
  // Ensure quantity is at least 1
  if (item.quantity < 1) {
    item.quantity = 1
  }
}

const incrementQuantity = (item: CartItem) => {
  item.quantity++
  updateQuantity(item)
}

const removeFromCart = (item: CartItem) => {
  cartStore.removeItem(item.product.id)
}

const continueShopping = () => {
  router.push('/')
}

const submitOrder = () => {
  const order = {
    customerId: Math.floor(Math.random() * 10000000000).toString(),
    items: cartItems.value.map((item) => ({
      productId: item.product.id,
      quantity: item.quantity,
      price: item.product.price,
    })),
  }

  fetch('/api/orders', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(order),
  })
    .then((response) => {
      if (response.ok) {
        cartStore.clear()
        alert('Order submitted successfully')
      } else {
        alert('Error occurred while submitting order')
      }
    })
    .catch((error) => {
      console.error('Error submitting order:', error)
      alert('Error occurred while submitting order')
    })
}
</script>

<style scoped>
.shopping-cart {
  display: flex;
  flex-direction: column;
  align-items: center;
  width: 100%;
  max-width: 95vw;
  margin: 0 auto;
  padding: 20px;
}

/* Force same container width */
.cart-items {
  width: 100%;
}

/* Grid layout for consistent alignment */
.cart-header,
.cart-item {
  display: grid;
  grid-template-columns: 3fr 1.3fr 1fr 1fr;
  width: 100%;
  padding: 12px 0;
  border-bottom: 1px solid #ddd;
  align-items: center;
  box-sizing: border-box;
}

.cart-item:hover {
  background-color: rgba(0, 123, 255, 0.1);
}

.cart-header {
  font-weight: bold;
  background-color: var(--primary-color, #f8f9fa);
  color: var(--secondary-color, #333);
  border-radius: var(--border-radius) var(--border-radius) 0 0;
}

.cart-column {
  padding: 0 10px;
  box-sizing: border-box;
}

.product-name {
  text-align: left;
}

.quantity {
  text-align: center;
  justify-self: center;
  display: flex;
  flex-direction: column;
  align-items: center;
}

.price {
  text-align: right;
  justify-self: end;
}

.cart-header .quantity {
  text-align: center;
  justify-self: center;
}
.remove {
  text-align: center;
  justify-self: center;
}

.remove-button {
  background-color: #dc3545;
  color: white;
  border: none;
  border-radius: 4px;
  padding: 5px 10px;
  cursor: pointer;
  min-width: 30px;
  margin-left: 4px;
  height: 30px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.remove-button:hover {
  background-color: #c82333;
}

.cart-summary {
  width: 100%;
  max-width: 400px;
  margin: 20px 0;
  padding: 15px;
  align-self: flex-end;
}

.summary-row {
  display: flex;
  justify-content: space-between;
  margin-bottom: 10px;
}

.total {
  font-weight: bold;
  font-size: 1.2rem;
  margin-top: 10px;
  border-top: 1px solid #ddd;
  padding-top: 10px;
}

.cart-actions {
  display: flex;
  justify-content: space-between;
  width: 100%;
  max-width: 500px;
  margin-top: 20px;
}

.cart-actions button {
  padding: 12px 20px;
  border-radius: var(--border-radius);
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
}

.continue-button {
  background-color: var(--primary-color);
  margin-right: 10px;
  color: white;
}

.continue-button:hover {
  background-color: #444;
}

.checkout-button {
  background-color: var(--accent-color-dark);
  color: var(--secondary-color);
}

.checkout-button:hover {
  background-color: var(--accent-color);
}

.empty-cart {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
}

.empty-cart h3 {
  margin-bottom: 20px;
}

.quantity-control {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  width: 100%;
}

.quantity-input {
  width: 40px;
  text-align: center;
  border: 1px solid #ddd;
  border-radius: 4px;
  padding: 4px;
  margin: 0 5px;
  -moz-appearance: textfield; /* Firefox */
}

/* Remove increment/decrement arrows from number input */
.quantity-input::-webkit-outer-spin-button,
.quantity-input::-webkit-inner-spin-button {
  -webkit-appearance: none;
  margin: 0;
}

.quantity-btn {
  width: 30px;
  height: 30px;
  border-radius: 4px;
  border: 1px solid #ccc;
  background-color: #f0f0f0;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: bold;
  font-size: 16px;
  color: #333;
}

.quantity-btn:hover:not(:disabled) {
  background-color: #e0e0e0;
  border-color: #999;
}

.quantity-btn:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
