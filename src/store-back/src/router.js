import { createWebHistory, createRouter } from "vue-router";
import OrderList from "./components/OrderList";
import OrderDetail from "./components/OrderDetail";
import ProductList from "./components/ProductList";
import ProductDetail from "./components/ProductDetail";

const routes = [
  { path: "/orders", component: OrderList },
  { path: "/order/:id", component: OrderDetail },
  { path: "/products", component: ProductList },
  { path: "/product/:id", component: ProductDetail },
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});

export default router;