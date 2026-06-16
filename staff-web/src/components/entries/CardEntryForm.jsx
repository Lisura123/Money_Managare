import { useCallback, useState } from 'react'
import toast from 'react-hot-toast'
import { MdCreditCard, MdNotes, MdStore } from 'react-icons/md'
import api from '../../config/api'
import { useAuth } from '../../hooks/useAuth'
import { useFormValidation } from '../../hooks/useFormValidation'
import { formatCurrency, getDayName, maskCard, todayString } from '../../utils/formatters'
import { validateCardEntry } from '../../utils/validators'
import { prioritizeShowrooms } from '../../utils/showroomPriority'
import LoadingSpinner from '../common/LoadingSpinner'

export default function CardEntryForm({ cardAccounts = [], onSuccess }) {
  const { user } = useAuth()
  const [submitting, setSubmitting] = useState(false)
  const [rawAmount, setRawAmount] = useState('')

  // Showrooms assigned to this staff member (multi-showroom support).
  const assignedShowrooms = prioritizeShowrooms(user?.showrooms || [], 'name')
  const hasMultipleShowrooms = assignedShowrooms.length > 1
  const [showroomId, setShowroomId] = useState(
    hasMultipleShowrooms ? '' : String(assignedShowrooms[0]?.id ?? user?.showroom_id ?? ''),
  )

  const { values, errors, handleChange, setValue, setFieldErrors, runValidation } =
    useFormValidation(
      { card_account_id: '', entry_date: todayString(), amount: '', notes: '' },
      validateCardEntry,
    )

  const handleAmountChange = useCallback(
    (e) => {
      const raw = e.target.value.replace(/[^0-9]/g, '')
      setRawAmount(raw)
      setValue('amount', raw)
    },
    [setValue],
  )

  // When multiple showrooms are assigned, only show accounts for the selected one.
  const visibleAccounts = hasMultipleShowrooms
    ? cardAccounts.filter((c) => String(c.showroom_id) === String(showroomId))
    : cardAccounts

  const selectedCard = visibleAccounts.find(
    (c) => String(c.id) === String(values.card_account_id),
  )

  const handleShowroomChange = useCallback(
    (e) => {
      setShowroomId(e.target.value)
      // Reset the chosen card account — it may belong to a different showroom.
      setValue('card_account_id', '')
    },
    [setValue],
  )

  const handleSubmit = useCallback(
    async (e) => {
      e.preventDefault()
      if (!runValidation()) return

      if (hasMultipleShowrooms && !showroomId) {
        toast.error('Please select a showroom before submitting.')
        return
      }

      const amount = parseFloat(values.amount)
      if (amount >= 1_000_000) {
        const confirmed = window.confirm(
          `You entered ${formatCurrency(amount)}. Are you sure this amount is correct?`
        )
        if (!confirmed) return
      }

      setSubmitting(true)
      try {
        await api.post('/card-entries', {
          card_account_id: values.card_account_id,
          entry_date: values.entry_date,
          amount: amount,
          notes: values.notes || null,
          ...(showroomId ? { showroom_id: Number(showroomId) } : {}),
        })
        toast.success('Bank entry submitted successfully!')
        onSuccess?.()
      } catch (err) {
        const status = err.response?.status
        if (status === 422) {
          const apiErrors = err.response.data.errors || {}
          const mapped = {}
          if (apiErrors.card_account_id) mapped.card_account_id = apiErrors.card_account_id[0]
          if (apiErrors.entry_date) mapped.entry_date = apiErrors.entry_date[0]
          if (apiErrors.amount) mapped.amount = apiErrors.amount[0]
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
    [values, runValidation, setFieldErrors, onSuccess, hasMultipleShowrooms, showroomId],
  )

  const dayName = getDayName(values.entry_date)
  const displayAmount = rawAmount
    ? new Intl.NumberFormat('en-US').format(parseFloat(rawAmount))
    : ''

  return (
    <form onSubmit={handleSubmit} noValidate className="space-y-5">
      {/* Showroom selector — shown only for multi-showroom staff */}
      {hasMultipleShowrooms && (
        <div>
          <label htmlFor="showroom_id" className="form-label">
            <MdStore className="inline w-4 h-4 mr-1 mb-0.5" />
            Showroom
          </label>
          <select
            id="showroom_id"
            value={showroomId}
            onChange={handleShowroomChange}
            className={`form-input ${!showroomId ? 'border-error focus:ring-error' : ''}`}
          >
            <option value="">Select a showroom…</option>
            {assignedShowrooms.map((sr) => (
              <option key={sr.id} value={sr.id}>
                {sr.name}
              </option>
            ))}
          </select>
          {!showroomId && (
            <p className="form-error">Select a showroom before adding an entry.</p>
          )}
        </div>
      )}

      {/* Card account selector — visual grid on desktop */}
      <div>
        <label className="form-label">
          <MdCreditCard className="inline w-4 h-4 mr-1 mb-0.5" />
          Select Card Account
        </label>

        {hasMultipleShowrooms && !showroomId ? (
          <p className="text-sm text-gray-500 dark:text-gray-400 py-2">
            Select a showroom to view its card accounts.
          </p>
        ) : visibleAccounts.length === 0 ? (
          <p className="text-sm text-gray-500 dark:text-gray-400 py-2">
            No card accounts found for your showroom.
          </p>
        ) : (
          <>
            {/* Desktop: grid of selectable cards */}
            <div className="hidden sm:grid grid-cols-2 gap-3 mt-1">
              {visibleAccounts.map((card) => {
                const isSelected = String(values.card_account_id) === String(card.id)
                return (
                  <button
                    key={card.id}
                    type="button"
                    onClick={() => setValue('card_account_id', String(card.id))}
                    className={`text-left p-3 rounded-xl border-2 transition-all duration-200 ${
                      isSelected
                        ? 'border-teal bg-teal/5 dark:bg-teal/10'
                        : 'border-gray-200 dark:border-gray-600 hover:border-gray-300 dark:hover:border-gray-500'
                    }`}
                  >
                    <div className="flex items-center gap-2 mb-1">
                      <MdCreditCard
                        className={`w-5 h-5 ${isSelected ? 'text-teal' : 'text-gray-400'}`}
                      />
                      <span
                        className={`text-sm font-semibold ${
                          isSelected ? 'text-teal' : 'text-gray-800 dark:text-gray-200'
                        }`}
                      >
                        {card.bank_name}
                      </span>
                    </div>
                    <p className="text-xs text-gray-500 dark:text-gray-400 font-mono">
                      {maskCard(card.last_four)}
                    </p>
                    <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">
                      Balance:{' '}
                      <span className="font-semibold">{formatCurrency(card.current_balance)}</span>
                    </p>
                  </button>
                )
              })}
            </div>

            {/* Mobile: dropdown */}
            <select
              className="sm:hidden form-input mt-1"
              value={values.card_account_id}
              onChange={(e) => setValue('card_account_id', e.target.value)}
            >
              <option value="">Select a card account…</option>
              {visibleAccounts.map((card) => (
                <option key={card.id} value={card.id}>
                  {card.bank_name} — {maskCard(card.last_four)} (
                  {formatCurrency(card.current_balance)})
                </option>
              ))}
            </select>
          </>
        )}

        {errors.card_account_id && (
          <p className="form-error">{errors.card_account_id}</p>
        )}

        {/* Selected card confirmation strip */}
        {selectedCard && (
          <div className="mt-3 bg-teal/5 border border-teal/20 rounded-lg px-4 py-2.5 text-sm text-teal dark:text-teal font-medium">
            Selected: {selectedCard.bank_name} {maskCard(selectedCard.last_four)} — Available:{' '}
            {formatCurrency(selectedCard.current_balance)}
          </div>
        )}
      </div>

      {/* Date */}
      <div>
        <label htmlFor="entry_date" className="form-label">
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

      {/* Amount */}
      <div>
        <label htmlFor="amount" className="form-label">
          Amount
        </label>
        <div className="relative">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500 dark:text-gray-400 text-sm font-medium select-none">
            Rs.
          </span>
          <input
            type="text"
            id="amount"
            name="amount"
            inputMode="numeric"
            value={displayAmount}
            placeholder="0"
            onChange={handleAmountChange}
            className={`form-input pl-10 ${errors.amount ? 'border-error focus:ring-error' : ''}`}
          />
        </div>
        {errors.amount && <p className="form-error">{errors.amount}</p>}
      </div>

      {/* Notes */}
      <div>
        <label htmlFor="notes" className="form-label">
          <MdNotes className="inline w-4 h-4 mr-1 mb-0.5" />
          Notes <span className="text-gray-400 font-normal">(optional)</span>
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
        <p className="text-xs text-gray-400 text-right mt-1">{values.notes.length}/500</p>
        {errors.notes && <p className="form-error">{errors.notes}</p>}
      </div>

      <button
        type="submit"
        disabled={submitting || (hasMultipleShowrooms && !showroomId)}
        className="btn-primary w-full py-3 text-base justify-center disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {submitting ? <LoadingSpinner size="sm" /> : 'Submit Entry'}
      </button>
    </form>
  )
}
