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
.apt-hero-img { height: 240px; background: linear-gradient(135deg, #d1fae5 0%, #ecfdf5 100%); display: flex; align-items: center; justify-content: center; font-size: 5rem; }
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
