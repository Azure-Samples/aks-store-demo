<template>
  <div class="order-list" v-if="hasOrders">
    <table>
      <thead>
        <tr>
          <th>Order ID</th>
          <th>Customer ID</th>
          <th>Status</th>
        </tr>
      </thead>
      <tr v-for="order in orders" :key="order.orderId">
        <td><router-link :to="`/order/${order.orderId}`">{{ order.orderId }}</router-link></td>
        <td>{{ order.customerId }}</td>
        <td>{{ order.status }}</td>
      </tr>
    </table>
  </div>
  <div class="order-list" v-else>
    <h3>No orders to process</h3>
  </div> 
</template>

<script>
  export default {
    name: 'OrderList',
    props: ['orders'],
    emits: ['fetchOrders', 'completeOrder'],
    computed: {
      hasOrders() {
        return this.orders.length > 0
      },
    },
    methods: {
      fetchOrders() {
        this.$emit('fetchOrders')
      }
    },
    beforeMount() {
      this.fetchOrders()
    }
  }
</script>

<style scoped>
/* a tag styles */
a {
  color: #0000FF;
  text-decoration: underline;
}

.order-list {
  margin: 2rem auto;
  text-align: left;
}
</style>