<template>
  <div class="page">
    <div class="container">
      <div class="page-header">
        <div><h1>My Listings</h1><p class="subtitle">Apartments you own on QazBook.kz</p></div>
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
.apt-img-placeholder { height: 140px; background: linear-gradient(135deg,#d1fae5,#ecfdf5); display: flex; align-items: center; justify-content: center; font-size: 3rem; }
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
