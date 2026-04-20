<template>
  <div id="app">
    <nav class="navbar">
      <router-link to="/apartments" class="logo">
        <span class="logo-icon">⬡</span> QazBook.kz
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
  --primary: #2d9e4f; --primary-dark: #1f7a3a;
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
