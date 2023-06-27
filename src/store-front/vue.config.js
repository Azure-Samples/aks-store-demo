const { defineConfig } = require('@vue/cli-service')
const fetch = require("node-fetch")

const PRODUCT_SERVICE_URL = (process.env.VUE_APP_PRODUCT_SERVICE_URL || "http://172.19.0.2:3002/")
const ORDER_SERVICE_URL = (process.env.VUE_APP_ORDER_SERVICE_URL || "http://172.19.0.5:3000/")

module.exports = defineConfig({
  transpileDependencies: true,
  devServer: {
    port: 8080,
    host: '0.0.0.0',
    allowedHosts: 'all',
    
    setupMiddlewares: (middlewares, devServer) => {
      
      if (!devServer) {
        throw new Error('webpack-dev-server is not defined');
      }

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

      return middlewares;
    }

  }
})
