<template>
  <div id="app">
    <TopNav :cartItemCount="cartItemCount"/>
    <router-view
      :products="products"
      :cartItems="cartItems"
      @addToCart="addToCart"
      @removeFromCart="removeFromCart"
      @submitOrder="submitOrder"
    ></router-view>

    <!-- Alerta Simples -->
    <div v-if="showAlert" class="alert">
      {{ alertMessage }}
    </div>
  </div>
</template>

<script>
import TopNav from './components/TopNav.vue'

export default {
  name: 'App',
  components: {
    TopNav
  },
  data() {
    return {
      cartItems: [],
      products: [],
      showAlert: false, // Controla a exibição do alerta
      alertMessage: ''  // Mensagem do alerta
    }
  },
  computed: {
    cartItemCount() {
      return this.cartItems.reduce((total, item) => {
        return total + item.quantity
      }, 0)
    }
  },
  mounted() {
    this.getProducts()
  },
  methods: {
    getProducts() {
      fetch('/products')
        .then(response => response.json())
        .then(products => {
          console.log('success getting proxy products')
          this.products = products
        })
        .catch(error => {
          console.log(error)
          this.showAlertMessage('Error occurred while fetching products')
        })
    },
    addToCart({ productId, quantity }) {
      const existingCartItem = this.cartItems.find(
        item => item.product.id == productId
      )
      if (existingCartItem) {
        existingCartItem.quantity += quantity
      } else {
        const product = this.products.find(product => product.id == productId)
        this.cartItems.push({ product, quantity })
      }
      // Exibe o alerta ao adicionar um item ao carrinho
      this.showAlertMessage('Product added to cart!')
    },
    removeFromCart(index) {
      this.cartItems.splice(index, 1)
      this.showAlertMessage('Product removed from cart!')
    },
    submitOrder() {
      const order = {
        customerId: Math.floor(Math.random() * 10000000000).toString(),
        items: this.cartItems.map(item => {
          return {
            productId: item.product.id,
            quantity: item.quantity,
            price: item.product.price
          }
        })
      }

      fetch(`/order`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify(order)
      })
        .then(response => {
          console.log(response)
          if (!response.ok) {
            this.showAlertMessage('Error occurred while submitting order')
          } else {
            this.cartItems = []
            this.showAlertMessage('Order submitted successfully')
          }
        })
        .catch(error => {
          console.log(error)
          this.showAlertMessage('Error occurred while submitting order')
        })
    },
    // Método para exibir o alerta
    showAlertMessage(message) {
      this.alertMessage = message
      this.showAlert = true
      setTimeout(() => {
        this.showAlert = false
      }, 3000) // O alerta desaparece após 3 segundos
    }
  }
}
</script>

<style>
#app {
  font-family: Avenir, Helvetica, Arial, sans-serif;
  text-align: center;
  color: #2c3e50;
  margin-top: 120px;
}

/* Estilo simples para o alerta */
.alert {
  background-color: #f44336; /* Cor de fundo do alerta */
  color: white;
  padding: 15px;
  margin: 20px;
  border-radius: 5px;
  text-align: center;
}

.alert.fade {
  opacity: 0;
  transition: opacity 0.5s ease-out;
}
</style>
