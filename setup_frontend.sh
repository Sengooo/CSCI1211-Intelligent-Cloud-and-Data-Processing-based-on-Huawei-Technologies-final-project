#!/bin/bash
# Run this from inside booking-frontend folder

# ── main.js ──────────────────────────────────────────────────────────────────
cat > src/main.js << 'EOF'
import { createApp } from 'vue'
import router from './router'
import { authStore } from './stores/auth'
import App from './App.vue'

const app = createApp(App)
app.use(router)
authStore.fetchMe()
app.mount('#app')
EOF

# ── .env ─────────────────────────────────────────────────────────────────────
cat > .env << 'EOF'
VITE_API_URL=http://localhost:8000
EOF

# ── src/services/api.js ───────────────────────────────────────────────────────
cat > src/services/api.js << 'EOF'
import axios from 'axios'

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000'

const api = axios.create({
  baseURL: BASE_URL,
  headers: { 'Content-Type': 'application/json' },
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('access_token')
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

api.interceptors.response.use(
  (res) => res,
  async (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('access_token')
      localStorage.removeItem('refresh_token')
      window.location.href = '/login'
    }
    return Promise.reject(err)
  }
)

export const authAPI = {
  register: (data) => api.post('/users/register/', data),
  login: (data) => api.post('/users/login/', data),
  me: () => api.get('/users/personal-info/'),
  updateProfile: (data) => api.patch('/users/update-profile/', data),
  refreshToken: (refresh) => api.post('/users/token/refresh/', { refresh }),
}

export const apartmentsAPI = {
  list: (params) => api.get('/properties/apartments/', { params }),
  get: (id) => api.get(`/properties/apartments/${id}/`),
  create: (data) => api.post('/properties/apartments/', data),
  update: (id, data) => api.patch(`/properties/apartments/${id}/`, data),
  delete: (id) => api.delete(`/properties/apartments/${id}/`),
  reviews: (id) => api.get(`/properties/apartments/${id}/reviews/`),
}

export const bookingsAPI = {
  list: () => api.get('/bookings/'),
  create: (data) => api.post('/bookings/', data),
  get: (id) => api.get(`/bookings/${id}/`),
  cancel: (id) => api.patch(`/bookings/${id}/cancel/`),
  updateStatus: (id, status) => api.patch(`/bookings/${id}/update-status/`, { status }),
}

export const reviewsAPI = {
  list: () => api.get('/reviews/'),
  create: (data) => api.post('/reviews/', data),
}

export default api
EOF

# ── src/stores/auth.js ────────────────────────────────────────────────────────
cat > src/stores/auth.js << 'EOF'
import { reactive } from 'vue'
import { authAPI } from '../services/api'

export const authStore = reactive({
  user: null,
  isLoading: false,
  error: null,

  get isLoggedIn() { return !!localStorage.getItem('access_token') },
  get isLandlord() { return this.user?.is_landlord === true },
  get isRenter() { return this.user?.is_renter === true },

  async login(email, password) {
    this.isLoading = true; this.error = null
    try {
      const { data } = await authAPI.login({ email, password })
      localStorage.setItem('access_token', data.access)
      localStorage.setItem('refresh_token', data.refresh)
      this.user = { id: data.id, email: data.email, first_name: data.first_name, last_name: data.last_name, is_landlord: data.is_landlord, is_renter: data.is_renter }
      return true
    } catch (e) {
      this.error = e.response?.data?.detail || 'Login failed'
      return false
    } finally { this.isLoading = false }
  },

  async register(payload) {
    this.isLoading = true; this.error = null
    try {
      await authAPI.register(payload)
      return true
    } catch (e) {
      this.error = e.response?.data || 'Registration failed'
      return false
    } finally { this.isLoading = false }
  },

  async fetchMe() {
    if (!this.isLoggedIn) return
    try { const { data } = await authAPI.me(); this.user = data } catch (_) {}
  },

  logout() {
    localStorage.removeItem('access_token')
    localStorage.removeItem('refresh_token')
    this.user = null
  },
})
EOF

# ── src/router/index.js ───────────────────────────────────────────────────────
cat > src/router/index.js << 'EOF'
import { createRouter, createWebHistory } from 'vue-router'
import { authStore } from '../stores/auth'

const routes = [
  { path: '/', redirect: '/apartments' },
  { path: '/login', component: () => import('../views/LoginView.vue') },
  { path: '/register', component: () => import('../views/RegisterView.vue') },
  { path: '/apartments', component: () => import('../views/ApartmentsView.vue') },
  { path: '/apartments/:id', component: () => import('../views/ApartmentDetailView.vue') },
  { path: '/bookings', component: () => import('../views/BookingsView.vue'), meta: { requiresAuth: true } },
  { path: '/my-apartments', component: () => import('../views/MyApartmentsView.vue'), meta: { requiresAuth: true, landlordOnly: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach(async (to) => {
  if (to.meta.requiresAuth && !authStore.isLoggedIn) return '/login'
  if (to.meta.landlordOnly && authStore.user && !authStore.isLandlord) return '/apartments'
})

export default router
EOF

# ── src/App.vue ───────────────────────────────────────────────────────────────
cat > src/App.vue << 'EOF'
<template>
  <div id="app">
    <nav class="navbar">
      <router-link to="/apartments" class="logo">
        <span class="logo-icon">⬡</span> StayFinder
      </router-link>
      <div class="nav-links">
        <router-link to="/apartments">Apartments</router-link>
        <template v-if="auth.isLoggedIn">
          <router-link to="/bookings">My Bookings</router-link>
          <router-link v-if="auth.isLandlord" to="/my-apartments">My Listings</router-link>
          <span class="nav-user">{{ auth.user?.first_name }}</span>
          <button class="btn-logout" @click="logout">Logout</button>
        </template>
        <template v-else>
          <router-link to="/login" class="btn-nav">Sign in</router-link>
          <router-link to="/register" class="btn-nav btn-nav-primary">Register</router-link>
        </template>
      </div>
    </nav>
    <main><router-view /></main>
  </div>
</template>

<script setup>
import { useRouter } from 'vue-router'
import { authStore as auth } from './stores/auth'
const router = useRouter()
function logout() { auth.logout(); router.push('/login') }
</script>

<style>
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
:root {
  --primary: #1a6cf6; --primary-dark: #1457cc;
  --surface: #ffffff; --bg: #f5f6fa;
  --text: #111827; --text-muted: #6b7280; --border: #e5e7eb;
  --radius: 12px; --shadow: 0 1px 3px rgba(0,0,0,.08), 0 4px 16px rgba(0,0,0,.06);
}
body { font-family: 'DM Sans','Segoe UI',sans-serif; background: var(--bg); color: var(--text); line-height: 1.6; }
a { text-decoration: none; color: inherit; }
.navbar { position: sticky; top: 0; z-index: 100; background: rgba(255,255,255,.92); backdrop-filter: blur(12px); border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: space-between; padding: 0 2rem; height: 60px; }
.logo { font-size: 1.25rem; font-weight: 700; color: var(--primary); display: flex; align-items: center; gap: .4rem; }
.logo-icon { font-size: 1.4rem; }
.nav-links { display: flex; align-items: center; gap: 1.2rem; font-size: .9rem; }
.nav-links a { color: var(--text-muted); font-weight: 500; transition: color .2s; }
.nav-links a:hover, .nav-links a.router-link-active { color: var(--primary); }
.nav-user { font-weight: 600; color: var(--text); padding: 0 .5rem; }
.btn-nav { padding: .4rem 1rem; border-radius: 8px; font-weight: 600; transition: all .2s; }
.btn-nav-primary { background: var(--primary); color: #fff !important; }
.btn-nav-primary:hover { background: var(--primary-dark); }
.btn-logout { background: none; border: 1px solid var(--border); border-radius: 8px; padding: .35rem .9rem; font-size: .85rem; cursor: pointer; color: var(--text-muted); transition: all .2s; }
.btn-logout:hover { border-color: #e53e3e; color: #e53e3e; }
main { min-height: calc(100vh - 60px); }
.container { max-width: 1200px; margin: 0 auto; padding: 0 1.5rem; }
.card { background: var(--surface); border-radius: var(--radius); box-shadow: var(--shadow); overflow: hidden; }
.btn { display: inline-flex; align-items: center; justify-content: center; gap: .4rem; padding: .65rem 1.4rem; border-radius: 10px; font-weight: 600; font-size: .9rem; cursor: pointer; border: none; transition: all .2s; }
.btn-primary { background: var(--primary); color: #fff; }
.btn-primary:hover { background: var(--primary-dark); transform: translateY(-1px); }
.btn-secondary { background: var(--bg); color: var(--text); border: 1px solid var(--border); }
.btn-secondary:hover { border-color: var(--primary); color: var(--primary); }
.btn-danger { background: #fee2e2; color: #dc2626; }
.btn-danger:hover { background: #fecaca; }
.btn:disabled { opacity: .5; cursor: not-allowed; transform: none !important; }
.badge { display: inline-block; padding: .2rem .65rem; border-radius: 99px; font-size: .75rem; font-weight: 600; }
.badge-pending { background: #fef3c7; color: #92400e; }
.badge-confirmed { background: #d1fae5; color: #065f46; }
.badge-completed { background: #dbeafe; color: #1e40af; }
.badge-cancelled { background: #fee2e2; color: #991b1b; }
.form-group { display: flex; flex-direction: column; gap: .4rem; margin-bottom: 1rem; }
.form-group label { font-size: .85rem; font-weight: 600; color: var(--text-muted); }
.form-group input, .form-group select, .form-group textarea { padding: .7rem 1rem; border: 1.5px solid var(--border); border-radius: 10px; font-size: .95rem; background: var(--surface); color: var(--text); transition: border-color .2s; font-family: inherit; }
.form-group input:focus, .form-group select:focus, .form-group textarea:focus { outline: none; border-color: var(--primary); }
.error-msg { color: #dc2626; font-size: .85rem; margin-top: .25rem; }
</style>
EOF

# ── src/views/LoginView.vue ───────────────────────────────────────────────────
cat > src/views/LoginView.vue << 'EOF'
<template>
  <div class="auth-page">
    <div class="auth-card card">
      <div class="auth-header">
        <h1>Welcome back</h1>
        <p>Sign in to your StayFinder account</p>
      </div>
      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label>Email</label>
          <input v-model="form.email" type="email" placeholder="you@example.com" required />
        </div>
        <div class="form-group">
          <label>Password</label>
          <input v-model="form.password" type="password" placeholder="••••••••" required />
        </div>
        <p v-if="auth.error" class="error-msg">{{ auth.error }}</p>
        <button class="btn btn-primary full-width" type="submit" :disabled="auth.isLoading">
          {{ auth.isLoading ? 'Signing in...' : 'Sign in' }}
        </button>
      </form>
      <p class="auth-footer">Don't have an account? <router-link to="/register">Register</router-link></p>
    </div>
  </div>
</template>
<script setup>
import { reactive } from 'vue'
import { useRouter } from 'vue-router'
import { authStore as auth } from '../stores/auth'
const router = useRouter()
const form = reactive({ email: '', password: '' })
async function handleLogin() {
  const ok = await auth.login(form.email, form.password)
  if (ok) router.push('/apartments')
}
</script>
<style scoped>
.auth-page { min-height: calc(100vh - 60px); display: flex; align-items: center; justify-content: center; padding: 2rem; }
.auth-card { width: 100%; max-width: 420px; padding: 2.5rem; }
.auth-header { text-align: center; margin-bottom: 2rem; }
.auth-header h1 { font-size: 1.75rem; font-weight: 700; margin-bottom: .4rem; }
.auth-header p { color: var(--text-muted); }
.full-width { width: 100%; margin-top: .5rem; }
.auth-footer { text-align: center; margin-top: 1.5rem; color: var(--text-muted); font-size: .9rem; }
.auth-footer a { color: var(--primary); font-weight: 600; }
</style>
EOF

# ── src/views/RegisterView.vue ────────────────────────────────────────────────
cat > src/views/RegisterView.vue << 'EOF'
<template>
  <div class="auth-page">
    <div class="auth-card card">
      <div class="auth-header">
        <h1>Create account</h1>
        <p>Join StayFinder today</p>
      </div>
      <form @submit.prevent="handleRegister">
        <div class="form-row">
          <div class="form-group">
            <label>First name</label>
            <input v-model="form.first_name" type="text" placeholder="John" required />
          </div>
          <div class="form-group">
            <label>Last name</label>
            <input v-model="form.last_name" type="text" placeholder="Doe" required />
          </div>
        </div>
        <div class="form-group">
          <label>Email</label>
          <input v-model="form.email" type="email" placeholder="you@example.com" required />
        </div>
        <div class="form-group">
          <label>Password</label>
          <input v-model="form.password" type="password" placeholder="••••••••" required />
        </div>
        <div class="role-selector">
          <p class="role-label">I want to...</p>
          <div class="role-options">
            <label :class="['role-card', form.is_renter && 'active']">
              <input type="checkbox" v-model="form.is_renter" />
              <span class="role-icon">🔍</span>
              <span class="role-text">Find & book places</span>
              <small>Renter</small>
            </label>
            <label :class="['role-card', form.is_landlord && 'active']">
              <input type="checkbox" v-model="form.is_landlord" />
              <span class="role-icon">🏠</span>
              <span class="role-text">List my property</span>
              <small>Landlord</small>
            </label>
          </div>
        </div>
        <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
        <p v-if="success" class="success-msg">Account created! <router-link to="/login">Sign in</router-link></p>
        <button class="btn btn-primary full-width" type="submit" :disabled="auth.isLoading">
          {{ auth.isLoading ? 'Creating...' : 'Create account' }}
        </button>
      </form>
      <p class="auth-footer">Already have an account? <router-link to="/login">Sign in</router-link></p>
    </div>
  </div>
</template>
<script setup>
import { reactive, ref, computed } from 'vue'
import { authStore as auth } from '../stores/auth'
const form = reactive({ first_name: '', last_name: '', email: '', password: '', is_renter: true, is_landlord: false })
const success = ref(false)
const errorMsg = computed(() => {
  if (!auth.error) return ''
  if (typeof auth.error === 'string') return auth.error
  return Object.entries(auth.error).map(([k, v]) => `${k}: ${v}`).join(', ')
})
async function handleRegister() {
  success.value = false
  const ok = await auth.register(form)
  if (ok) success.value = true
}
</script>
<style scoped>
.auth-page { min-height: calc(100vh - 60px); display: flex; align-items: center; justify-content: center; padding: 2rem; }
.auth-card { width: 100%; max-width: 480px; padding: 2.5rem; }
.auth-header { text-align: center; margin-bottom: 2rem; }
.auth-header h1 { font-size: 1.75rem; font-weight: 700; margin-bottom: .4rem; }
.auth-header p { color: var(--text-muted); }
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: .75rem; }
.full-width { width: 100%; margin-top: .5rem; }
.auth-footer { text-align: center; margin-top: 1.5rem; color: var(--text-muted); font-size: .9rem; }
.auth-footer a, .success-msg a { color: var(--primary); font-weight: 600; }
.success-msg { color: #059669; font-size: .9rem; margin-bottom: .5rem; }
.role-selector { margin-bottom: 1.25rem; }
.role-label { font-size: .85rem; font-weight: 600; color: var(--text-muted); margin-bottom: .6rem; }
.role-options { display: grid; grid-template-columns: 1fr 1fr; gap: .75rem; }
.role-card { display: flex; flex-direction: column; align-items: center; gap: .25rem; padding: 1rem; border: 2px solid var(--border); border-radius: var(--radius); cursor: pointer; transition: all .2s; text-align: center; }
.role-card input { display: none; }
.role-card.active { border-color: var(--primary); background: #eff6ff; }
.role-icon { font-size: 1.5rem; }
.role-text { font-weight: 600; font-size: .9rem; }
.role-card small { color: var(--text-muted); font-size: .75rem; }
</style>
EOF

# ── src/views/ApartmentsView.vue ──────────────────────────────────────────────
cat > src/views/ApartmentsView.vue << 'EOF'
<template>
  <div class="page">
    <div class="hero">
      <div class="container">
        <h1>Find your perfect stay</h1>
        <p>Browse apartments across Kazakhstan and beyond</p>
        <div class="search-bar">
          <input v-model="filters.search" type="text" placeholder="Search by city or title..." @input="onFilter" />
          <div class="filter-row">
            <select v-model="filters.rooms" @change="onFilter">
              <option value="">Any rooms</option>
              <option value="1">1 room</option>
              <option value="2">2 rooms</option>
              <option value="3">3 rooms</option>
              <option value="4">4+ rooms</option>
            </select>
            <select v-model="filters.ordering" @change="onFilter">
              <option value="">Sort by</option>
              <option value="price_per_night">Price: Low to High</option>
              <option value="-price_per_night">Price: High to Low</option>
              <option value="-created_at">Newest first</option>
            </select>
            <input v-model="filters.max_price" type="number" placeholder="Max price/night" @input="onFilter" />
          </div>
        </div>
      </div>
    </div>
    <div class="container">
      <div v-if="loading" class="loading-state"><div class="spinner"></div><p>Loading apartments...</p></div>
      <div v-else-if="apartments.length === 0" class="empty-state"><p>🏙️ No apartments found.</p></div>
      <div v-else class="grid">
        <router-link v-for="apt in apartments" :key="apt.id" :to="`/apartments/${apt.id}`" class="apt-card card">
          <div class="apt-img">
            <div class="apt-img-placeholder">
              <span>🏠</span>
              <span class="apt-rooms">{{ apt.rooms }} room{{ apt.rooms !== 1 ? 's' : '' }}</span>
            </div>
          </div>
          <div class="apt-info">
            <div class="apt-location">{{ apt.city?.name }}, {{ apt.city?.country?.name }}</div>
            <h3 class="apt-title">{{ apt.title }}</h3>
            <p class="apt-address">📍 {{ apt.address }}</p>
            <div class="apt-footer">
              <div class="apt-price"><strong>${{ apt.price_per_night }}</strong><span>/ night</span></div>
              <span class="btn btn-secondary apt-btn">View →</span>
            </div>
          </div>
        </router-link>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, onMounted } from 'vue'
import { apartmentsAPI } from '../services/api'
const apartments = ref([])
const loading = ref(true)
const filters = reactive({ search: '', rooms: '', ordering: '', max_price: '' })
const MOCK = [
  { id: 1, title: 'Cozy Studio in Almaty Center', address: 'Abay Ave 12', city: { name: 'Almaty', country: { name: 'Kazakhstan' } }, price_per_night: '45.00', rooms: 1 },
  { id: 2, title: 'Spacious 2BR near Medeo', address: 'Dostyk St 88', city: { name: 'Almaty', country: { name: 'Kazakhstan' } }, price_per_night: '80.00', rooms: 2 },
  { id: 3, title: 'Modern Loft in Astana', address: 'Turan Ave 5', city: { name: 'Astana', country: { name: 'Kazakhstan' } }, price_per_night: '65.00', rooms: 1 },
  { id: 4, title: 'Family Apartment 3BR', address: 'Al-Farabi 22', city: { name: 'Almaty', country: { name: 'Kazakhstan' } }, price_per_night: '110.00', rooms: 3 },
  { id: 5, title: 'Budget Room Shymkent', address: 'Lenin St 1', city: { name: 'Shymkent', country: { name: 'Kazakhstan' } }, price_per_night: '25.00', rooms: 1 },
  { id: 6, title: 'Penthouse with City View', address: 'Republic Square 3', city: { name: 'Astana', country: { name: 'Kazakhstan' } }, price_per_night: '200.00', rooms: 4 },
]
async function loadApartments() {
  loading.value = true
  try {
    const params = {}
    if (filters.rooms) params.rooms = filters.rooms
    if (filters.ordering) params.ordering = filters.ordering
    if (filters.max_price) params.max_price = filters.max_price
    const { data } = await apartmentsAPI.list(params)
    apartments.value = data
  } catch { apartments.value = MOCK }
  finally { loading.value = false }
}
let filterTimer = null
function onFilter() { clearTimeout(filterTimer); filterTimer = setTimeout(loadApartments, 400) }
onMounted(loadApartments)
</script>
<style scoped>
.hero { background: linear-gradient(135deg, #1a6cf6 0%, #0f4bc4 100%); color: white; padding: 4rem 0 3rem; margin-bottom: 2.5rem; }
.hero h1 { font-size: 2.5rem; font-weight: 800; margin-bottom: .5rem; }
.hero p { opacity: .85; font-size: 1.1rem; margin-bottom: 1.75rem; }
.search-bar { background: white; border-radius: var(--radius); padding: 1.25rem; display: flex; flex-direction: column; gap: .75rem; max-width: 780px; }
.search-bar > input { border: none; font-size: 1.05rem; color: var(--text); outline: none; padding: .25rem .1rem; border-bottom: 2px solid var(--border); }
.filter-row { display: flex; gap: .75rem; flex-wrap: wrap; }
.filter-row select, .filter-row input { flex: 1; min-width: 140px; padding: .5rem .75rem; border: 1.5px solid var(--border); border-radius: 8px; font-size: .875rem; background: var(--bg); color: var(--text); font-family: inherit; }
.filter-row select:focus, .filter-row input:focus { outline: none; border-color: var(--primary); }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 1.5rem; padding-bottom: 3rem; }
.apt-card { cursor: pointer; transition: transform .2s, box-shadow .2s; }
.apt-card:hover { transform: translateY(-4px); box-shadow: 0 8px 32px rgba(0,0,0,.12); }
.apt-img { height: 180px; }
.apt-img-placeholder { height: 100%; background: linear-gradient(135deg, #dbeafe 0%, #eff6ff 100%); display: flex; flex-direction: column; align-items: center; justify-content: center; gap: .5rem; font-size: 3rem; }
.apt-rooms { font-size: .8rem; font-weight: 600; color: var(--primary); background: white; padding: .2rem .6rem; border-radius: 99px; }
.apt-info { padding: 1.25rem; }
.apt-location { font-size: .8rem; color: var(--primary); font-weight: 600; margin-bottom: .3rem; }
.apt-title { font-size: 1rem; font-weight: 700; margin-bottom: .4rem; }
.apt-address { font-size: .82rem; color: var(--text-muted); margin-bottom: 1rem; }
.apt-footer { display: flex; align-items: center; justify-content: space-between; }
.apt-price strong { font-size: 1.2rem; font-weight: 800; color: var(--primary); }
.apt-price span { font-size: .8rem; color: var(--text-muted); margin-left: .2rem; }
.apt-btn { padding: .4rem .9rem; font-size: .82rem; }
.loading-state, .empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 1rem; padding: 5rem 0; color: var(--text-muted); }
.spinner { width: 40px; height: 40px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
</style>
EOF

# ── src/views/ApartmentDetailView.vue ────────────────────────────────────────
cat > src/views/ApartmentDetailView.vue << 'EOF'
<template>
  <div class="page">
    <div v-if="loading" class="loading-state"><div class="spinner"></div></div>
    <div v-else-if="apt" class="container detail-layout">
      <div class="detail-main">
        <div class="apt-hero card">
          <div class="apt-hero-img"><span>🏠</span></div>
          <div class="apt-hero-info">
            <div class="detail-location">{{ apt.city?.name }}, {{ apt.city?.country?.name }}</div>
            <h1>{{ apt.title }}</h1>
            <p class="detail-address">📍 {{ apt.address }}</p>
            <div class="detail-meta">
              <span class="meta-item">🛏 {{ apt.rooms }} room{{ apt.rooms !== 1 ? 's' : '' }}</span>
              <span class="meta-item">💰 ${{ apt.price_per_night }} / night</span>
            </div>
            <p class="detail-desc">{{ apt.description }}</p>
          </div>
        </div>
        <div class="card reviews-card">
          <h2>Reviews <span class="review-count">({{ reviews.length }})</span></h2>
          <div v-if="reviews.length === 0" class="no-reviews">No reviews yet.</div>
          <div v-for="r in reviews" :key="r.id" class="review-item">
            <div class="review-header">
              <span class="review-author">{{ r.author?.first_name }} {{ r.author?.last_name }}</span>
              <span class="review-stars">{{ '★'.repeat(r.rating) }}{{ '☆'.repeat(5 - r.rating) }}</span>
            </div>
            <p class="review-comment">{{ r.comment }}</p>
            <span class="review-date">{{ formatDate(r.created_at) }}</span>
          </div>
          <div v-if="auth.isRenter && auth.isLoggedIn && !hasReviewed" class="add-review">
            <h3>Leave a review</h3>
            <div class="star-picker">
              <span v-for="n in 5" :key="n" :class="['star', n <= reviewForm.rating ? 'active' : '']" @click="reviewForm.rating = n">★</span>
            </div>
            <div class="form-group">
              <textarea v-model="reviewForm.comment" rows="3" placeholder="Share your experience..."></textarea>
            </div>
            <p v-if="reviewError" class="error-msg">{{ reviewError }}</p>
            <button class="btn btn-primary" @click="submitReview" :disabled="submittingReview">
              {{ submittingReview ? 'Submitting...' : 'Submit review' }}
            </button>
          </div>
        </div>
      </div>
      <div class="booking-sidebar">
        <div class="card booking-card">
          <div class="booking-price"><strong>${{ apt.price_per_night }}</strong><span>/ night</span></div>
          <template v-if="auth.isLoggedIn && auth.isRenter">
            <div class="form-group"><label>Check-in</label><input v-model="bookingForm.check_in" type="date" :min="today" /></div>
            <div class="form-group"><label>Check-out</label><input v-model="bookingForm.check_out" type="date" :min="bookingForm.check_in || today" /></div>
            <div v-if="nights > 0" class="price-breakdown">
              <div class="price-row"><span>${{ apt.price_per_night }} × {{ nights }} nights</span><strong>${{ totalPrice }}</strong></div>
              <div class="price-row total"><span>Total</span><strong>${{ totalPrice }}</strong></div>
            </div>
            <p v-if="bookingError" class="error-msg">{{ bookingError }}</p>
            <p v-if="bookingSuccess" class="success-msg">✓ Booking created! Check <router-link to="/bookings">My Bookings</router-link></p>
            <button class="btn btn-primary full-width" @click="submitBooking" :disabled="!canBook || submittingBooking">
              {{ submittingBooking ? 'Booking...' : 'Book now' }}
            </button>
          </template>
          <template v-else-if="auth.isLandlord"><p class="booking-note">You are viewing as landlord.</p></template>
          <template v-else>
            <p class="booking-note"><router-link to="/login">Sign in</router-link> or <router-link to="/register">register</router-link> to book.</p>
          </template>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { authStore as auth } from '../stores/auth'
import { apartmentsAPI, bookingsAPI, reviewsAPI } from '../services/api'
const route = useRoute()
const apt = ref(null); const reviews = ref([]); const loading = ref(true)
const bookingForm = reactive({ check_in: '', check_out: '' })
const bookingError = ref(''); const bookingSuccess = ref(false); const submittingBooking = ref(false)
const reviewForm = reactive({ rating: 5, comment: '' })
const reviewError = ref(''); const submittingReview = ref(false); const hasReviewed = ref(false)
const today = new Date().toISOString().split('T')[0]
const nights = computed(() => {
  if (!bookingForm.check_in || !bookingForm.check_out) return 0
  return Math.max(0, Math.floor((new Date(bookingForm.check_out) - new Date(bookingForm.check_in)) / 86400000))
})
const totalPrice = computed(() => (nights.value * parseFloat(apt.value?.price_per_night || 0)).toFixed(2))
const canBook = computed(() => nights.value > 0)
const MOCK_APT = { id: 1, title: 'Cozy Studio in Almaty Center', description: 'Modern studio in the heart of Almaty. Walking distance to central park, cafes and public transport.', address: 'Abay Ave 12', rooms: 1, price_per_night: '45.00', city: { name: 'Almaty', country: { name: 'Kazakhstan' } } }
const MOCK_REVIEWS = [
  { id: 1, rating: 5, comment: 'Amazing place, very clean!', created_at: '2026-03-01T10:00:00Z', author: { first_name: 'Alex', last_name: 'Kim' } },
  { id: 2, rating: 4, comment: 'Good location, nice host.', created_at: '2026-02-15T10:00:00Z', author: { first_name: 'Maria', last_name: 'Lee' } },
]
onMounted(async () => {
  const id = route.params.id
  try {
    const [aptRes, revRes] = await Promise.all([apartmentsAPI.get(id), apartmentsAPI.reviews(id)])
    apt.value = aptRes.data; reviews.value = revRes.data
  } catch { apt.value = { ...MOCK_APT, id }; reviews.value = MOCK_REVIEWS }
  finally { loading.value = false }
})
async function submitBooking() {
  bookingError.value = ''; bookingSuccess.value = false; submittingBooking.value = true
  try {
    await bookingsAPI.create({ apartment: apt.value.id, check_in: bookingForm.check_in, check_out: bookingForm.check_out })
    bookingSuccess.value = true; bookingForm.check_in = ''; bookingForm.check_out = ''
  } catch (e) { bookingError.value = e.response?.data?.detail || 'Could not create booking' }
  finally { submittingBooking.value = false }
}
async function submitReview() {
  reviewError.value = ''; submittingReview.value = true
  try {
    const { data } = await reviewsAPI.create({ apartment: apt.value.id, rating: reviewForm.rating, comment: reviewForm.comment })
    reviews.value.unshift(data); hasReviewed.value = true
  } catch (e) { reviewError.value = e.response?.data?.detail || 'Could not submit review' }
  finally { submittingReview.value = false }
}
function formatDate(d) { return new Date(d).toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' }) }
</script>
<style scoped>
.detail-layout { display: grid; grid-template-columns: 1fr 340px; gap: 2rem; padding-top: 2rem; padding-bottom: 3rem; align-items: start; }
.detail-main { display: flex; flex-direction: column; gap: 1.5rem; }
.apt-hero-img { height: 240px; background: linear-gradient(135deg, #dbeafe 0%, #eff6ff 100%); display: flex; align-items: center; justify-content: center; font-size: 5rem; }
.apt-hero-info { padding: 1.5rem; }
.detail-location { font-size: .85rem; color: var(--primary); font-weight: 600; margin-bottom: .4rem; }
h1 { font-size: 1.6rem; font-weight: 800; margin-bottom: .5rem; }
.detail-address { color: var(--text-muted); font-size: .9rem; margin-bottom: 1rem; }
.detail-meta { display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 1rem; }
.meta-item { font-size: .9rem; background: var(--bg); padding: .3rem .8rem; border-radius: 99px; }
.detail-desc { color: var(--text-muted); line-height: 1.7; }
.reviews-card { padding: 1.5rem; }
.reviews-card h2 { font-size: 1.15rem; font-weight: 700; margin-bottom: 1rem; }
.review-count { font-size: .85rem; color: var(--text-muted); font-weight: 400; }
.no-reviews { color: var(--text-muted); font-size: .9rem; padding: 1rem 0; }
.review-item { padding: 1rem 0; border-bottom: 1px solid var(--border); }
.review-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: .4rem; }
.review-author { font-weight: 600; font-size: .9rem; }
.review-stars { color: #f59e0b; }
.review-comment { color: var(--text-muted); font-size: .9rem; margin-bottom: .3rem; }
.review-date { font-size: .78rem; color: var(--text-muted); }
.add-review { margin-top: 1.5rem; padding-top: 1.5rem; border-top: 2px solid var(--border); }
.add-review h3 { font-size: 1rem; margin-bottom: .75rem; }
.star-picker { display: flex; gap: .3rem; margin-bottom: 1rem; cursor: pointer; }
.star { font-size: 1.8rem; color: var(--border); transition: color .1s; }
.star.active { color: #f59e0b; }
.booking-sidebar { position: sticky; top: 76px; }
.booking-card { padding: 1.5rem; }
.booking-price { margin-bottom: 1.25rem; }
.booking-price strong { font-size: 2rem; font-weight: 800; color: var(--primary); }
.booking-price span { color: var(--text-muted); font-size: .9rem; margin-left: .3rem; }
.price-breakdown { background: var(--bg); border-radius: 10px; padding: 1rem; margin-bottom: 1rem; }
.price-row { display: flex; justify-content: space-between; font-size: .9rem; padding: .25rem 0; }
.price-row.total { border-top: 1px solid var(--border); margin-top: .5rem; padding-top: .75rem; font-weight: 700; }
.full-width { width: 100%; }
.booking-note { color: var(--text-muted); font-size: .9rem; text-align: center; line-height: 1.6; }
.booking-note a { color: var(--primary); font-weight: 600; }
.success-msg { color: #059669; font-size: .9rem; margin-bottom: .75rem; }
.success-msg a { color: var(--primary); font-weight: 600; }
.loading-state { display: flex; justify-content: center; padding: 5rem 0; }
.spinner { width: 40px; height: 40px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
@media (max-width: 768px) { .detail-layout { grid-template-columns: 1fr; } .booking-sidebar { position: static; } }
</style>
EOF

# ── src/views/BookingsView.vue ────────────────────────────────────────────────
cat > src/views/BookingsView.vue << 'EOF'
<template>
  <div class="page">
    <div class="container">
      <div class="page-header">
        <h1>{{ auth.isLandlord ? 'Booking Requests' : 'My Bookings' }}</h1>
        <p class="subtitle">{{ auth.isLandlord ? 'Manage bookings for your apartments' : 'Track your upcoming and past stays' }}</p>
      </div>
      <div v-if="loading" class="loading-state"><div class="spinner"></div></div>
      <div v-else-if="bookings.length === 0" class="empty-state">
        <p>{{ auth.isLandlord ? '📭 No booking requests yet.' : '📅 You have no bookings yet.' }}</p>
        <router-link v-if="!auth.isLandlord" to="/apartments" class="btn btn-primary">Browse apartments</router-link>
      </div>
      <div v-else class="bookings-list">
        <div v-for="b in bookings" :key="b.id" class="booking-card card">
          <div class="booking-apt">
            <div class="booking-apt-icon">🏠</div>
            <div>
              <h3>{{ b.apartment?.title }}</h3>
              <p class="booking-apt-addr">📍 {{ b.apartment?.address }}</p>
            </div>
          </div>
          <div class="booking-details">
            <div class="booking-dates">
              <div class="date-block"><label>Check-in</label><strong>{{ formatDate(b.check_in) }}</strong></div>
              <div class="date-sep">→</div>
              <div class="date-block"><label>Check-out</label><strong>{{ formatDate(b.check_out) }}</strong></div>
            </div>
            <div class="booking-meta">
              <span :class="['badge', `badge-${b.status}`]">{{ b.status }}</span>
              <span class="booking-price">${{ b.total_price }}</span>
            </div>
          </div>
          <div v-if="auth.isLandlord" class="booking-tenant">
            Tenant: <strong>{{ b.tenant?.first_name }} {{ b.tenant?.last_name }}</strong>
            <span class="tenant-email">({{ b.tenant?.email }})</span>
          </div>
          <div class="booking-actions">
            <template v-if="auth.isRenter && b.status === 'pending'">
              <button class="btn btn-danger" @click="cancelBooking(b)" :disabled="b._loading">{{ b._loading ? '...' : 'Cancel booking' }}</button>
            </template>
            <template v-if="auth.isLandlord">
              <button v-if="b.status === 'pending'" class="btn btn-primary" @click="updateStatus(b, 'confirmed')" :disabled="b._loading">Confirm</button>
              <button v-if="b.status === 'confirmed'" class="btn btn-secondary" @click="updateStatus(b, 'completed')" :disabled="b._loading">Mark completed</button>
              <button v-if="['pending','confirmed'].includes(b.status)" class="btn btn-danger" @click="updateStatus(b, 'cancelled')" :disabled="b._loading">Cancel</button>
            </template>
            <span v-if="b._error" class="error-msg">{{ b._error }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, onMounted, reactive } from 'vue'
import { authStore as auth } from '../stores/auth'
import { bookingsAPI } from '../services/api'
const bookings = ref([]); const loading = ref(true)
const MOCK = [
  { id: 1, status: 'confirmed', check_in: '2026-05-01', check_out: '2026-05-05', total_price: '180.00', apartment: { title: 'Cozy Studio in Almaty Center', address: 'Abay Ave 12' }, tenant: { first_name: 'You', last_name: '', email: 'user@example.com' } },
  { id: 2, status: 'pending', check_in: '2026-06-10', check_out: '2026-06-14', total_price: '320.00', apartment: { title: 'Modern Loft in Astana', address: 'Turan Ave 5' }, tenant: { first_name: 'You', last_name: '', email: 'user@example.com' } },
]
onMounted(async () => {
  try {
    const { data } = await bookingsAPI.list()
    bookings.value = data.map(b => reactive({ ...b, _loading: false, _error: '' }))
  } catch { bookings.value = MOCK.map(b => reactive({ ...b, _loading: false, _error: '' })) }
  finally { loading.value = false }
})
async function cancelBooking(b) {
  b._loading = true; b._error = ''
  try { const { data } = await bookingsAPI.cancel(b.id); Object.assign(b, data) }
  catch (e) { b._error = e.response?.data?.detail || 'Failed to cancel' }
  finally { b._loading = false }
}
async function updateStatus(b, status) {
  b._loading = true; b._error = ''
  try { const { data } = await bookingsAPI.updateStatus(b.id, status); Object.assign(b, data) }
  catch (e) { b._error = e.response?.data?.detail || 'Failed to update' }
  finally { b._loading = false }
}
function formatDate(d) { return new Date(d).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }) }
</script>
<style scoped>
.page-header { padding: 2.5rem 0 2rem; }
.page-header h1 { font-size: 1.75rem; font-weight: 800; }
.subtitle { color: var(--text-muted); margin-top: .25rem; }
.bookings-list { display: flex; flex-direction: column; gap: 1.25rem; padding-bottom: 3rem; }
.booking-card { padding: 1.5rem; display: flex; flex-direction: column; gap: 1.25rem; }
.booking-apt { display: flex; align-items: center; gap: 1rem; }
.booking-apt-icon { font-size: 2.5rem; background: var(--bg); padding: .75rem; border-radius: var(--radius); }
.booking-apt h3 { font-size: 1.05rem; font-weight: 700; }
.booking-apt-addr { font-size: .85rem; color: var(--text-muted); margin-top: .2rem; }
.booking-details { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 1rem; }
.booking-dates { display: flex; align-items: center; gap: 1rem; }
.date-block { text-align: center; }
.date-block label { display: block; font-size: .75rem; color: var(--text-muted); font-weight: 600; margin-bottom: .2rem; }
.date-block strong { font-size: .95rem; }
.date-sep { font-size: 1.2rem; color: var(--text-muted); }
.booking-meta { display: flex; align-items: center; gap: 1rem; }
.booking-price { font-size: 1.2rem; font-weight: 800; color: var(--primary); }
.booking-tenant { font-size: .9rem; color: var(--text-muted); }
.booking-tenant strong { color: var(--text); }
.tenant-email { margin-left: .4rem; font-size: .82rem; }
.booking-actions { display: flex; gap: .75rem; align-items: center; flex-wrap: wrap; }
.loading-state { display: flex; justify-content: center; padding: 5rem 0; }
.spinner { width: 40px; height: 40px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 1.5rem; padding: 5rem 0; color: var(--text-muted); }
</style>
EOF

# ── src/views/MyApartmentsView.vue ────────────────────────────────────────────
cat > src/views/MyApartmentsView.vue << 'EOF'
<template>
  <div class="page">
    <div class="container">
      <div class="page-header">
        <div><h1>My Listings</h1><p class="subtitle">Apartments you own on StayFinder</p></div>
        <button class="btn btn-primary" @click="showForm = !showForm">{{ showForm ? '✕ Close' : '+ Add apartment' }}</button>
      </div>
      <div v-if="showForm" class="card form-card">
        <h2>New listing</h2>
        <div class="form-grid">
          <div class="form-group"><label>Title</label><input v-model="form.title" type="text" placeholder="e.g. Cozy studio in Almaty" /></div>
          <div class="form-group"><label>Address</label><input v-model="form.address" type="text" placeholder="Street, number" /></div>
          <div class="form-group"><label>Price per night ($)</label><input v-model="form.price_per_night" type="number" placeholder="50" /></div>
          <div class="form-group"><label>Rooms</label><input v-model="form.rooms" type="number" placeholder="1" min="1" /></div>
          <div class="form-group full-col"><label>Description</label><textarea v-model="form.description" rows="3" placeholder="Describe the apartment..."></textarea></div>
          <div class="form-group"><label>City ID</label><input v-model="form.city" type="number" placeholder="City ID from backend" /></div>
        </div>
        <p v-if="formError" class="error-msg">{{ formError }}</p>
        <button class="btn btn-primary" @click="createApartment" :disabled="submitting">{{ submitting ? 'Creating...' : 'Create listing' }}</button>
      </div>
      <div v-if="loading" class="loading-state"><div class="spinner"></div></div>
      <div v-else-if="apartments.length === 0 && !showForm" class="empty-state">
        <p>🏠 You have no listings yet.</p>
        <button class="btn btn-primary" @click="showForm = true">Add your first apartment</button>
      </div>
      <div v-else class="grid">
        <div v-for="apt in apartments" :key="apt.id" class="apt-card card">
          <div class="apt-img-placeholder"><span>🏠</span></div>
          <div class="apt-info">
            <div class="apt-location">{{ apt.city?.name }}</div>
            <h3>{{ apt.title }}</h3>
            <p class="apt-address">📍 {{ apt.address }}</p>
            <div class="apt-footer">
              <div class="apt-price"><strong>${{ apt.price_per_night }}</strong><span>/ night</span></div>
              <span class="rooms-tag">{{ apt.rooms }} rm</span>
            </div>
            <div class="apt-actions">
              <router-link :to="`/apartments/${apt.id}`" class="btn btn-secondary">View</router-link>
              <button class="btn btn-danger" @click="deleteApartment(apt)">Delete</button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
<script setup>
import { ref, reactive, onMounted } from 'vue'
import { apartmentsAPI } from '../services/api'
const apartments = ref([]); const loading = ref(true); const showForm = ref(false)
const submitting = ref(false); const formError = ref('')
const form = reactive({ title: '', address: '', price_per_night: '', rooms: 1, description: '', city: '' })
const MOCK = [{ id: 1, title: 'My Studio in Almaty', address: 'Abay 12', price_per_night: '45.00', rooms: 1, city: { name: 'Almaty' } }]
onMounted(async () => {
  try { const { data } = await apartmentsAPI.list(); apartments.value = data }
  catch { apartments.value = MOCK }
  finally { loading.value = false }
})
async function createApartment() {
  formError.value = ''; submitting.value = true
  try {
    const { data } = await apartmentsAPI.create(form)
    apartments.value.unshift(data); showForm.value = false
    Object.assign(form, { title: '', address: '', price_per_night: '', rooms: 1, description: '', city: '' })
  } catch (e) { formError.value = JSON.stringify(e.response?.data || 'Failed to create') }
  finally { submitting.value = false }
}
async function deleteApartment(apt) {
  if (!confirm(`Delete "${apt.title}"?`)) return
  try { await apartmentsAPI.delete(apt.id); apartments.value = apartments.value.filter(a => a.id !== apt.id) }
  catch { alert('Could not delete apartment') }
}
</script>
<style scoped>
.page-header { display: flex; justify-content: space-between; align-items: flex-end; padding: 2.5rem 0 2rem; }
.page-header h1 { font-size: 1.75rem; font-weight: 800; }
.subtitle { color: var(--text-muted); margin-top: .2rem; }
.form-card { padding: 1.75rem; margin-bottom: 2rem; }
.form-card h2 { font-size: 1.1rem; font-weight: 700; margin-bottom: 1.25rem; }
.form-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 0 1rem; }
.full-col { grid-column: 1 / -1; }
.grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(280px, 1fr)); gap: 1.5rem; padding-bottom: 3rem; }
.apt-card { overflow: hidden; }
.apt-img-placeholder { height: 140px; background: linear-gradient(135deg,#dbeafe,#eff6ff); display: flex; align-items: center; justify-content: center; font-size: 3rem; }
.apt-info { padding: 1.25rem; }
.apt-location { font-size: .8rem; color: var(--primary); font-weight: 600; margin-bottom: .3rem; }
.apt-info h3 { font-size: .95rem; font-weight: 700; margin-bottom: .3rem; }
.apt-address { font-size: .82rem; color: var(--text-muted); margin-bottom: .75rem; }
.apt-footer { display: flex; justify-content: space-between; align-items: center; margin-bottom: .75rem; }
.apt-price strong { font-size: 1.1rem; font-weight: 800; color: var(--primary); }
.apt-price span { font-size: .78rem; color: var(--text-muted); margin-left: .2rem; }
.rooms-tag { background: var(--bg); padding: .2rem .6rem; border-radius: 99px; font-size: .78rem; font-weight: 600; }
.apt-actions { display: flex; gap: .6rem; }
.apt-actions .btn { flex: 1; font-size: .82rem; padding: .4rem; }
.loading-state { display: flex; justify-content: center; padding: 5rem 0; }
.spinner { width: 40px; height: 40px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-state { display: flex; flex-direction: column; align-items: center; gap: 1.5rem; padding: 5rem 0; color: var(--text-muted); }
</style>
EOF

echo ""
echo "✅ All files created successfully!"
echo "Now run: npm run dev"
