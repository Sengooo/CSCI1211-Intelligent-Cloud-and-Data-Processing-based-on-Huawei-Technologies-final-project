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
.hero { background: linear-gradient(135deg, #2d9e4f 0%, #1a6b34 100%); color: white; padding: 4rem 0 3rem; margin-bottom: 2.5rem; }
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
.apt-img-placeholder { height: 100%; background: linear-gradient(135deg, #d1fae5 0%, #ecfdf5 100%); display: flex; flex-direction: column; align-items: center; justify-content: center; gap: .5rem; font-size: 3rem; }
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
