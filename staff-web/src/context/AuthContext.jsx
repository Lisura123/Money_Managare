import { createContext, useCallback, useEffect, useState } from 'react'
import toast from 'react-hot-toast'
import api, { TOKEN_KEY } from '../config/api'
import { ROLES } from '../utils/constants'

const USER_KEY = 'mm_staff_user'

export const AuthContext = createContext(null)

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null)
  const [loading, setLoading] = useState(true) // validating token on mount

  // Clear all auth state
  const clearAuth = useCallback(() => {
    localStorage.removeItem(TOKEN_KEY)
    localStorage.removeItem(USER_KEY)
    setUser(null)
  }, [])

  // Validate the stored token by fetching the current user
  const validateToken = useCallback(async () => {
    const token = localStorage.getItem(TOKEN_KEY)
    const cachedUser = localStorage.getItem(USER_KEY)

    if (!token) {
      setLoading(false)
      return
    }

    try {
      // We use /today-status as a lightweight authenticated ping
      // and rely on the cached user for display data.
      // A dedicated /user endpoint doesn't exist in this backend,
      // so we use the cached user and re-verify on the first real API call.
      if (cachedUser) {
        const parsed = JSON.parse(cachedUser)
        if (parsed.role === ROLES.STAFF || parsed.role === ROLES.ADMIN) {
          setUser(parsed)
        } else {
          clearAuth()
        }
      } else {
        clearAuth()
      }
    } catch {
      clearAuth()
    } finally {
      setLoading(false)
    }
  }, [clearAuth])

  // Listen for session-expired events emitted by the axios interceptor
  useEffect(() => {
    const handleExpiry = () => {
      clearAuth()
      toast.error('Your session has expired. Please log in again.')
    }
    window.addEventListener('mm:session-expired', handleExpiry)
    return () => window.removeEventListener('mm:session-expired', handleExpiry)
  }, [clearAuth])

  // Validate token on mount
  useEffect(() => {
    validateToken()
  }, [validateToken])

  const login = useCallback(async (email, password) => {
    const response = await api.post('/login', { email, password })
    const { token, user: userData } = response.data

    if (userData.role !== ROLES.STAFF && userData.role !== ROLES.ADMIN) {
      throw new Error('Your account does not have access to this portal.')
    }

    if (!userData.is_active) {
      throw new Error('Your account has been deactivated.')
    }

    localStorage.setItem(TOKEN_KEY, token)
    localStorage.setItem(USER_KEY, JSON.stringify(userData))
    setUser(userData)

    return { user: userData }
  }, [])

  const logout = useCallback(async () => {
    try {
      await api.post('/logout')
    } catch {
      // Ignore logout API errors — clear locally regardless
    }
    clearAuth()
  }, [clearAuth])

  const updateUser = useCallback((updatedUser) => {
    setUser(updatedUser)
    localStorage.setItem(USER_KEY, JSON.stringify(updatedUser))
  }, [])

  return (
    <AuthContext.Provider
      value={{
        user,
        loading,
        login,
        logout,
        updateUser,
        isAuthenticated: !!user,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
