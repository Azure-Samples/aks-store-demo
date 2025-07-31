<template>
  <nav>
    <div class="logo">
      <router-link to="/">
        <img :src="theme.logo.src" :alt="theme.logo.alt" />
      </router-link>
      <span class="admin-text">Admin Portal</span>
    </div>
    <button class="hamburger" @click="toggleNav">
      <span class="hamburger-icon"></span>
    </button>
    <ul class="nav-links" :class="{ 'nav-links--open': isNavOpen }">
      <li><router-link to="/orders" @click="closeNav">Orders</router-link></li>
      <li><router-link to="/products" @click="closeNav">Products</router-link></li>
    </ul>
  </nav>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useTheme } from '@/composables/useTheme'

const isNavOpen = ref(false)
const { theme } = useTheme()

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
  background-color: var(--primary-color);
  color: var(--secondary-color);
  padding-top: 0.5rem;
  padding-left: 1rem;
  padding-right: 1rem;
  padding-bottom: 0.25rem;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
}

nav img {
  width: 100px;
  height: auto;
  margin-right: 0.75rem;
}

.logo {
  display: flex;
  align-items: center;
}

.admin-text {
  font-size: 1.5rem;
  font-weight: bold;
}

.nav-links {
  display: flex;
  list-style: none;
  font-size: 1.5rem;
  font-weight: bold;
  margin: 0;
  padding: 0;
}

.nav-links li {
  margin-left: 2rem;
}

.nav-links a {
  color: var(--secondary-color);
  text-decoration: none;
}

.nav-links a:hover {
  opacity: 0.8;
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
  background-color: var(--secondary-color);
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
  background-color: var(--secondary-color);
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
    background-color: var(--primary-color);
    padding: 1rem;
    flex-direction: column;
  }

  .nav-links--open {
    display: flex;
  }

  .nav-links--open li {
    padding: 0.5rem 0;
    margin-left: 0;
  }

  .hamburger {
    display: block;
  }
}
</style>
