<template>
  <div class="auth-page">
    <div class="auth-card card">
      <div class="auth-header">
        <h1>Welcome back</h1>
        <p>Sign in to your QazBook.kz account</p>
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
