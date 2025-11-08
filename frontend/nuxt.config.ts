export default defineNuxtConfig({
  compatibilityDate: '2024-11-01',
  devtools: { enabled: true },
  
  modules: ['@nuxt/eslint'],

  runtimeConfig: {
    public: {
      apiBase: process.env.NUXT_PUBLIC_API_BASE || 'http://api.localhost'
    }
  },

  devServer: {
    host: '0.0.0.0',
    port: 3000
  },

  vite: {
    server: {
      watch: {
        usePolling: true
      }
    }
  }
})
