const { defineConfig } = require('@vue/cli-service')
const fetch = require("node-fetch")
const bodyParser = require('body-parser')

const PRODUCT_SERVICE_URL = (process.env.VUE_APP_PRODUCT_SERVICE_URL || "http://172.19.0.2:3002/")
const ORDER_SERVICE_URL = (process.env.VUE_APP_ORDER_SERVICE_URL || "http://172.19.0.5:3000/")
// const MAKELINE_SERVICE_URL = (process.env.VUE_APP_MAKELINE_SERVICE_URL || "http://172.19.0.6:3001/")
const MAKELINE_SERVICE_URL = (process.env.VUE_APP_MAKELINE_SERVICE_URL || "http://172.19.0.6:3001/")
const AI_SERVICE_URL = (process.env.VUE_APP_AI_SERVICE_URL || "http://172.19.0.6:5001/")

module.exports = defineConfig({
  transpileDependencies: true,
  devServer: {
    port: 8081,
    host: '0.0.0.0',
    allowedHosts: 'all',
    setupMiddlewares: (middlewares, devServer) => {
      
      if (!devServer) {
        throw new Error('webpack-dev-server is not defined');
      }

      devServer.app.use(bodyParser.json())
      
      // Get all orders
      devServer.app.get('/makeline/order/fetch', (_, res) => {
        console.log(MAKELINE_SERVICE_URL)
        fetch(`${MAKELINE_SERVICE_URL}order/fetch`)
        .then(response => response.json())
        .then(orders => {
          res.send(orders)
        })
        .catch(error => console.error(error));

      })


      // Get all products
      devServer.app.get('/products', (_, res) => {
        fetch(`${PRODUCT_SERVICE_URL}`)
          .then(response => response.json())
          .then(products => {
            res.send(products)
          })
          .catch(error => {
            console.log(error)
            // alert('Error occurred while fetching products')
          })
      });

      // Get a single product by id
      devServer.app.get('/product/:id', (_, res) => {
        fetch(`${PRODUCT_SERVICE_URL}${_.params.id}`)
          .then(response => response.json())
          .then(products => {
            res.send(products)
          })
          .catch(error => {
            console.log(error)
            // alert('Error occurred while fetching products')
          })
      });

      // Manually process an order
      devServer.app.post('/order', (req, res) => {
        fetch(`${ORDER_SERVICE_URL}`, {
          method: 'POST',
          body: JSON.stringify(req.body),
          headers: { 'Content-Type': 'application/json' }
        })
          .then(response => response.json())
          .then(order => {
            res.send(order)
          })
          .catch(error => {
            console.log(error)
            // alert('Error occurred while posting order')
          })
      })

      // Get AI service health
      devServer.app.get('/ai/health', (_, res) => {
        fetch(`${AI_SERVICE_URL}health`)
          .then(response => res.send(response.json()))
          .catch(error => console.error(error));
      })

      // Generate product description
      devServer.app.post('/ai/generate/description', (req, res) => {
        console.log('Generating product description')
        const product = req.body
        console.log(product)

        fetch(`${AI_SERVICE_URL}generate/description`, {
          method: 'POST',
          body: JSON.stringify(product),
          headers: { 'Content-Type': 'application/json' }
        })
          .then(response => response.json())
          .then(description => {
            console.log(description);
            res.send(description)
          })
          .catch(error => {
            console.log(error)
          })
      })

      // Add product
      devServer.app.post('/product', (req, res) => {
        console.log('Add product')
        const product = req.body
        console.log(product)

        fetch(`${PRODUCT_SERVICE_URL}`, {
          method: 'POST',
          body: JSON.stringify(product),
          headers: { 'Content-Type': 'application/json' }
        })
          .then(response => response.json())
          .then(product => {
            console.log(product);
            res.send(product)
          })
          .catch(error => {
            console.log(error)
          })
      })

      // Update product
      devServer.app.put('/product', (req, res) => {
        console.log('Update product')
        const product = req.body
        console.log(product)

        fetch(`${PRODUCT_SERVICE_URL}`, {
          method: 'PUT',
          body: JSON.stringify(product),
          headers: { 'Content-Type': 'application/json' }
        })
          .then(response => response.json())
          .then(product => {
            console.log(product);
            res.send(product)
          })
          .catch(error => {
            console.log(error)
          })
      })

      return middlewares;
    }

  }
})
