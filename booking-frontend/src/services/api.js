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
