<template>
  <div class="order-detail-container" v-if="orderExists">
    <div class="order-header-section">
      <div class="order-info">
        <h2>Order Details</h2>
        <p><b>Order ID:</b> {{ order?.orderId }}</p>
        <p><b>Customer ID:</b> {{ order?.customerId }}</p>
        <p>
          <b>Status: </b>
          <span :class="order?.status === 0 ? 'status-pending' : 'status-completed'">
            {{ order?.status === 0 ? 'Pending' : 'Completed' }}
          </span>
        </p>
      </div>
      <div class="action-button" v-if="order?.status === 0">
        <button @click="completeOrder" class="complete-button">Complete Order</button>
      </div>
    </div>

    <div class="order-items-container">
      <div class="order-header">
        <div class="order-column product-id">Product ID</div>
        <div class="order-column product-name">Product Name</div>
        <div class="order-column quantity">Quantity</div>
        <div class="order-column price">Price</div>
        <div class="order-column total">Total</div>
      </div>

      <div class="order-items">
        <div class="order-item" v-for="item in order?.items" :key="item.productId">
          <div class="order-column product-id">
            <router-link :to="`/product/${item.productId}`">{{ item.productId }}</router-link>
          </div>
          <div class="order-column product-name">{{ productLookup(item.productId) }}</div>
          <div class="order-column quantity">{{ item.quantity }}</div>
          <div class="order-column price">{{ item.price.toFixed(2) }}</div>
          <div class="order-column total">{{ (item.quantity * item.price).toFixed(2) }}</div>
        </div>
      </div>

      <div class="order-summary">
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
  </div>

  <div class="loading-container" v-else>
    <div class="loading-spinner"></div>
    <h3>Fetching order details...</h3>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useProductStore, useOrderStore } from '@/stores'

const productStore = useProductStore()
const orderStore = useOrderStore()
const route = useRoute()
const router = useRouter()
const orderId = computed(() => route.params.id)

const order = computed(() => {
  return orderStore.orders.find((order) => order.orderId == orderId.value)
})

const orderExists = computed(() => !!order.value)

const calculateSubtotal = () => {
  if (!order.value) return 0
  return order.value?.items.reduce((total, item) => {
    return total + item.price * item.quantity
  }, 0)
}

const productLookup = (productId: string | number) => {
  return productStore.products.find((product) => product.id == productId)?.name
}

const completeOrder = () => {
  if (order.value) {
    console.log(`Completing order ${order.value?.orderId}`)

    const foundOrder = orderStore.orders.find((o) => o.orderId == order.value?.orderId)

    if (foundOrder) {
      foundOrder.status = 1
      fetch(`/api/makeline/order`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(foundOrder),
      })
        .then((response) => {
          if (response.ok) {
            orderStore.removeOrder(foundOrder)
            alert('Order successfully processed')
            router.push('/')
          } else {
            alert('Error occurred while processing order')
          }
        })
        .catch((error) => {
          console.log(error)
          alert('Error occurred while processing order')
        })
    }
  }
}
</script>

<style scoped>
.loading-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 200px;
  background-color: var(--card-background);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
  margin: 2rem auto;
  width: 95vw;
}

.loading-spinner {
  width: 40px;
  height: 40px;
  border: 4px solid rgba(0, 0, 0, 0.1);
  border-left-color: var(--primary-color);
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin-bottom: 1rem;
}

@keyframes spin {
  to {
    transform: rotate(360deg);
  }
}

.order-detail-container {
  display: flex;
  flex-direction: column;
  width: 95vw;
  margin: 2rem auto;
  padding: 20px;
}

.order-header-section {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  width: 100%;
  margin-bottom: 20px;
}

.order-info {
  text-align: left;
}

.order-info h2 {
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

.order-items-container {
  background-color: var(--card-background, white);
  border-radius: var(--border-radius, 4px);
  box-shadow: var(--shadow, 0 2px 8px rgba(0, 0, 0, 0.1));
  width: 100%;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  align-items: flex-end;
}

.order-header {
  display: grid;
  grid-template-columns: 0.5fr 1fr 0.5fr 0.5fr 0.5fr;
  width: 100%;
  background-color: var(--primary-color, #f8f9fa);
  font-weight: bold;
  color: var(--secondary-color, #333);
  border-bottom: 1px solid #ddd;
  padding: 12px 0;
}

.order-items {
  width: 100%;
}

.order-item {
  display: grid;
  grid-template-columns: 0.5fr 1fr 0.5fr 0.5fr 0.5fr;
  width: 100%;
  border-bottom: 1px solid #eee;
  align-items: center;
  padding: 10px 0;
}

.order-item:hover {
  background-color: rgba(0, 123, 255, 0.05);
}

.order-column {
  padding: 0 12px;
}

.product-id {
  text-align: left;
}

.product-id a {
  color: var(--accent-color-dark, #007bff);
  text-decoration: none;
}

.product-id a:hover {
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

.order-summary {
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
  .order-header,
  .order-item {
    grid-template-columns: 1fr 1.5fr 0.8fr 0.8fr 0.8fr;
    font-size: 0.9rem;
  }

  .order-header-section {
    flex-direction: column;
  }

  .action-button {
    margin-top: 15px;
    align-self: flex-start;
  }
}
</style>
