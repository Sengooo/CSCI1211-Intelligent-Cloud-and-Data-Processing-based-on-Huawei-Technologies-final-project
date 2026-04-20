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
