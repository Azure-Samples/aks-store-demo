<template>
  <div class="action-button">
    <button @click="saveProduct" class="button">Save Product</button>
  </div>
  <br/>
  <div class="product-form">
    <div class="form-row">
      <label for="product-id">ID</label>
      <input id="product-id" placeholder="Product ID" v-model="product.id" />
    </div>

    <div class="form-row">
      <label for="product-name">Name</label>
      <input id="product-name" placeholder="Product Name" v-model="product.name" />
    </div>

    <div class="form-row">
      <label for="product-price">Price</label>
      <input id="product-price" placeholder="Product Price" v-model="product.price" />
    </div>

    <div class="form-row">
      <label for="product-tags">Keywords</label>
      <input id="product-tags" placeholder="Product Keywords" v-model="product.tags" />
    </div>

    <div class="form-row">
      <label for="product-description">Description</label>
      <textarea id="product-description" placeholder="Product Description" v-model="product.description" />
      <button @click="generateDescription" class="ai-button">Ask OpenAI</button>
    </div>  

    <div class="form-row">
      <label for="product-image">Image</label>
      <input id="product-image" placeholder="Product Image" v-model="product.image" />
    </div>
  </div>
</template>

<script>
  export default {
    name: 'ProductForm',
    props: ['products'],
    emits: ['addProductsToList','updateProductInList'],
    data() {
      return {
        product: {
          id: 0,
          name: '',
          image: 'https://via.placeholder.com/400x400?text=Placeholder',
          description: '',
          price: 0.00,
          tags: []
        }
      }
    },
    mounted() {
      // if we're editing a product, get the product details
      if (this.$route.params.id) {
        // get the product from the products list
        const product = this.products.find(product => product.id == this.$route.params.id)
        // copy the product details into the product object
        this.product = Object.assign({}, product);
      } else {
        // disable the product id textbox
        document.getElementById('product-id').disabled = true;
      }
    },
    methods: {
      generateDescription() {
        // ensure the tag has a value
        if (this.product.tags.length === 0) {
          alert('Please enter a value for the keywords field')
          return;
        }

        const intervalId = this.waitForAI();

        // get the ai-service URL from an environment variable
        const aiServiceUrl = process.env.AI_SERVICE_URL || 'http://localhost:5001/';

        let requestBody = {
          name: this.product.name,
          tags: this.product.tags.split(',').map(tag => tag.trim())
        }

        console.log(requestBody);
        this.product.description = "";

        // call the ai-service using fetch
        fetch(`${aiServiceUrl}generate/description`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(requestBody)
        })
          .then(response => response.json())
          .then(product => {
            this.product.description = product.description
          })
          .catch(error => {
            console.log(error)
            alert('Error occurred while generating product description')
          })
          .finally(() => {
            clearInterval(intervalId);
          })
      },
      waitForAI() {
        let dots = '';
        const intervalId = setInterval(() => {
          dots += '.';
          this.product.description = `Thinking${dots}`;
        }, 500);
        return intervalId;
      },
      saveProduct() {
        // get the product-service URL from an environment variable
        const productServiceUrl = process.env.PRODUCT_SERVICE_URL || 'http://localhost:3002/';

        // default to updates
        let method = 'PUT';

        // get the path of the current request
        let path = this.$route.path;
        if (path.includes('add')) {
          method = 'POST';
        }

        // ensure product.price is not wrapped in quotes
        this.product.price = parseFloat(this.product.price);

        // upsert the product
        fetch(`${productServiceUrl}`, {
          method: method,
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(this.product)
        })
          .then(response => response.json())
          .then(product => {
            alert('Product saved successfully')            
            // update or add the product to the list
            if (method === 'PUT') {
              this.$emit('updateProductInList', this.product);
            } else {
              this.$emit('addProductsToList', product);
            }
            // route to product detail
            this.$router.push(`/product/${product.id}`);
          })
          .catch(error => {
            console.log(error)
            alert('Error occurred while saving product')
          })
      }
    }
  }
</script>