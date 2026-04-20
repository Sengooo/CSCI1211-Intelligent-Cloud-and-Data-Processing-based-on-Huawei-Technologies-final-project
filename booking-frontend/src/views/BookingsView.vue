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
