import { createApp } from 'vue'
import router from './router'
import { authStore } from './stores/auth'
import App from './App.vue'

const app = createApp(App)
app.use(router)
authStore.fetchMe()
app.mount('#app')
