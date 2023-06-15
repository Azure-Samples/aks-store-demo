import { createWebHistory, createRouter } from "vue-router";
import ProductList from "./components/ProductList";
import ProductDetail from "./components/ProductDetail";
import ShoppingCart from "./components/ShoppingCart";
import HealthCheck from "./components/HealthCheck";

const routes = [
  { path: "/", component: ProductList },
  { path: "/health", component: HealthCheck },
  { path: "/product/:id", component: ProductDetail },
  { path: "/cart", component: ShoppingCart },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;