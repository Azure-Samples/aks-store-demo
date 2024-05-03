const { defineConfig } = require('@vue/cli-service')
const fetch = require("node-fetch")
const bodyParser = require('body-parser')

const PRODUCT_SERVICE_URL = (process.env.VUE_APP_PRODUCT_SERVICE_URL || "http://172.19.0.2:3002/")
const MAKELINE_SERVICE_URL = (process.env.VUE_APP_MAKELINE_SERVICE_URL || "http://172.19.0.6:3001/")

module.exports = defineConfig({
  transpileDependencies: true,
  devServer: {
    port: 8081,
    host: '0.0.0.0',
    allowedHosts: 'all',
    client: false,
    webSocketServer: false,
    setupMiddlewares: (middlewares, devServer) => {
      
      if (!devServer) {
        throw new Error('webpack-dev-server is not defined');
      }

      devServer.app.use(bodyParser.json())
      
      // Health check
      devServer.app.get('/health', (_, res) => {
        const version = process.env.APP_VERSION || '0.1.0'
        res.send({ status: 'ok', version: version})
      })

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

      // Get a single order by id
      devServer.app.get('/makeline/order/:id', (_, res) => {
        fetch(`${MAKELINE_SERVICE_URL}order/${_.params.id}`)
          .then(response => response.json())
          .then(order => {
            res.send(order)
          })
          .catch(error => {
            console.log(error)
            // alert('Error occurred while fetching products')
          })

      });

      // Manually process an order
      devServer.app.put('/makeline/order', (req, res) => {
        const order = req.body
        console.log(order)

        fetch(`${MAKELINE_SERVICE_URL}order`, {
          method: 'PUT',
          body: JSON.stringify(order),
          headers: { 'Content-Type': 'application/json' }
        })
          .then(response => res.send(response))
          .catch(error => {
            console.log(error)
            // alert('Error occurred while posting order')
          })
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

      // Get AI service health
      devServer.app.get('/ai/health', (_, res) => {
        fetch(`${PRODUCT_SERVICE_URL}ai/health`)
          .then(response => response.json())
          .then(health => {
            res.send(health);
          })
          .catch(error => {
            console.error(error);
            res.status(500).send('Health check failed');
          });
      })

      // Generate product description
      devServer.app.post('/ai/generate/description', (req, res) => {
        console.log('Generating product description')
        const product = req.body
        console.log(product)

        fetch(`${PRODUCT_SERVICE_URL}ai/generate/description`, {
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

      // Generate product image
      devServer.app.post('/ai/generate/image', (req, res) => {
        console.log('Generating product image')
        const product = req.body
        console.log(product)

        fetch(`${PRODUCT_SERVICE_URL}ai/generate/image`, {
          method: 'POST',
          body: JSON.stringify(product),
          headers: { 'Content-Type': 'application/json' }
        })
          .then(response => response.json())
          .then(image => {
            console.log(image);
            res.send(image)
          })
          .catch(error => {
            console.log(error)
          })
      })

      return middlewares;
    }

  }
})
