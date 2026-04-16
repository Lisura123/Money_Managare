import { useCallback, useRef, useState } from 'react'
import toast from 'react-hot-toast'
import { MdVisibility, MdVisibilityOff } from 'react-icons/md'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import api from '../config/api'
import LoadingSpinner from '../components/common/LoadingSpinner'
import { APP_NAME } from '../utils/constants'

export default function ResetPasswordPage() {
  const { state } = useLocation()
  const navigate = useNavigate()

  const [email, setEmail] = useState(state?.email || '')
  const [code, setCode] = useState(['', '', '', '', '', ''])
  const [newPassword, setNewPassword] = useState('')
  const [confirmPassword, setConfirmPassword] = useState('')
  const [showNew, setShowNew] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)
  const [loading, setLoading] = useState(false)
  const [errors, setErrors] = useState({})
  const inputRefs = useRef([])

  const handleCodeChange = useCallback((idx, value) => {
    const val = value.replace(/\D/g, '').slice(-1)
    const next = [...code]
    next[idx] = val
    setCode(next)
    if (val && idx < 5) {
      inputRefs.current[idx + 1]?.focus()
    }
  }, [code])

  const handleCodeKeyDown = useCallback((idx, e) => {
    if (e.key === 'Backspace' && !code[idx] && idx > 0) {
      inputRefs.current[idx - 1]?.focus()
    }
    if (e.key === 'ArrowLeft' && idx > 0) inputRefs.current[idx - 1]?.focus()
    if (e.key === 'ArrowRight' && idx < 5) inputRefs.current[idx + 1]?.focus()
  }, [code])

  const handleCodePaste = useCallback((e) => {
    e.preventDefault()
    const pasted = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6)
    const next = [...code]
    for (let i = 0; i < pasted.length; i++) {
      next[i] = pasted[i]
    }
    setCode(next)
    inputRefs.current[Math.min(pasted.length, 5)]?.focus()
  }, [code])

  const handleSubmit = useCallback(
    async (e) => {
      e.preventDefault()
      const errs = {}
      const codeStr = code.join('')

      if (!email.trim()) errs.email = 'Email is required.'
      if (codeStr.length !== 6) errs.code = 'Please enter the 6-digit code.'
      if (!newPassword || newPassword.length < 8) errs.newPassword = 'Password must be at least 8 characters.'
      if (newPassword !== confirmPassword) errs.confirmPassword = 'Passwords do not match.'

      if (Object.keys(errs).length > 0) {
        setErrors(errs)
        return
      }
      setErrors({})
      setLoading(true)

      try {
        await api.post('/reset-password', {
          email: email.trim(),
          code: codeStr,
          password: newPassword,
          password_confirmation: confirmPassword,
        })
        toast.success('Password reset successfully! Please sign in with your new password.')
        navigate('/login')
      } catch (err) {
        const apiErrors = err.response?.data?.errors || {}
        const mapped = {}
        if (apiErrors.email) mapped.email = apiErrors.email[0]
        if (apiErrors.code) mapped.code = apiErrors.code[0]
        if (apiErrors.password) mapped.newPassword = apiErrors.password[0]
        if (Object.keys(mapped).length > 0) {
          setErrors(mapped)
        } else {
          toast.error(err.response?.data?.message || 'Reset failed. Please try again.')
        }
      } finally {
        setLoading(false)
      }
    },
    [code, email, newPassword, confirmPassword, navigate],
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
            Reset your password
          </h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-6">
            Enter the 6-digit code from your email, then choose a new password.
          </p>

          <form onSubmit={handleSubmit} noValidate className="space-y-5">
            {/* Email (editable in case user navigated directly) */}
            <div>
              <label htmlFor="email" className="form-label">Email address</label>
              <input
                id="email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="form-input"
                placeholder="you@example.com"
              />
              {errors.email && <p className="form-error">{errors.email}</p>}
            </div>

            {/* 6-digit OTP boxes */}
            <div>
              <label className="form-label">Reset Code</label>
              <div className="flex gap-2 justify-between" onPaste={handleCodePaste}>
                {code.map((digit, idx) => (
                  <input
                    key={idx}
                    ref={(el) => (inputRefs.current[idx] = el)}
                    type="text"
                    inputMode="numeric"
                    maxLength={1}
                    value={digit}
                    onChange={(e) => handleCodeChange(idx, e.target.value)}
                    onKeyDown={(e) => handleCodeKeyDown(idx, e)}
                    className="otp-input"
                  />
                ))}
              </div>
              {errors.code && <p className="form-error mt-1">{errors.code}</p>}
            </div>

            {/* New password */}
            <div>
              <label htmlFor="newPassword" className="form-label">New Password</label>
              <div className="relative">
                <input
                  id="newPassword"
                  type={showNew ? 'text' : 'password'}
                  value={newPassword}
                  onChange={(e) => setNewPassword(e.target.value)}
                  placeholder="••••••••"
                  className="form-input pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowNew((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400"
                  tabIndex={-1}
                >
                  {showNew ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
                </button>
              </div>
              {errors.newPassword && <p className="form-error">{errors.newPassword}</p>}
            </div>

            {/* Confirm password */}
            <div>
              <label htmlFor="confirmPassword" className="form-label">Confirm New Password</label>
              <div className="relative">
                <input
                  id="confirmPassword"
                  type={showConfirm ? 'text' : 'password'}
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  placeholder="••••••••"
                  className="form-input pr-10"
                />
                <button
                  type="button"
                  onClick={() => setShowConfirm((v) => !v)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400"
                  tabIndex={-1}
                >
                  {showConfirm ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
                </button>
              </div>
              {errors.confirmPassword && <p className="form-error">{errors.confirmPassword}</p>}
            </div>

            <button
              type="submit"
              disabled={loading}
              className="btn-accent w-full py-3 justify-center"
            >
              {loading ? <LoadingSpinner size="sm" /> : 'Reset Password'}
            </button>
          </form>

          <div className="mt-6 text-center">
            <Link to="/login" className="text-sm text-teal hover:underline">
              ← Back to sign in
            </Link>
          </div>
        </div>
      </div>
    </div>
  )
}
