import { createRouter, createWebHistory } from 'vue-router'
import OrderListView from '../views/OrderListView.vue'
import OrderDetailView from '../views/OrderDetailView.vue'
import ProductListView from '../views/ProductListView.vue'
import ProductDetailView from '../views/ProductDetailView.vue'
import ProductFormView from '../views/ProductFormView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    { path: '/', component: OrderListView },
    { path: '/orders', component: OrderListView },
    { path: '/order/:id', component: OrderDetailView },
    { path: '/products', component: ProductListView },
    { path: '/product/:id', component: ProductDetailView },
    { path: '/product/:id/edit', component: ProductFormView },
    { path: '/product/add', component: ProductFormView },
  ],
})

export default router
