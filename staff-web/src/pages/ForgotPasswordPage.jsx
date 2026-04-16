import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import { Link, useNavigate } from 'react-router-dom'
import api from '../config/api'
import LoadingSpinner from '../components/common/LoadingSpinner'
import { APP_NAME } from '../utils/constants'
import { isValidEmail } from '../utils/validators'

export default function ForgotPasswordPage() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  const handleSubmit = useCallback(
    async (e) => {
      e.preventDefault()
      setError('')

      if (!email.trim() || !isValidEmail(email)) {
        setError('Please enter a valid email address.')
        return
      }

      setLoading(true)
      try {
        await api.post('/forgot-password', { email: email.trim() })
        toast.success('Reset code sent! Check your email.')
        navigate('/reset-password', { state: { email: email.trim() } })
      } catch (err) {
        setError(err.response?.data?.message || 'Failed to send reset email. Please try again.')
      } finally {
        setLoading(false)
      }
    },
    [email, navigate],
  )

  return (
    <div className="min-h-screen bg-navy dark:bg-navy-dark flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <div className="w-16 h-16 rounded-2xl bg-teal mx-auto flex items-center justify-center mb-4">
            <span className="text-white font-heading font-bold text-2xl">M</span>
          </div>
          <h1 className="font-heading font-bold text-white text-2xl">{APP_NAME}</h1>
        </div>

        <div className="bg-white dark:bg-navy rounded-2xl shadow-2xl p-8">
          <h2 className="font-heading font-semibold text-gray-900 dark:text-white text-xl mb-2">
            Forgot your password?
          </h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">
            Enter your email address and we'll send you a reset code.
          </p>

          <form onSubmit={handleSubmit} noValidate className="space-y-4">
            <div>
              <label htmlFor="email" className="form-label">
                Email address
              </label>
              <input
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
              />
            </div>

            {error && (
              <div className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/30 rounded-lg px-4 py-3 text-sm text-error">
                {error}
              </div>
            )}

            <button
              type="submit"
              disabled={loading}
              className="btn-accent w-full py-3 justify-center"
            >
              {loading ? <LoadingSpinner size="sm" /> : 'Send Reset Code'}
            </button>
          </form>

          <div className="mt-6 text-center">
            <Link
              to="/login"
              className="text-sm text-teal hover:underline"
            >
              ← Back to sign in
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
