<template>
  <div class="order-detail" v-if="orderExists">
    <div class="action-button">
      <button @click="completeOrder" class="button">Complete Order</button>
    </div>
    <br/>
    <p><b>Order ID:</b> {{ order.orderId }}</p>
    <p><b>Customer ID:</b> {{ order.customerId }}</p>
    <p><b>Status:</b> {{ order.status }}</p>
    <p>
      <table>
        <thead>
          <tr>
            <th>Product ID</th>
            <th>Quantity</th>
            <th>Price</th>
          </tr>
        </thead>
        <tr v-for="item in order.items" :key="item.productId">
          <td>{{ item.productId }}</td>
          <td>{{ item.quantity }}</td>
          <td>{{ item.price }}</td>
        </tr>
      </table>
    </p>
  </div>
  <div class="order-detail" v-else>
    <h3>Opps! That order was not found...</h3>
  </div>
</template>

<script>
  export default {
    name: 'OrderDetail',
    props: ['orders'],
    emits: ['completeOrder'],
    data() {
      return {
        order: null
      }
    },
    computed: {
      orderExists() {
        return !!this.order
      }
    },
    mounted() {
      this.getOrder()
    },
    methods: {
      getOrder() {
        // get the order from the orders prop
        // if not found in the orders prop, fetch from the server
        this.order = this.orders.find(order => order.orderId === this.$route.params.id);  
        
        if (!this.order) {          
          // return this.orders.find(order => order.orderId === this.$route.params.id);
          // get the order from the makeline service
          const makelineServiceUrl = process.env.MAKELINE_SERVICE_URL || 'http://localhost:3001/';

          fetch(`${makelineServiceUrl}order/${this.$route.params.id}`)
            .then(response => {
              if (!response.ok) {
                throw new Error('Network response was not ok');
              }
              // check if the response is empty
              if (response.status === 204) {
                return null;
              }
              return response.json();
            })
            .then(data => {
              if (data) {
                this.order = data;
              } else {
                console.log('No orders from server');
              }
            })
            .catch(error => console.error(error));
        }
        
        return this.order;
      },
      completeOrder() {
        this.$emit('completeOrder', this.order.orderId)
      }
    }
  }
</script>

<style scoped>
.order-detail {
  margin: 2rem auto;
  text-align: left;
}
</style>