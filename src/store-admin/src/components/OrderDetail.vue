<template>
  <div class="order-detail" v-if="orderExists">
    <div class="action-button">
      <button @click="completeOrder" class="button">Complete Order</button>
    </div>
    <br/>
    <div class="order-header">
      <p><b>Order ID:</b> {{ order.orderId }}</p>
      <p><b>Customer ID:</b> {{ order.customerId }}</p>
      <p><b>Status:</b> {{ order.status }}</p>
    </div>
    <div class="order-items">
      <table>
        <thead>
          <tr>
            <th>Product ID</th>
            <th>Product Name</th>
            <th>Quantity</th>
            <th>Price</th>
            <th>Total</th>
          </tr>
        </thead>
        <tr v-for="item in order.items" :key="item.productId">
          <td><router-link :to="`/product/${item.productId}`">{{ item.productId }}</router-link></td>
          <td>{{ productLookup(item.productId) }}</td>
          <td>{{ item.quantity }}</td>
          <td>{{ item.price.toFixed(2) }}</td>
          <td>{{ (item.quantity * item.price).toFixed(2) }}</td>
        </tr>
        <tfoot>
          <tr>
            <td></td>
            <td></td>
            <td></td>
            <td></td>
            <td><b>{{ orderTotal() }}</b></td>
          </tr>
        </tfoot>
      </table>
    </div>
  </div>
  <div class="order-detail" v-else>
    <h3>Opps! That order was not found...</h3>
  </div>
</template>

<script>
  export default {
    name: 'OrderDetail',
    props: ['orders','products'],
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
          // get the order from the makeline service
          fetch(`/makeline/order/${this.$route.params.id}`)
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
      },
      productLookup(id) {
        return this.products.find(product => product.id === id).name;
      },
      orderTotal() {
        let total = 0;
        this.order.items.forEach(item => {
          total += item.price * item.quantity;
        });
        return total.toFixed(2);
      }
    }
  }
</script>

<style scoped>
a {
  color: #0000FF;
  text-decoration: underline;
}

.order-detail {
  text-align: left;
}
</style>