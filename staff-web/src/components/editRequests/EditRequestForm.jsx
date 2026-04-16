import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import { MdNotes } from 'react-icons/md'
import { useNavigate } from 'react-router-dom'
import api from '../../config/api'
import { EDIT_REQUEST_REASONS } from '../../utils/constants'
import { calcDiff, formatCurrency } from '../../utils/formatters'
import { validateEditRequest } from '../../utils/validators'
import LoadingSpinner from '../common/LoadingSpinner'

export default function EditRequestForm({ entry, entryType }) {
  const navigate = useNavigate()
  const [submitting, setSubmitting] = useState(false)

  const originalAmount =
    entryType === 'cash' ? entry.cash_amount : entry.amount

  const [requestedAmount, setRequestedAmount] = useState(String(originalAmount || ''))
  const [notes, setNotes] = useState(entry.notes || '')
  const [reason, setReason] = useState('')
  const [errors, setErrors] = useState({})

  const diff = calcDiff(originalAmount, requestedAmount)

  const handleReasonChip = useCallback((chip) => {
    setReason(chip)
    if (errors.reason) setErrors((e) => ({ ...e, reason: undefined }))
  }, [errors])

  const handleSubmit = useCallback(
    async (e) => {
      e.preventDefault()
      const { isValid, errors: valErrors } = validateEditRequest({
        requested_amount: requestedAmount,
        reason,
      })
      if (!isValid) {
        setErrors(valErrors)
        return
      }

      setSubmitting(true)
      try {
        const requestedChanges =
          entryType === 'cash'
            ? { cash_amount: parseFloat(requestedAmount), notes: notes || null }
            : { amount: parseFloat(requestedAmount), notes: notes || null }

        await api.post('/edit-requests', {
          requestable_type: entryType === 'cash' ? 'daily_cash_entries' : 'daily_card_entries',
          requestable_id: entry.id,
          requested_changes: requestedChanges,
          reason,
        })
        toast.success('Edit request submitted!')
        navigate('/edit-requests')
      } catch (err) {
        const status = err.response?.status
        if (status === 422) {
          const apiErrors = err.response.data.errors || {}
          const mapped = {}
          if (apiErrors.reason) mapped.reason = apiErrors.reason[0]
          if (apiErrors['requested_changes.cash_amount'] || apiErrors['requested_changes.amount']) {
            mapped.amount = (apiErrors['requested_changes.cash_amount'] || apiErrors['requested_changes.amount'])[0]
          }
          setErrors(mapped)
        } else if (status === 409) {
          toast.error('A pending edit request already exists for this entry.')
        } else {
          toast.error(err.response?.data?.message || 'Failed to submit request.')
        }
      } finally {
        setSubmitting(false)
      }
    },
    [requestedAmount, notes, reason, entryType, entry.id, navigate],
  )

  return (
    <form onSubmit={handleSubmit} noValidate className="space-y-6">
      {/* Original entry (read-only) */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">
          Current Entry
        </p>
        <div className="border-2 border-gray-200 dark:border-gray-600 rounded-xl p-4 bg-gray-50 dark:bg-white/3 space-y-2">
          <div className="flex items-center justify-between">
            <span className="text-sm text-gray-500 dark:text-gray-400">Amount</span>
            <span className="font-semibold text-gray-800 dark:text-gray-200">
              {formatCurrency(originalAmount)}
            </span>
          </div>
          {entry.notes && (
            <div className="flex items-start justify-between gap-4">
              <span className="text-sm text-gray-500 dark:text-gray-400">Notes</span>
              <span className="text-sm text-gray-700 dark:text-gray-300 text-right max-w-[240px]">
                {entry.notes}
              </span>
            </div>
          )}
        </div>
      </div>

      {/* Requested changes */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">
          Your Changes
        </p>
        <div className="space-y-4">
          <div>
            <label className="form-label">New Amount</label>
            <div className="relative">
              <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 text-sm font-medium select-none">
                Rs.
              </span>
              <input
                type="text"
                inputMode="numeric"
                value={requestedAmount}
                onChange={(e) => {
                  const raw = e.target.value.replace(/[^0-9.]/g, '')
                  setRequestedAmount(raw)
                  if (errors.amount) setErrors((er) => ({ ...er, amount: undefined }))
                }}
                className={`form-input pl-10 ${errors.amount ? 'border-error' : ''}`}
                placeholder="0"
              />
            </div>
            {errors.amount && <p className="form-error">{errors.amount}</p>}
          </div>

          <div>
            <label className="form-label">
              <MdNotes className="inline w-4 h-4 mr-1 mb-0.5" />
              Updated Notes <span className="text-gray-400 font-normal">(optional)</span>
            </label>
            <textarea
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              maxLength={500}
              rows={3}
              className="form-input resize-none"
              placeholder="Updated notes..."
            />
          </div>
        </div>

        {/* Diff preview */}
        {!diff.same && (
          <div className="mt-3 bg-gray-50 dark:bg-white/3 rounded-lg px-4 py-3 text-sm">
            <span className="text-gray-600 dark:text-gray-400">Amount: </span>
            <span className="font-semibold text-gray-700 dark:text-gray-300">
              {formatCurrency(originalAmount)}
            </span>
            <span className="text-gray-400 mx-2">→</span>
            <span className="font-semibold text-gray-700 dark:text-gray-300">
              {formatCurrency(requestedAmount)}
            </span>
            <span
              className={`ml-2 font-semibold ${
                diff.positive ? 'text-success' : 'text-error'
              }`}
            >
              {diff.formatted}
            </span>
          </div>
        )}
      </div>

      {/* Reason */}
      <div>
        <label className="form-label">
          Reason <span className="text-error">*</span>
        </label>
        <div className="flex flex-wrap gap-2 mb-2">
          {EDIT_REQUEST_REASONS.map((chip) => (
            <button
              key={chip}
              type="button"
              onClick={() => handleReasonChip(chip)}
              className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
                reason === chip
                  ? 'bg-navy text-white border-navy dark:bg-teal dark:border-teal'
                  : 'border-gray-300 dark:border-gray-600 text-gray-600 dark:text-gray-400 hover:border-navy dark:hover:border-teal'
              }`}
            >
              {chip}
            </button>
          ))}
        </div>
        <textarea
          value={reason}
          onChange={(e) => {
            setReason(e.target.value)
            if (errors.reason) setErrors((er) => ({ ...er, reason: undefined }))
          }}
          rows={3}
          placeholder="Describe the reason for the edit request (min 10 characters)..."
          className={`form-input resize-none ${errors.reason ? 'border-error' : ''}`}
          minLength={10}
        />
        {errors.reason && <p className="form-error">{errors.reason}</p>}
      </div>

      <button
        type="submit"
        disabled={submitting}
        className="btn-primary w-full py-3 text-base justify-center"
      >
        {submitting ? <LoadingSpinner size="sm" /> : 'Submit Edit Request'}
      </button>
    </form>
  )
}
