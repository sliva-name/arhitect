<template>
  <div>
    <h1>Welcome to Nuxt 4</h1>
    <p>API Base: {{ config.public.apiBase }}</p>
  </div>
</template>

<script setup lang="ts">
const config = useRuntimeConfig()
</script>
