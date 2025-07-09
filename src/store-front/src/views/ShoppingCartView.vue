<template>
  <div class="shopping-cart-container" v-if="hasCartItems">
    <div class="cart-items-container">
      <div class="cart-header">
        <div class="cart-column product-name">Product Name</div>
        <div class="cart-column quantity">Quantity</div>
        <div class="cart-column price">Price</div>
        <div class="cart-column total">Total</div>
      </div>

      <div class="cart-items">
        <div class="cart-item" v-for="item in cartItems" :key="item.product.id">
          <div class="cart-column product-name">
            <router-link :to="`/product/${item.product.id}`">{{
              item.product.name
            }}</router-link>
          </div>
          <div class="cart-column quantity">
            <div class="quantity-control">
              <button class="remove-button" @click="removeFromCart(item)">
                X
              </button>
              <input
                type="number"
                class="quantity-input"
                v-model.number="item.quantity"
                min="1"
                @change="updateQuantity(item)"
              />
              <button class="quantity-btn" @click="incrementQuantity(item)">
                +
              </button>
            </div>
          </div>
          <div class="cart-column price">
            {{ item.product.price.toFixed(2) }}
          </div>
          <div class="cart-column total">
            {{ getItemTotal(item) }}
          </div>
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
    </div>
    <div class="cart-actions">
      <button class="continue-button" @click="continueShopping">
        Continue Shopping
      </button>
      <button class="checkout-button" @click="submitOrder">
        Proceed to Checkout
      </button>
    </div>
  </div>
  <div class="shopping-cart empty-cart" v-else>
    <h3>Your shopping cart is empty</h3>
    <button class="continue-button" @click="continueShopping">
      Continue Shopping
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useCartStore } from "@/stores";
import { useRouter } from "vue-router";
import type { CartItem } from "@/types";

const cartStore = useCartStore();
const router = useRouter();

const cartItems = computed(() => cartStore.items);
const hasCartItems = computed(() => cartItems.value.length > 0);

const getItemTotal = (item: CartItem) =>
  (item.product.price * item.quantity).toFixed(2);

const calculateSubtotal = () => {
  return cartItems.value.reduce((total, item) => {
    return total + item.product.price * item.quantity;
  }, 0);
};

const updateQuantity = (item: CartItem) => {
  // Ensure quantity is at least 1
  if (item.quantity < 1) {
    item.quantity = 1;
  }
};

const incrementQuantity = (item: CartItem) => {
  item.quantity++;
  updateQuantity(item);
};

const removeFromCart = (item: CartItem) => {
  cartStore.removeItem(item.product.id);
};

const continueShopping = () => {
  router.push("/");
};

const submitOrder = () => {
  const order = {
    customerId: Math.floor(Math.random() * 10000000000).toString(),
    items: cartItems.value.map((item) => ({
      productId: item.product.id,
      quantity: item.quantity,
      price: item.product.price,
    })),
  };

  fetch("/api/orders", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(order),
  })
    .then((response) => {
      if (response.ok) {
        cartStore.clear();
        alert("Order submitted successfully");
      } else {
        alert("Error occurred while submitting order");
      }
    })
    .catch((error) => {
      console.error("Error submitting order:", error);
      alert("Error occurred while submitting order");
    });
};
</script>

<style scoped>
.shopping-cart-container {
  display: flex;
  flex-direction: column;
  width: 95vw;
  margin: 2rem auto;
  padding: 20px;
}

.shopping-cart.empty-cart {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 40px 20px;
}

.cart-header-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  width: 100%;
  margin-bottom: 20px;
}

.cart-info {
  text-align: left;
}

.cart-info h2 {
  margin-top: 0;
  margin-bottom: 15px;
}

.status-pending {
  color: #f39c12;
  font-weight: bold;
}

.status-completed {
  color: #2ecc71;
  font-weight: bold;
}

.complete-button {
  background-color: var(--accent-color-dark, #007bff);
  color: white;
  border: none;
  border-radius: var(--border-radius, 4px);
  padding: 12px 20px;
  cursor: pointer;
  font-weight: bold;
  transition: all 0.2s ease;
}

.complete-button:hover {
  background-color: var(--accent-color, #0056b3);
}

.cart-items-container {
  background-color: var(--card-background, white);
  border-radius: var(--border-radius, 4px);
  box-shadow: var(--shadow, 0 2px 8px rgba(0, 0, 0, 0.1));
  width: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.cart-header {
  display: grid;
  grid-template-columns: 1fr 0.5fr 0.5fr 0.5fr;
  width: 100%;
  background-color: var(--primary-color, #f8f9fa);
  font-weight: bold;
  color: var(--secondary-color, #333);
  border-bottom: 1px solid #ddd;
  padding: 12px 0;
}

.cart-items {
  width: 100%;
}

.cart-item {
  display: grid;
  grid-template-columns: 1fr 0.5fr 0.5fr 0.5fr;
  width: 100%;
  border-bottom: 1px solid #eee;
  align-items: center;
  padding: 10px 0;
}

.cart-item:hover {
  background-color: rgba(0, 123, 255, 0.05);
}

.cart-column {
  padding: 0 12px;
}

.product-name {
  text-align: left;
}

.product-name a {
  color: var(--accent-color-dark, #007bff);
  text-decoration: none;
}

.product-name a:hover {
  text-decoration: underline;
}

.product-name {
  text-align: left;
}

.quantity {
  text-align: center;
}

.price {
  text-align: right;
}

.total {
  text-align: right;
  font-weight: bold;
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

.summary-row.total {
  font-weight: bold;
  font-size: 1.2rem;
  margin-top: 10px;
  border-top: 1px solid #ddd;
  padding-top: 10px;
}

@media (max-width: 768px) {
  .cart-header,
  .cart-item {
    grid-template-columns: 1fr 1.5fr 0.8fr 0.8fr 0.8fr;
    font-size: 0.9rem;
  }

  .cart-header-section {
    flex-direction: column;
  }

  .action-button {
    margin-top: 15px;
    align-self: flex-start;
  }
}

.cart-actions {
  display: flex;
  justify-content: flex-end;
  margin-top: 20px;
}

.cart-actions button {
  padding: 12px 20px;
  border-radius: var(--border-radius);
  border: none;
  cursor: pointer;
  transition: all 0.2s ease;
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
