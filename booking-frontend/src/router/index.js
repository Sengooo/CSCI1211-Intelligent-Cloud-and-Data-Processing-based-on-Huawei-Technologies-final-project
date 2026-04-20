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
