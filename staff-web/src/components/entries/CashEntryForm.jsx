import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import {
  MdCalendarToday,
  MdNotes,
} from 'react-icons/md'
import api from '../../config/api'
import { useFormValidation } from '../../hooks/useFormValidation'
import { todayString, getDayName, formatCurrency } from '../../utils/formatters'
import { validateCashEntry } from '../../utils/validators'
import { ACCOUNT_TYPE_LABELS } from '../../utils/constants'
import LoadingSpinner from '../common/LoadingSpinner'

export default function CashEntryForm({ accountType, onSuccess }) {
  const [submitting, setSubmitting] = useState(false)
  const [rawAmount, setRawAmount] = useState('')

  const { values, errors, handleChange, setValue, setFieldErrors, runValidation } =
    useFormValidation(
      { entry_date: todayString(), cash_amount: '', notes: '' },
      validateCashEntry,
    )

  const handleAmountChange = useCallback(
    (e) => {
      const raw = e.target.value.replace(/[^0-9]/g, '')
      setRawAmount(raw)
      setValue('cash_amount', raw)
    },
    [setValue],
  )

  const handleSubmit = useCallback(
    async (e) => {
      e.preventDefault()
      if (!runValidation()) return

      const amount = parseFloat(values.cash_amount)
      if (amount >= 1_000_000) {
        const confirmed = window.confirm(
          `You entered ${formatCurrency(amount)}. Are you sure this amount is correct?`
        )
        if (!confirmed) return
      }

      setSubmitting(true)
      try {
        await api.post('/cash-entries', {
          entry_date: values.entry_date,
          cash_amount: amount,
          notes: values.notes || null,
          cash_account_type: accountType,
        })
        toast.success('Cash entry submitted successfully!')
        onSuccess?.()
      } catch (err) {
        const status = err.response?.status
        if (status === 422) {
          const apiErrors = err.response.data.errors || {}
          const mapped = {}
          if (apiErrors.entry_date) mapped.entry_date = apiErrors.entry_date[0]
          if (apiErrors.cash_amount) mapped.cash_amount = apiErrors.cash_amount[0]
          if (apiErrors.notes) mapped.notes = apiErrors.notes[0]
          setFieldErrors(mapped)
          toast.error('Please fix the errors below.')
        } else {
          toast.error(err.response?.data?.message || 'Submission failed. Please try again.')
        }
      } finally {
        setSubmitting(false)
      }
    },
    [values, accountType, runValidation, setFieldErrors, onSuccess],
  )

  const accountLabel = ACCOUNT_TYPE_LABELS[accountType] || 'Account'
  const dayName = getDayName(values.entry_date)
  const displayAmount = rawAmount
    ? new Intl.NumberFormat('en-US').format(parseFloat(rawAmount))
    : ''

  return (
    <form onSubmit={handleSubmit} noValidate className="space-y-5">
      {/* Account type badge */}
      <div>
        <span
          className={`status-badge text-sm px-3 py-1 ${
            accountType === 'mano'
              ? 'bg-purple-100 text-purple-800 dark:bg-purple-500/20 dark:text-purple-300'
              : 'bg-teal/10 text-teal dark:bg-teal/20'
          }`}
        >
          {accountLabel}
        </span>
      </div>

      {/* Date field */}
      <div>
        <label htmlFor="entry_date" className="form-label">
          <MdCalendarToday className="inline w-4 h-4 mr-1 mb-0.5" />
          Date
        </label>
        <div className="flex items-center gap-3">
          <input
            type="date"
            id="entry_date"
            name="entry_date"
            value={values.entry_date}
            max={todayString()}
            onChange={handleChange}
            className="form-input max-w-[180px]"
          />
          {dayName && (
            <span className="text-sm text-gray-500 dark:text-gray-400 font-medium">{dayName}</span>
          )}
        </div>
        {errors.entry_date && <p className="form-error">{errors.entry_date}</p>}
      </div>

      {/* Amount field */}
      <div>
        <label htmlFor="cash_amount" className="form-label">
          Amount
        </label>
        <div className="relative">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 text-sm font-medium select-none">
            Rs.
          </span>
          <input
            type="text"
            id="cash_amount"
            name="cash_amount"
            inputMode="numeric"
            value={displayAmount}
            placeholder="0"
            onChange={handleAmountChange}
            className={`form-input pl-10 ${errors.cash_amount ? 'border-error focus:ring-error' : ''}`}
          />
        </div>
        {errors.cash_amount && <p className="form-error">{errors.cash_amount}</p>}
      </div>

      {/* Notes field */}
      <div>
        <label htmlFor="notes" className="form-label">
          <MdNotes className="inline w-4 h-4 mr-1 mb-0.5" />
          Notes{' '}
          <span className="text-gray-400 font-normal">(optional)</span>
        </label>
        <textarea
          id="notes"
          name="notes"
          value={values.notes}
          onChange={handleChange}
          maxLength={500}
          rows={3}
          placeholder="Any additional details..."
          className="form-input resize-none"
        />
        <p className="text-xs text-gray-400 text-right mt-1">
          {values.notes.length}/500
        </p>
        {errors.notes && <p className="form-error">{errors.notes}</p>}
      </div>

      {/* Submit */}
      <button
        type="submit"
        disabled={submitting}
        className="btn-primary w-full py-3 text-base justify-center"
      >
        {submitting ? <LoadingSpinner size="sm" /> : 'Submit Entry'}
      </button>
    </form>
  )
}
