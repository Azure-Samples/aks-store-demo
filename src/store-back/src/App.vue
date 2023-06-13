<template>
  <TopNav />
  <router-view
    :orders="orders"
    :products="products"
    @fetchOrders="fetchOrders"
    @completeOrder="completeOrder"
    @updateProduct="updateProduct"
  ></router-view>
</template>

<script>
import TopNav from './components/TopNav.vue';
import products from './products'

export default {
  name: 'App',
  components: {
    TopNav
  },
  data() {
    return {
      orders: [],
      products,
    }
  },
  methods: {
    async fetchOrders() {
      const makelineServiceUrl = process.env.MAKELINE_SERVICE_URL || 'http://localhost:3001/';

      await fetch(`${makelineServiceUrl}order/fetch`)
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
            this.orders = data;
          } else {
            console.log('No orders from server');
          }
        })
        .catch(error => console.error(error));
    },
    async completeOrder(orderId) {
      const makelineServiceUrl = process.env.MAKELINE_SERVICE_URL || 'http://localhost:3001/';
      
      // get the order and update the status
      let order = this.orders.find(order => order.orderId === orderId);
      order.status = 1;

      let orderObject = JSON.stringify(order)
      console.log(orderObject);

      await fetch(`${makelineServiceUrl}order`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json'
        },
        body: orderObject
      })
        .then(response => {
          if (!response.ok) {
            alert('Error occurred while processing order')
          } else {
            alert('Order successfully processed')
            // remove the order from the list
            this.orders = this.orders.filter(order => order.orderId !== orderId);
            this.$router.go(-1);
          }
        })
        .catch(error => {
          console.log(error)
          alert('Error occurred while processing order')
        })
    },
    async updateProduct(product) {
      console.log(product);
      alert('Not wired up yet');
    }
  },
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}
</style>


<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-align: center;
  color: #2c3e50;
  margin-top: 60px;
}

footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background-color: #333;
  color: #fff;
  padding: 1rem;
  margin: 0;
}

nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

ul {
  display: flex;
  list-style: none;
  margin: 0;
  padding: 0;
}

li {
  margin: 0 1rem;
}

a {
  color: #fff;
  text-decoration: none;
}

table {
  width: 100%;
  border-collapse: collapse;
  border-spacing: 0;
}

th,
td {
  padding: 8px;
  text-align: left;
  border-bottom: 1px solid #ddd;
}

.order-detail {
  text-align: left;
}

.button {
  margin-top: 20px;
  padding: 10px 20px;
  background-color: #007acc;
  color: #fff;
  border: none;
  border-radius: 5px;
  cursor: pointer;
}

.button:hover {
  background-color: #005f8b;
}
</style>
