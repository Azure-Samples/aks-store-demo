import { createWebHistory, createRouter } from "vue-router";
import ProductList from "./components/ProductList";
import ProductDetail from "./components/ProductDetail";
import ShoppingCart from "./components/ShoppingCart";

const routes = [
  { path: "/", component: ProductList },
  { path: "/product/:id", component: ProductDetail },
  { path: "/cart", component: ShoppingCart },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;