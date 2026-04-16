import { useEffect, useState } from 'react'
import { BrowserRouter, Routes, Route, Navigate, Outlet } from 'react-router-dom'
import { Toaster } from 'react-hot-toast'
import { AuthProvider } from './context/AuthContext'
import { useAuth } from './hooks/useAuth'
import AppLayout from './components/layout/AppLayout'
import { FullPageSpinner } from './components/common/LoadingSpinner'
// Pages — public
import LoginPage from './pages/LoginPage'
import ForgotPasswordPage from './pages/ForgotPasswordPage'
import ResetPasswordPage from './pages/ResetPasswordPage'

// Pages — protected
import DashboardPage from './pages/DashboardPage'
import CashEntryPage from './pages/CashEntryPage'
import CardEntryPage from './pages/CardEntryPage'
import HistoryPage from './pages/HistoryPage'
import EditRequestPage from './pages/EditRequestPage'
import MyEditRequestsPage from './pages/MyEditRequestsPage'
import ChangePasswordPage from './pages/ChangePasswordPage'
import ProfilePage from './pages/ProfilePage'

// ─── Auth guard ───────────────────────────────────────────────────────────────

function RequireAuth() {
  const { isAuthenticated, loading } = useAuth()
  if (loading) return <FullPageSpinner />
  if (!isAuthenticated) return <Navigate to="/login" replace />
  return <Outlet />
}

function GuestOnly() {
  const { isAuthenticated, loading } = useAuth()
  if (loading) return <FullPageSpinner />
  if (isAuthenticated) return <Navigate to="/dashboard" replace />
  return <Outlet />
}

// ─── Connection banner ────────────────────────────────────────────────────────

function ConnectionBanner() {
  const [offline, setOffline] = useState(false)

  useEffect(() => {
    let timer

    async function check() {
      try {
        const base = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000/api'
        const res = await fetch(`${base}/login`, { method: 'HEAD', signal: AbortSignal.timeout(4000) })
        // Any HTTP response means the server is reachable
        setOffline(!res || res.status === 0)
      } catch {
        setOffline(true)
      }
    }

    check()
    timer = setInterval(check, 30000)
    return () => clearInterval(timer)
  }, [])

  if (!offline) return null

  return (
    <div className="fixed top-0 inset-x-0 z-[9999] bg-error text-white text-sm text-center py-2 px-4">
      Unable to reach the server. Check your connection.
    </div>
  )
}

// ─── App shell ────────────────────────────────────────────────────────────────

function AppRoutes() {
  return (
    <Routes>
      {/* Guest-only routes */}
      <Route element={<GuestOnly />}>
        <Route path="/login" element={<LoginPage />} />
        <Route path="/forgot-password" element={<ForgotPasswordPage />} />
        <Route path="/reset-password" element={<ResetPasswordPage />} />
      </Route>

      {/* Protected routes */}
      <Route element={<RequireAuth />}>
        <Route element={<AppLayout />}>
          <Route index element={<Navigate to="/dashboard" replace />} />
          <Route path="/dashboard" element={<DashboardPage />} />
          <Route path="/cash-entry/:accountType" element={<CashEntryPage />} />
          <Route path="/card-entry" element={<CardEntryPage />} />
          <Route path="/history" element={<HistoryPage />} />
          <Route path="/edit-request/:entryType/:entryId" element={<EditRequestPage />} />
          <Route path="/edit-requests" element={<MyEditRequestsPage />} />
          <Route path="/change-password" element={<ChangePasswordPage />} />
          <Route path="/profile" element={<ProfilePage />} />
        </Route>
      </Route>

      {/* Catch-all */}
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  )
}

export default function App() {
  return (
    <BrowserRouter future={{ v7_startTransition: true, v7_relativeSplatPath: true }}>
      <AuthProvider>
        <Toaster
          position="top-right"
          toastOptions={{
            duration: 4000,
            style: {
              borderRadius: '10px',
              fontFamily: 'Inter, sans-serif',
              fontSize: '14px',
            },
            success: {
              iconTheme: { primary: '#00BFA6', secondary: '#fff' },
            },
            error: {
              iconTheme: { primary: '#EF5363', secondary: '#fff' },
            },
          }}
        />
        <ConnectionBanner />
        <AppRoutes />
      </AuthProvider>
    </BrowserRouter>
  )
}
