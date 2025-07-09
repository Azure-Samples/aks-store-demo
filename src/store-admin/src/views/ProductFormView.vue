<template>
  <div class="action-button">
    <button @click="saveProduct" class="button">Save Product</button>
  </div>

  <div v-if="showValidationErrors && validationErrors.length > 0" class="validation-errors">
    <ul>
      <li v-for="error in validationErrors" :key="error">{{ error }}</li>
    </ul>
  </div>

  <div class="product-form-container">
    <div class="product-info-section">
      <div class="form-group">
        <label for="product-name">Name</label>
        <input
          id="product-name"
          placeholder="Product Name"
          v-model="product.name"
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label for="product-price">Price</label>
        <input
          id="product-price"
          placeholder="Product Price"
          v-model="product.price"
          type="number"
          step="0.01"
          class="form-input"
        />
      </div>

      <div class="form-group">
        <label for="product-tags">Keywords</label>
        <input
          id="product-tags"
          placeholder="Product Keywords"
          v-model="product.tags"
          class="form-input"
        />
      </div>

      <div class="form-group">
        <div class="label-with-actions">
          <label for="product-description">Description</label>
          <button
            v-if="aiCapabilities.includes('description')"
            @click="generateDescription"
            class="button ai-button"
          >
            <span class="ai-icon">✨</span> Ask AI Assistant
          </button>
        </div>
        <div class="description-container">
          <textarea
            rows="8"
            id="product-description"
            placeholder="Product Description"
            v-model="product.description"
            class="form-textarea"
          ></textarea>
        </div>
      </div>

      <input type="hidden" id="product-id" v-model="product.id" />
    </div>

    <div class="product-image-section">
      <div class="form-group">
        <div class="label-with-actions">
          <label for="product-image">Image</label>
          <button
            v-if="aiCapabilities.includes('image')"
            id="product-image-btn"
            @click="generateImage"
            class="button ai-button"
          >
            <span class="ai-icon">✨</span> Generate Image
          </button>
        </div>
        <div
          v-if="aiCapabilities.includes('image')"
          id="product-image-container"
          class="image-container"
          :class="{ loading: isLoadingImage }"
        >
          <img v-if="product.image" :src="product.image" alt="Product Image" />
          <div class="overlay">{{ overlayText }}</div>
        </div>

        <input
          v-else
          id="product-image"
          placeholder="Product Image URL"
          v-model="product.image"
          class="form-input"
        />
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useProductStore } from '@/stores'
import type { Product } from '@/types'

const aiServiceUrl = '/api/ai'
const productServiceUrl = '/api/product'

const productStore = useProductStore()
const route = useRoute()
const router = useRouter()

const DEFAULT_PRODUCT: Product = {
  id: 0,
  name: '',
  price: 0,
  tags: '',
  description: '',
  image: '/placeholder.png',
}

const product = ref<Product>({ ...DEFAULT_PRODUCT })

const aiCapabilities = ref<string[]>([])
const showValidationErrors = ref(false)
const isLoadingImage = ref(false)
const overlayText = ref('')

const validationErrors = computed(() => {
  const errors: string[] = []
  if (product.value.name.length === 0) {
    errors.push('Please enter a value for the name field')
  }

  if (product.value.price <= 0) {
    errors.push('Please enter a value greater than 0 for the price field')
  }

  if (!product.value.description || product.value.description.length === 0) {
    errors.push('Please enter a value for the description field')
  }

  return errors
})

const generateDescription = (): void => {
  // ensure the tag has a value
  if (
    !product.value.tags ||
    (Array.isArray(product.value.tags) && product.value.tags.length === 0) ||
    (typeof product.value.tags === 'string' && product.value.tags === '')
  ) {
    alert('Please enter a value for the keywords field')
    return
  }

  const intervalId = waitForAI()

  const tags =
    typeof product.value.tags === 'string'
      ? product.value.tags.split(',').map((tag) => tag.trim())
      : product.value.tags

  const requestBody = {
    name: product.value.name,
    tags,
  }

  product.value.description = ''

  fetch(`${aiServiceUrl}/generate/description`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  })
    .then((response) => response.json())
    .then((productResponse) => {
      product.value.description = productResponse.description
    })
    .catch((error) => {
      console.log(error)
      alert('Error occurred while generating product description')
    })
    .finally(() => {
      clearInterval(intervalId)
    })
}

const generateImage = (): void => {
  // ensure the tag has a value
  if (!product.value.description || product.value.description === '') {
    alert('Please enter a product description')
    return
  }

  isLoadingImage.value = true
  overlayText.value = 'Drawing...'

  const requestBody = {
    name: product.value.name,
    description: product.value.description,
  }

  fetch(`${aiServiceUrl}/generate/image`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(requestBody),
  })
    .then((response) => {
      return response.json()
    })
    .then((productResponse) => {
      overlayText.value = 'Downloading...'
      product.value.image = ''
      product.value.image = productResponse.image
    })
    .catch((error) => {
      console.log(error)
      alert('Error occurred while generating product image')
    })
    .finally(() => {
      isLoadingImage.value = false
    })
}

const waitForAI = (): ReturnType<typeof setInterval> => {
  let dots = ''
  const intervalId = setInterval(() => {
    dots += '.'
    product.value.description = `Thinking${dots}`
  }, 500)
  return intervalId
}

const saveProduct = (): void => {
  if (validationErrors.value.length > 0) {
    showValidationErrors.value = true
    return
  } else {
    showValidationErrors.value = false
  }

  // default to updates
  let method = 'PUT'

  // get the path of the current request
  const path = route.path
  if (path.includes('add')) {
    method = 'POST'
  }

  // upsert the product
  fetch(`${productServiceUrl}`, {
    method: method,
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(product.value),
  })
    .then((response) => response.json())
    .then((data) => {
      alert('Product saved successfully')
      // update or add the product to the list
      if (method === 'PUT') {
        productStore.updateProduct(data)
      } else {
        productStore.addProduct(data)
      }
      router.push(`/product/${data.id}`)
    })
    .catch((error) => {
      console.log(error)
      alert('Error occurred while saving product')
    })
}

onMounted(() => {
  if (route.params.id && route.params.id !== 'add') {
    const foundProduct = productStore.products.find((p) => p.id == route.params.id)
    if (foundProduct) {
      // Copy all properties from the found product to our local product
      Object.assign(product.value, foundProduct)
    } else {
      alert('Product not found')
    }
  }

  fetch(`${aiServiceUrl}/health`)
    .then((response) => response.json())
    .then((data) => {
      if (data.status === 'ok') {
        console.log('ai service health is ok')
        aiCapabilities.value = data.capabilities
      } else {
        console.log('ai service health is not ok')
      }
    })
    .catch((error) => {
      console.log('error occurred when evaluating ai service health')
      console.log(error)
    })
})
</script>

<style scoped>
.action-button {
  text-align: right;
  margin: 1.5rem;
}

.product-form-container {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: flex-start;
  gap: 0.5rem;
  margin: 1rem 0;
  text-align: left;
  width: 92vw;
  max-width: 100%;
  margin-left: 2rem;
}

.product-image-section,
.product-info-section {
  width: 100%;
  display: flex;
  flex-direction: column;
}

.product-image-section {
  margin-top: 0;
}

.form-group {
  margin-bottom: 1.5rem;
  width: 100%;
}

.form-group label {
  display: block;
  font-weight: bold;
  margin-bottom: 0.5rem;
}

.form-input,
.form-textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ccc;
  border-radius: var(--border-radius);
  font-size: 1rem;
}

.form-textarea {
  resize: vertical;
  min-height: 150px;
}

.description-container {
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.ai-button-container {
  margin-top: 0.5rem;
  margin-bottom: 0.5rem;
}

.ai-button {
  background-color: var(--button-color);
  align-self: flex-start;
}

.ai-button:hover {
  background-color: var(--button-hover-color);
}

.image-container {
  position: relative;
  width: 100%;
  max-width: 500px;
  margin-bottom: 1rem;
  border-radius: var(--border-radius);
  box-shadow: var(--shadow);
  overflow: hidden;
  align-self: center;
}

.image-container img {
  width: 100%;
  height: auto;
  display: block;
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

.validation-errors {
  background-color: #ffdddd;
  border-left: 5px solid #f44336;
  padding: 0.5rem 1rem;
  margin: 1rem 0;
  border-radius: var(--border-radius);
  text-align: left;
  width: 91vw;
  max-width: 100%;
  margin-left: 2rem;
}

.validation-errors ul {
  list-style: none;
  padding: 0;
  margin: 0;
  color: #f44336;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.validation-errors li {
  margin: 0;
  padding: 0;
  display: block;
  position: relative;
  padding-left: 20px;
  width: 100%;
}

.validation-errors li::before {
  content: '•';
  color: #f44336;
  position: absolute;
  left: 5px;
  font-weight: bold;
}

.label-with-actions {
  display: flex;
  align-items: center;
  margin-bottom: 0.5rem;
  width: auto; /* Allow container to shrink to content width */
}

.label-with-actions label {
  margin-right: 12px; /* Space between label and button */
  margin-bottom: 0; /* Override default label margin */
  display: inline-block; /* Allow label to sit side-by-side with button */
}

/* Update AI buttons to use standard button colors */
.ai-button {
  display: flex;
  align-items: center;
  gap: 5px;
  background-color: var(--accent-color); /* Use standard accent color */
  color: var(--secondary-color);
  border: none;
  padding: 8px 12px; /* Slightly smaller padding for better fit */
  border-radius: var(--border-radius);
  cursor: pointer;
  font-weight: 800;
  transition: background-color 0.3s;
}

.ai-button:hover {
  background-color: var(--accent-color-dark);
}

.ai-icon {
  font-size: 1.1em;
}
</style>
