import { useState } from 'react'
import { MdVisibility, MdVisibilityOff, MdLock } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../components/common/PageHeader'
import Card from '../components/common/Card'
import api from '../config/api'
import { ENDPOINTS } from '../utils/constants'
import { getPasswordStrength } from '../utils/validators'

function PasswordField({ id, label, value, onChange, showToggle, show, onToggle, error, hint }) {
  return (
    <div>
      <label htmlFor={id} className="form-label">
        {label}
      </label>
      <div className="relative">
        <input
          id={id}
          type={show ? 'text' : 'password'}
          value={value}
          onChange={onChange}
          autoComplete={id === 'current_password' ? 'current-password' : 'new-password'}
          className={`form-input pr-10 ${error ? 'border-error focus:ring-error' : ''}`}
        />
        {showToggle && (
          <button
            type="button"
            onClick={onToggle}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
            aria-label={show ? 'Hide password' : 'Show password'}
          >
            {show ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
          </button>
        )}
      </div>
      {hint && !error && (
        <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">{hint}</p>
      )}
      {error && <p className="form-error">{error}</p>}
    </div>
  )
}

function StrengthBar({ password }) {
  if (!password) return null
  const { score, label, color } = getPasswordStrength(password)
  const segments = 4
  const colors = ['bg-error', 'bg-warning', 'bg-teal', 'bg-success']
  const barColor = score <= 1 ? colors[0] : score === 2 ? colors[1] : score === 3 ? colors[2] : colors[3]

  return (
    <div className="mt-2">
      <div className="flex gap-1 mb-1">
        {Array.from({ length: segments }).map((_, i) => (
          <div
            key={i}
            className={`h-1.5 flex-1 rounded-full transition-colors ${
              i < score ? barColor : 'bg-gray-200 dark:bg-white/10'
            }`}
          />
        ))}
      </div>
      <p className={`text-xs font-medium`} style={{ color: score <= 1 ? '#EF5363' : score === 2 ? '#FFC107' : score === 3 ? '#00BFA6' : '#4CAF50' }}>
        {label}
      </p>
    </div>
  )
}

export default function ChangePasswordPage() {
  const [form, setForm] = useState({
    current_password: '',
    new_password: '',
    confirm_password: '',
  })
  const [show, setShow] = useState({
    current: false,
    new: false,
    confirm: false,
  })
  const [errors, setErrors] = useState({})
  const [submitting, setSubmitting] = useState(false)

  const update = (field) => (e) => {
    setForm((prev) => ({ ...prev, [field]: e.target.value }))
    if (errors[field]) setErrors((prev) => ({ ...prev, [field]: '' }))
  }

  const toggleShow = (field) =>
    setShow((prev) => ({ ...prev, [field]: !prev[field] }))

  const validate = () => {
    const errs = {}
    if (!form.current_password) errs.current_password = 'Current password is required.'
    if (!form.new_password) {
      errs.new_password = 'New password is required.'
    } else if (form.new_password.length < 8) {
      errs.new_password = 'Password must be at least 8 characters.'
    }
    if (!form.confirm_password) {
      errs.confirm_password = 'Please confirm your new password.'
    } else if (form.new_password !== form.confirm_password) {
      errs.confirm_password = 'Passwords do not match.'
    }
    return errs
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const errs = validate()
    if (Object.keys(errs).length > 0) {
      setErrors(errs)
      return
    }
    setSubmitting(true)
    try {
      await api.post(ENDPOINTS.CHANGE_PASSWORD, {
        current_password: form.current_password,
        new_password: form.new_password,
        new_password_confirmation: form.confirm_password,
      })
      toast.success('Password changed successfully.')
      setForm({ current_password: '', new_password: '', confirm_password: '' })
      setErrors({})
    } catch (err) {
      const data = err.response?.data
      if (err.response?.status === 422 && data?.errors) {
        const fieldErrors = {}
        for (const [key, msgs] of Object.entries(data.errors)) {
          fieldErrors[key] = Array.isArray(msgs) ? msgs[0] : msgs
        }
        setErrors(fieldErrors)
      } else if (data?.message) {
        toast.error(data.message)
      } else {
        toast.error('Failed to change password. Please try again.')
      }
    } finally {
      setSubmitting(false)
    }
  }

  return (
    <div className="max-w-md mx-auto space-y-6 animate-fade-in">
      <PageHeader
        title="Change Password"
        subtitle="Keep your account secure with a strong password."
      />

      <Card>
        <div className="flex justify-center mb-6">
          <div className="w-16 h-16 rounded-full bg-navy/10 dark:bg-teal/10 flex items-center justify-center">
            <MdLock className="w-8 h-8 text-navy dark:text-teal" />
          </div>
        </div>

        <form onSubmit={handleSubmit} className="space-y-5" noValidate>
          <PasswordField
            id="current_password"
            label="Current Password"
            value={form.current_password}
            onChange={update('current_password')}
            showToggle
            show={show.current}
            onToggle={() => toggleShow('current')}
            error={errors.current_password}
          />

          <div>
            <PasswordField
              id="new_password"
              label="New Password"
              value={form.new_password}
              onChange={update('new_password')}
              showToggle
              show={show.new}
              onToggle={() => toggleShow('new')}
              error={errors.new_password}
              hint="At least 8 characters."
            />
            <StrengthBar password={form.new_password} />
          </div>

          <PasswordField
            id="confirm_password"
            label="Confirm New Password"
            value={form.confirm_password}
            onChange={update('confirm_password')}
            showToggle
            show={show.confirm}
            onToggle={() => toggleShow('confirm')}
            error={errors.confirm_password}
          />

          <button
            type="submit"
            disabled={submitting}
            className="btn-primary w-full mt-2"
          >
            {submitting ? 'Changing...' : 'Change Password'}
          </button>
        </form>
      </Card>
    </div>
  )
}
