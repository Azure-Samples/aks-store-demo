import { createApp } from 'vue'
import { createPinia } from 'pinia'
import './assets/styles.scss'

import App from './App.vue'
import router from './router'
import { useTheme } from './composables/useTheme'

const app = createApp(App)

app.use(createPinia())
app.use(router)

// Initialize theme before mounting
const { initializeTheme } = useTheme()
initializeTheme().then(() => {
  app.mount('#app')
})
