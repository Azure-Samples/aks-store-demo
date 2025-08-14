export interface ThemeConfig {
  name: string
  title: string
  logo: {
    src: string
    alt: string
  }
  colors: {
    primary: string
    secondary: string
    accent: string
    accentDark: string
    background: string
    cardBackground: string
    textColor: string
    borderColor?: string
    buttonColor: string
    buttonHoverColor: string
  }
}

export const themes: Record<string, ThemeConfig> = {
  contoso: {
    name: 'Contoso Pet Store',
    title: 'Contoso Pet Store Admin Portal',
    logo: {
      src: '/contoso-pet-store-logo.png',
      alt: 'Contoso Pet Store Logo'
    },
    colors: {
      primary: '#2a2a2a',
      secondary: '#ffffff',
      accent: '#007bff',
      accentDark: '#0062cc',
      background: '#f8f9fa',
      cardBackground: '#ffffff',
      textColor: '#2c3e50',
      buttonColor: '#005f8b',
      buttonHoverColor: '#004a6e'
    }
  },
  zava: {
    name: 'Zava',
    title: 'Zava Pet Store Admin Portal',
    logo: {
      src: '/zava-logo-white.png',
      alt: 'Zava Logo'
    },
    colors: {
      primary: '#000000',
      secondary: '#ffffff',
      accent: '#000000',
      accentDark: '#333333',
      background: '#ffffff',
      cardBackground: '#ffffff',
      textColor: '#000000',
      borderColor: '#e0e0e0',
      buttonColor: '#000000',
      buttonHoverColor: '#333333'
    }
  }
}

export const defaultTheme = 'contoso'