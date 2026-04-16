import { todayString } from './formatters'

/**
 * Validate an email address.
 */
export function isValidEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)
}

/**
 * Validate that a password meets minimum requirements.
 * Returns an array of error strings (empty if valid).
 */
export function validatePassword(password) {
  const errors = []
  if (!password || password.length < 8) {
    errors.push('Password must be at least 8 characters.')
  }
  return errors
}

/**
 * Get password strength score 0-4 and label.
 */
export function getPasswordStrength(password) {
  if (!password) return { score: 0, label: '', color: '' }
  let score = 0
  if (password.length >= 8) score++
  if (password.length >= 12) score++
  if (/[A-Z]/.test(password) && /[a-z]/.test(password)) score++
  if (/\d/.test(password)) score++
  if (/[^A-Za-z0-9]/.test(password)) score++

  const clampedScore = Math.min(score, 4)
  const labels = ['', 'Weak', 'Fair', 'Good', 'Strong']
  const colors = ['', 'bg-error', 'bg-warning', 'bg-blue-400', 'bg-success']

  return {
    score: clampedScore,
    label: labels[clampedScore],
    color: colors[clampedScore],
  }
}

/**
 * Validate a cash entry form.
 * Returns { isValid: boolean, errors: { field: message } }
 */
export function validateCashEntry({ entry_date, cash_amount }) {
  const errors = {}
  if (!entry_date) {
    errors.entry_date = 'Date is required.'
  } else if (entry_date > todayString()) {
    errors.entry_date = 'Cannot select a future date.'
  }
  if (!cash_amount || cash_amount === '') {
    errors.cash_amount = 'Amount is required.'
  } else if (isNaN(parseFloat(cash_amount)) || parseFloat(cash_amount) <= 0) {
    errors.cash_amount = 'Amount must be a positive number.'
  }
  return { isValid: Object.keys(errors).length === 0, errors }
}

/**
 * Validate a card entry form.
 */
export function validateCardEntry({ card_account_id, entry_date, amount }) {
  const errors = {}
  if (!card_account_id) {
    errors.card_account_id = 'Please select a card account.'
  }
  if (!entry_date) {
    errors.entry_date = 'Date is required.'
  } else if (entry_date > todayString()) {
    errors.entry_date = 'Cannot select a future date.'
  }
  if (!amount || amount === '') {
    errors.amount = 'Amount is required.'
  } else if (isNaN(parseFloat(amount)) || parseFloat(amount) <= 0) {
    errors.amount = 'Amount must be a positive number.'
  }
  return { isValid: Object.keys(errors).length === 0, errors }
}

/**
 * Validate an edit request form.
 */
export function validateEditRequest({ requested_amount, reason }) {
  const errors = {}
  if (!requested_amount || requested_amount === '') {
    errors.amount = 'Amount is required.'
  } else if (isNaN(parseFloat(requested_amount)) || parseFloat(requested_amount) <= 0) {
    errors.amount = 'Amount must be a positive number.'
  }
  if (!reason || reason.trim().length < 10) {
    errors.reason = 'Reason must be at least 10 characters.'
  }
  return { isValid: Object.keys(errors).length === 0, errors }
}
