<template>
  <div class="action-button">
    <button @click="saveProduct" class="button">Save Product</button>
  </div>
  <br/>
  <div v-if="showValidationErrors" class="error">
    <br/>
    <ul v-for="error in validationErrors" :key="error">
      <li>{{ error }}</li>
    </ul>
  </div>
  <div class="product-form">
    <table>
      <tr>
        <td><label for="product-name">Name</label></td>
        <td><input id="product-name" placeholder="Product Name" v-model="product.name" /></td>
        <td></td>
      </tr>

      <tr>
        <td><label for="product-price">Price</label></td>
        <td><input id="product-price" placeholder="Product Price" v-model="product.price" type="number" step="0.01" /></td>
        <td></td>
      </tr>

      <tr>
        <td><label for="product-tags">Keywords</label></td>
        <td><input id="product-tags" placeholder="Product Keywords" v-model="product.tags" /></td>
        <td></td>
      </tr>

      <tr>
        <td><label for="product-description">Description</label></td>
        <td>
          <textarea rows="8" id="product-description" placeholder="Product Description" v-model="product.description" />
          <input type="hidden" id="product-id" placeholder="Product ID" v-model="product.id" />
        </td>
        <td>
          <button @click="generateDescription" class="ai-button">Ask AI Assistant</button>
        </td>
      </tr>

      <tr>
        <td><label for="product-image">Image</label></td>
        <td>
          <input id="product-image-text" placeholder="Product Image" v-model="product.image" />
          <div id="product-image-container" class="image-container" :class="{ loading: isLoadingImage }" style="display: flex; align-items: center;">
            <img v-if="product.image" :src="product.image" alt="Product Image" />
            <div class="overlay">{{ overlayText }}</div>
          </div>
        </td>
        <td>
          <button id="product-image-btn" @click="generateImage" class="ai-button">Generate Image</button>
        </td>
      </tr>
    </table>
  </div>
</template>

<script>
  const aiServiceUrl = '/ai/';
  const productServiceUrl = '/product/';
  
  export default {
    name: 'ProductForm',
    props: ['products'],
    emits: ['addProductsToList','updateProductInList'],
    data() {
      return {
        product: {
          id: 0,
          name: '',
          image: '/placeholder.png',
          description: '',
          price: 0.00,
          tags: []
        },
        showValidationErrors: false,
        isLoadingImage: false,
        overlayText: ''
      }
    },
    mounted() {
      // if we're editing a product, get the product details
      if (this.$route.params.id) {
        // get the product from the products list
        const product = this.products.find(product => product.id == this.$route.params.id)
        // copy the product details into the product object
        this.product = Object.assign({}, product);
        // add empty tags if the product doesn't have any
        if (!this.product.tags) {
          this.product.tags = [];
        }
      }

      // if the AI service is not responding, hide the button
      fetch(`${aiServiceUrl}health`)
        // .then(response => {
        //   console.log(JSON.stringify(response.json()));
        //   if (response.ok) {
        //     console.log('AI service is healthy');
        //   } else {
        //     console.log('AI service is not healthy');
        //     document.getElementsByClassName('ai-button')[0].style.display = 'none';
        //   }
        //   return response.json();
        // })
        .then(response => response.json())
        .then(data => {
          if (data.status === 'ok') {
            console.log('AI service is healthy');
            
            if (data.capabilities.includes('image')) {
              document.getElementById('product-image-text').style.display = 'none';
            } else {
              document.getElementById('product-image-container').style.display = 'none';
              document.getElementById('product-image-btn').style.display = 'none';
            }
          } else {
            console.log('AI service is not healthy');
            document.getElementsByClassName('ai-button')[0].style.display = 'none';
            document.getElementById('product-image-container').style.display = 'none';
            document.getElementById('product-image-btn').style.display = 'none';
          }
        })
        .catch(error => {
          console.log('Error calling the AI service');
          console.log(error)
          document.getElementsByClassName('ai-button')[0].style.display = 'none';
          document.getElementById('product-image-container').style.display = 'none';
          document.getElementById('product-image-btn').style.display = 'none';
        })
    },
    computed: {
      validationErrors() {
        let errors = [];
        if (this.product.name.length === 0) {
          errors.push('Please enter a value for the name field');
        }

        if (this.product.description.length === 0) {
          errors.push('Please enter a value for the description field');
        }

        if (this.product.price <= 0) {
          errors.push('Please enter a value greater than 0 for the price field');
        }

        return errors;
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

        let requestBody = {
          name: this.product.name,
          tags: this.product.tags.split(',').map(tag => tag.trim())
        }

        console.log(requestBody);
        this.product.description = "";

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
      generateImage() {
        // ensure the tag has a value
        if (this.product.description === "") {
          alert('Please enter a product description')
          return;
        }

        this.isLoadingImage = true;
        this.overlayText = 'Drawing...';

        let requestBody = {
          name: this.product.name,
          description: this.product.description
        }

        console.log(requestBody);

        fetch(`${aiServiceUrl}generate/image`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(requestBody)
        })
          .then(response => {
            this.overlayText = 'Downloading...'; // update overlay text
            return response.json();
          })
          .then(product => {
            this.product.image = product.image
          })
          .catch(error => {
            console.log(error)
            alert('Error occurred while generating product image')
          })
          .finally(() => {
            this.isLoadingImage = false;
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
        if (this.validationErrors.length > 0) {
          this.showValidationErrors = true;
          return;
        }

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

<style scoped>
ul {
  justify-content: center;
  list-style: none;
  margin: 0;
  padding: 0;
  width: 100%;
  color: #ff0000;
}

img {
  max-width: 100%;
}

table {
  border-collapse: collapse;
}

td {
  vertical-align: top;
  border: none;
}

.ai-button {
  height: 60px;
}

.image-container {
  position: relative;
  display: inline-block;
}

.overlay {
  position: absolute;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.5);
  color: white;
  display: flex;
  justify-content: center;
  align-items: center;
  opacity: 0;
  transition: opacity 0.3s ease;
  font-size: x-large;
  font-weight: bolder;
}

.image-container.loading .overlay {
  opacity: 1;
}

.product-form {
  display: flex;
  justify-content: center;
}
</style>