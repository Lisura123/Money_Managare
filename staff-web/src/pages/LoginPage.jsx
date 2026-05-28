import { useCallback, useEffect, useRef, useState } from 'react'
import toast from 'react-hot-toast'
import { MdVisibility, MdVisibilityOff } from 'react-icons/md'
import { Link, useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { APP_NAME } from '../utils/constants'
import LoadingSpinner from '../components/common/LoadingSpinner'

export default function LoginPage() {
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const emailRef = useRef(null)

  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  useEffect(() => {
    if (isAuthenticated) navigate('/dashboard', { replace: true })
  }, [isAuthenticated, navigate])

  useEffect(() => {
    emailRef.current?.focus()
  }, [])

  const handleSubmit = useCallback(
    async (e) => {
      e.preventDefault()
      setError('')

      if (!email.trim() || !password) {
        setError('Please enter your email and password.')
        return
      }

      setLoading(true)
      try {
        const result = await login(email.trim(), password)
        toast.success(`Welcome back, ${result.user.name}!`)
        if (result.user.role === 'admin') {
          navigate('/admin/dashboard', { replace: true })
        } else {
          navigate('/dashboard', { replace: true })
        }
      } catch (err) {
        setError(err.response?.data?.message || err.message || 'Login failed. Please try again.')
      } finally {
        setLoading(false)
      }
    },
    [email, password, login, navigate],
  )

  return (
    <div className="min-h-screen bg-navy dark:bg-navy-dark flex items-center justify-center p-4">
      {/* Background decoration */}
      <div className="absolute top-0 left-0 w-full h-full overflow-hidden pointer-events-none">
        <div className="absolute -top-32 -left-32 w-96 h-96 bg-teal/10 rounded-full blur-3xl" />
        <div className="absolute -bottom-40 -right-40 w-[500px] h-[500px] bg-teal/5 rounded-full blur-3xl" />
      </div>

      <div className="relative w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-teal mx-auto flex items-center justify-center mb-4 shadow-lg">
            <span className="text-white font-heading font-bold text-2xl">M</span>
          </div>
          <h1 className="font-heading font-bold text-white text-2xl">{APP_NAME}</h1>
          <p className="text-slate-400 text-sm mt-1">Staff Portal</p>
        </div>

        {/* Login card */}
        <div className="bg-white dark:bg-navy rounded-2xl shadow-2xl p-8">
          <>
              <h2 className="font-heading font-semibold text-gray-900 dark:text-white text-xl mb-6">
                Sign in to your account
              </h2>

              <form onSubmit={handleSubmit} noValidate className="space-y-4">
                <div>
                  <label htmlFor="email" className="form-label">
                    Email address
                  </label>
                  <input
                    ref={emailRef}
                    id="email"
                    type="email"
                    autoComplete="email"
                    value={email}
                    onChange={(e) => {
                      setEmail(e.target.value)
                      setError('')
                    }}
                    placeholder="you@example.com"
                    className="form-input"
                    disabled={loading}
                  />
                </div>

                <div>
                  <label htmlFor="password" className="form-label">
                    Password
                  </label>
                  <div className="relative">
                    <input
                      id="password"
                      type={showPassword ? 'text' : 'password'}
                      autoComplete="current-password"
                      value={password}
                      onChange={(e) => {
                        setPassword(e.target.value)
                        setError('')
                      }}
                      placeholder="••••••••"
                      className="form-input pr-10"
                      disabled={loading}
                    />
                    <button
                      type="button"
                      onClick={() => setShowPassword((v) => !v)}
                      className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
                      tabIndex={-1}
                    >
                      {showPassword ? (
                        <MdVisibilityOff className="w-5 h-5" />
                      ) : (
                        <MdVisibility className="w-5 h-5" />
                      )}
                    </button>
                  </div>
                </div>

                {error && (
                  <div className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/30 rounded-lg px-4 py-3 text-sm text-error">
                    {error}
                  </div>
                )}

                <div className="flex justify-end">
                  <Link
                    to="/forgot-password"
                    className="text-sm text-teal hover:underline font-medium"
                  >
                    Forgot password?
                  </Link>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="btn-accent w-full py-3 text-base justify-center mt-2"
                >
                  {loading ? <LoadingSpinner size="sm" /> : 'Sign In'}
                </button>
              </form>
          </>
        </div>

        <p className="text-center text-slate-500 text-xs mt-6">
          Money Manager · CameraLK
        </p>
      </div>
    </div>
  )
}
