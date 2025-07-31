import { ref, computed, onMounted } from 'vue'
import { themes, defaultTheme, type ThemeConfig } from '@/config/themes'

const currentThemeName = ref<string>(defaultTheme)

export function useTheme() {
  const theme = computed(() => themes[currentThemeName.value] || themes[defaultTheme])
  
  const setTheme = (themeName: string) => {
    if (themes[themeName]) {
      currentThemeName.value = themeName
      applyThemeToDOM(themes[themeName])
      updatePageTitle(themes[themeName])
    }
  }

  const applyThemeToDOM = (themeConfig: ThemeConfig) => {
    const root = document.documentElement
    root.style.setProperty('--primary-color', themeConfig.colors.primary)
    root.style.setProperty('--secondary-color', themeConfig.colors.secondary)
    root.style.setProperty('--accent-color', themeConfig.colors.accent)
    root.style.setProperty('--accent-color-dark', themeConfig.colors.accentDark)
    root.style.setProperty('--background-color', themeConfig.colors.background)
    root.style.setProperty('--card-background', themeConfig.colors.cardBackground)
    root.style.setProperty('--text-color', themeConfig.colors.textColor)
    root.style.setProperty('--button-color', themeConfig.colors.buttonColor)
    root.style.setProperty('--button-hover-color', themeConfig.colors.buttonHoverColor)
    
    if (themeConfig.colors.borderColor) {
      root.style.setProperty('--border-color', themeConfig.colors.borderColor)
    }
  }

  const updatePageTitle = (themeConfig: ThemeConfig) => {
    document.title = themeConfig.title
  }

  const initializeTheme = async () => {
    // Try to get the company name from environment variables
    // In a Vite app, we need to fetch this from a runtime config
    try {
      const response = await fetch('/api/config')
      const config = await response.json()
      const companyName = config.companyName
      
      if (companyName) {
        // Convert to lowercase to match our theme keys
        const themeKey = companyName.toLowerCase()
        
        if (themes[themeKey]) {
          setTheme(themeKey)
        } else {
          console.warn(`Unknown company name: ${companyName}, using default theme`)
          setTheme(defaultTheme)
        }
      } else {
        setTheme(defaultTheme)
      }
    } catch (error) {
      console.warn('Could not load runtime config, using default theme:', error)
      setTheme(defaultTheme)
    }
  }

  return {
    theme,
    currentThemeName: computed(() => currentThemeName.value),
    setTheme,
    initializeTheme
  }
}