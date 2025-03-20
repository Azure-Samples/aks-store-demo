<template>
  <nav>
    <div class="logo">
      <router-link to="/">
        <img src="/contoso-pet-store-logo.png" alt="Contoso Pet Store Logo" />
      </router-link>
      Admin Portal
    </div>
    <ul class="nav-links" :class="{ 'nav-links--open': isNavOpen }">
      <li><router-link to="/orders" @click="closeNav">Orders</router-link></li>
      <li><router-link to="/products" @click="closeNav">Products</router-link></li>
    </ul>
    <button class="hamburger" @click="toggleNav">
      <span class="hamburger-icon"></span>
    </button>
  </nav>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const isNavOpen = ref(false)

function toggleNav(): void {
  isNavOpen.value = !isNavOpen.value
}

function closeNav(): void {
  isNavOpen.value = false
}
</script>

<style scoped>
nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #333;
  color: #fff;
  padding-top: 0.5rem;
  padding-left: 1rem;
  padding-right: 1rem;
  padding-bottom: 1px;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  font-size: 1.5rem;
  font-weight: bold;
}

nav img {
  padding-right: 15px;
  width: 100px;
  height: auto;
  align-self: center;
}

.nav-links {
  display: flex;
  list-style: none;
}

.logo {
  display: flex;
  align-items: center;
}

.hamburger {
  display: none;
  background: none;
  border: none;
  cursor: pointer;
  padding: 0;
  margin: 0;
  margin-top: -40px;
}

.hamburger-icon {
  display: block;
  width: 20px;
  height: 2px;
  background-color: #fff;
  position: relative;
  top: 50%;
  transform: translateY(-50%);
}

.hamburger-icon::before,
.hamburger-icon::after {
  content: '';
  display: block;
  width: 20px;
  height: 2px;
  background-color: #fff;
  position: absolute;
  left: 0;
}

.hamburger-icon::before {
  top: -6px;
}

.hamburger-icon::after {
  bottom: -6px;
}

@media (max-width: 768px) {
  .nav-links {
    display: none;
    position: absolute;
    top: 100%;
    left: 0;
    right: 0;
    background-color: #333;
    padding: 1rem;
  }

  .nav-links--open {
    display: block;
  }

  .nav-links--open li {
    padding: 0.5rem 0;
  }

  .hamburger {
    display: block;
  }
}
</style>
