<template>
  <div class="auth-page">
    <div class="auth-card card">
      <div class="auth-header">
        <h1>Create account</h1>
        <p>Join QazBook.kz today</p>
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
