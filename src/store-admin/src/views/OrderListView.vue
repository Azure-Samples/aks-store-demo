<template>
  <!-- <div v-if="isLoading" class="loading-container">
    <div class="loading-spinner"></div>
    <p>Fetching orders...</p>
  </div> -->

  <div v-if="hasOrders" class="order-table">
    <!-- Column headers -->
    <div class="table-header">
      <div class="column-id">Order ID</div>
      <div class="column-customer">Customer ID</div>
      <div class="column-status">Status</div>
      <div class="column-price">Total</div>
    </div>

    <!-- Order rows -->
    <div
      v-for="order in orders"
      :key="order.orderId"
      class="table-row clickable"
      @click="routeToOrder(order.orderId)"
    >
      <div class="column-id">{{ order.orderId }}</div>
      <div class="column-customer">{{ order.customerId }}</div>
      <div class="column-status">{{ order.status === 0 ? 'Pending' : 'Completed' }}</div>
      <div class="column-price">{{ orderTotal(order) }}</div>
    </div>
  </div>

  <!-- <div class="empty-list" v-else>
    <h3>No orders available</h3>
  </div> -->
  <div v-else class="loading-container">
    <div class="loading-spinner"></div>
    <p>Fetching orders...</p>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useOrderStore } from '@/stores'
import { useRouter } from 'vue-router'
import type { Order } from '@/types'

const orderStore = useOrderStore()
const router = useRouter()

// const isLoading = computed(() => !orderStore.initialized)
const orders = computed(() => orderStore.orders)
const hasOrders = computed(() => orders.value.length > 0)

const orderTotal = (order: Order) => {
  return order.items.reduce((total, item) => total + item.quantity * item.price, 0).toFixed(2)
}

const routeToOrder = (orderId: string | number | undefined) => {
  if (!orderId) {
    console.warn('Cannot navigate to order with undefined ID')
    return
  }
  router.push(`/order/${orderId}`)
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

.order-table {
  background-color: var(--card-background);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
  overflow: hidden;
  width: 95vw;
  margin: 2rem auto;
}

.table-header,
.table-row {
  display: grid;
  grid-template-columns: 0.5fr 1fr 2.5fr 0.5fr;
  align-items: center;
  padding: 0.5rem 1rem;
}

.table-header {
  background-color: var(--primary-color);
  color: var(--secondary-color);
  font-weight: bold;
}

.table-row {
  border-bottom: 1px solid #eee;
}

.table-row:last-child {
  border-bottom: none;
}

.clickable {
  cursor: pointer;
  transition: background-color 0.2s;
}

.table-row:hover {
  background-color: rgba(0, 123, 255, 0.1);
}

.column-id {
  text-align: left;
}

.column-price {
  text-align: right;
}

/* .empty-list {
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

@media (max-width: 768px) {
  .page-container {
    width: 95%;
    padding: 0 1rem;
  }

  .table-header,
  .table-row {
    grid-template-columns: 0.2fr 1fr 2.5fr 0.5fr;
    font-size: 0.9rem;
  }
} */
</style>
