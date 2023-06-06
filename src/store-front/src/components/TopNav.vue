<template>
  <nav>
    <div class="logo">
      <a href="/">Azure Pet Supplies</a>
    </div>
    <ul class="nav-links">
      <li><router-link to="/">Products</router-link></li>
      <li><router-link to="/cart">Cart ({{ cartItemCount }})</router-link></li>
    </ul>
  </nav>
</template>

<script>
export default {
  name: 'TopNav',
  props: ['cartItemCount']
}
</script>

<style scoped>
nav {
  display: flex;
  justify-content: space-between;
  align-items: center;
  background-color: #333;
  color: #fff;
  padding: 1rem;
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
}

.logo a {
  font-size: 1.5rem;
  font-weight: bold;
  color: #fff;
  text-decoration: none;
}

.nav-links {
  display: flex;
  justify-content: flex-end;
  gap: 1rem;
}

.nav-links li {
  list-style: none;
}

.nav-links a {
  color: #fff;
  text-decoration: none;
  font-size: 1.2rem;
}

@media screen and (max-width: 768px) {
  .nav-links {
    display: none;
  }
}

@media screen and (max-width: 768px) {
  nav {
    flex-direction: column;
    align-items: flex-start;
  }

  .nav-links {
    display: flex;
    flex-direction: column;
    width: 100%;
    margin: 0;
  }

  .nav-links li {
    margin: 0.5rem 0;
  }
}
</style>