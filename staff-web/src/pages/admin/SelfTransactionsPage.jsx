import { useState, useMemo } from 'react'
import { MdAdd, MdDelete, MdRefresh, MdSwapHoriz, MdArrowForward } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, formatDateTime } from '../../utils/formatters'
import { isFlagshipShowroom, prioritizeShowrooms } from '../../utils/showroomPriority'
import api from '../../config/api'

// ─── helpers ──────────────────────────────────────────────────────────────────
const maskCard = (lastFour) => lastFour ? `••••${lastFour}` : '—'
const cardLabel = (bankName, lastFour, balance) =>
  `${bankName || 'Unknown'} ${maskCard(lastFour)}${balance !== undefined ? ` (${formatCurrency(balance)})` : ''}`

const FROM_TYPES = [
  { key: 'mainCash', label: 'Main Cash' },
  { key: 'showroomCash', label: 'Showroom Cash' },
  { key: 'card', label: 'Bank' },
  { key: 'mano', label: 'Mano' },
]
const TO_TYPES = [...FROM_TYPES, { key: 'other', label: 'Others' }]

// ─── New Transaction Modal ─────────────────────────────────────────────────────
function AddModal({ open, onClose, onSaved, cardAccounts, externalAccounts, showroomCash }) {
  const [fromType, setFromType] = useState(null)
  const [fromShowroomId, setFromShowroomId] = useState('')        // Bank
  const [fromCardId, setFromCardId] = useState('')                // Bank
  const [fromCashShowroomId, setFromCashShowroomId] = useState('') // Main / Showroom Cash

  const [toType, setToType] = useState(null)
  const [toShowroomId, setToShowroomId] = useState('')            // Bank
  const [toCardId, setToCardId] = useState('')                    // Bank
  const [toCashShowroomId, setToCashShowroomId] = useState('')    // Main / Showroom Cash

  const [amount, setAmount] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  // ── derived data ──
  const manoAccount = externalAccounts.find(e => e.cash_account_type === 'mano')
  const cardsForShowroom = (id) => cardAccounts.filter(c => String(c.showroom_id) === String(id) && (c.is_active ?? true))

  const cardShowrooms = prioritizeShowrooms(
    [...new Map(cardAccounts.map(c => [c.showroom_id, { id: c.showroom_id, name: c.showroom_name }])).values()],
    'name',
  )
  const mainCashShowrooms = prioritizeShowrooms(showroomCash.filter(s => isFlagshipShowroom(s.showroom_name)), 'showroom_name')
  const otherCashShowrooms = prioritizeShowrooms(showroomCash.filter(s => !isFlagshipShowroom(s.showroom_name)), 'showroom_name')

  const fromCardAccount = cardAccounts.find(c => String(c.id) === String(fromCardId))
  const toCardAccount = cardAccounts.find(c => String(c.id) === String(toCardId))
  const fromCashItem = showroomCash.find(s => String(s.showroom_id) === String(fromCashShowroomId))
  const toCashItem = showroomCash.find(s => String(s.showroom_id) === String(toCashShowroomId))

  const parsedAmount = parseFloat(amount) || 0

  const fromBalance = (() => {
    switch (fromType) {
      case 'card': return fromCardAccount?.current_balance != null ? parseFloat(fromCardAccount.current_balance) : null
      case 'mano': return manoAccount ? parseFloat(manoAccount.balance) : null
      case 'mainCash':
      case 'showroomCash': return fromCashItem ? parseFloat(fromCashItem.balance) : null
      default: return null
    }
  })()
  const toBalance = (() => {
    switch (toType) {
      case 'card': return toCardAccount?.current_balance != null ? parseFloat(toCardAccount.current_balance) : null
      case 'mano': return manoAccount ? parseFloat(manoAccount.balance) : null
      case 'mainCash':
      case 'showroomCash': return toCashItem ? parseFloat(toCashItem.balance) : null
      default: return null
    }
  })()

  const fromLabel = (() => {
    switch (fromType) {
      case 'card': return fromCardAccount ? `${fromCardAccount.bank_name || 'Bank'} ${maskCard(fromCardAccount.last_four)}` : 'Bank'
      case 'mano': return manoAccount?.name || 'Mano'
      case 'mainCash':
      case 'showroomCash': return fromCashItem ? `Cash (${fromCashItem.showroom_name})` : 'Cash'
      default: return '—'
    }
  })()
  const toLabel = (() => {
    switch (toType) {
      case 'card': return toCardAccount ? `${toCardAccount.bank_name || 'Bank'} ${maskCard(toCardAccount.last_four)}` : 'Bank'
      case 'mano': return manoAccount?.name || 'Mano'
      case 'mainCash':
      case 'showroomCash': return toCashItem ? `Cash (${toCashItem.showroom_name})` : 'Cash'
      case 'other': return 'Others'
      default: return '—'
    }
  })()

  const notesRequired = toType === 'other'
  const insufficientBalance = fromBalance != null && parsedAmount > 0 && parsedAmount > fromBalance

  const saveDisabled =
    loading || !fromType || !toType || parsedAmount <= 0 ||
    (fromType === 'card' && !fromCardId) ||
    ((fromType === 'mainCash' || fromType === 'showroomCash') && !fromCashShowroomId) ||
    (fromType === 'mano' && !manoAccount) ||
    (toType === 'card' && !toCardId) ||
    ((toType === 'mainCash' || toType === 'showroomCash') && !toCashShowroomId) ||
    (toType === 'mano' && !manoAccount) ||
    (notesRequired && !notes.trim()) ||
    insufficientBalance

  const reset = () => {
    setFromType(null); setFromShowroomId(''); setFromCardId(''); setFromCashShowroomId('')
    setToType(null); setToShowroomId(''); setToCardId(''); setToCashShowroomId('')
    setAmount(''); setNotes(''); setShowConfirm(false)
  }

  const selectFromType = (key) => {
    setFromType(key); setFromShowroomId(''); setFromCardId(''); setFromCashShowroomId('')
  }
  const selectToType = (key) => {
    setToType(key); setToShowroomId(''); setToCardId(''); setToCashShowroomId('')
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (saveDisabled) {
      if (insufficientBalance) toast.error('Insufficient balance in source account.')
      else if (notesRequired && !notes.trim()) toast.error('Notes are required for Others.')
      else toast.error('Please complete the transfer details.')
      return
    }
    setShowConfirm(true)
  }

  const handleConfirm = async () => {
    setLoading(true)
    try {
      const payload = { amount: parsedAmount }

      // FROM
      if (fromType === 'card') payload.from_card_account_id = Number(fromCardId)
      else if (fromType === 'mano') payload.from_external_account_id = manoAccount?.id
      else if (fromType === 'mainCash' || fromType === 'showroomCash') {
        payload.from_account_type = 'main'
        payload.from_showroom_id = Number(fromCashShowroomId)
      }

      // TO
      if (toType === 'card') payload.to_card_account_id = Number(toCardId)
      else if (toType === 'mano') payload.to_external_account_id = manoAccount?.id
      else if (toType === 'mainCash' || toType === 'showroomCash') {
        payload.to_account_type = 'main'
        payload.to_showroom_id = Number(toCashShowroomId)
      }
      // 'other' → notes only

      if (notes.trim()) payload.notes = notes.trim()

      await api.post(ENDPOINTS.SELF_TRANSACTIONS, payload)
      toast.success('Transfer created.')
      reset()
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create transfer.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null

  // Confirm step
  if (showConfirm) {
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => setShowConfirm(false)} />
        <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
          <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">Confirm Transfer</h3>
          <div className="bg-teal/5 border border-teal/20 rounded-xl p-4 space-y-3 mb-4">
            <p className="text-xs text-gray-500 uppercase font-medium tracking-wide">Transfer Summary</p>
            <div className="flex items-center gap-2">
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-400">From</p>
                <p className="text-sm font-semibold text-navy dark:text-white truncate">{fromLabel}</p>
              </div>
              <MdArrowForward className="w-5 h-5 text-teal flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-400">To</p>
                <p className="text-sm font-semibold text-navy dark:text-white truncate">{toLabel}</p>
              </div>
            </div>
            <p className="text-xl font-heading font-bold text-teal">{formatCurrency(parsedAmount)}</p>
            {notes && <p className="text-xs text-gray-500 italic">"{notes}"</p>}
          </div>
          <div className="flex gap-3">
            <button onClick={() => setShowConfirm(false)} className="btn-outline flex-1 justify-center" disabled={loading}>Back</button>
            <button onClick={handleConfirm} disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : 'Confirm Transfer'}
            </button>
          </div>
        </div>
      </div>
    )
  }

  const renderChips = (types, selected, onSelect) => (
    <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1">
      {types.map(t => (
        <button
          key={t.key}
          type="button"
          onClick={() => onSelect(t.key)}
          className={`px-3.5 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-colors ${
            selected === t.key
              ? 'bg-navy text-white dark:bg-teal'
              : 'bg-gray-100 dark:bg-white/10 text-gray-500 dark:text-gray-300'
          }`}
        >
          {t.label}
        </button>
      ))}
    </div>
  )

  const renderDetail = (type, { showroomId, setShowroomId, cardId, setCardId, cashShowroomId, setCashShowroomId, cashItem }) => {
    if (type === 'card') {
      return (
        <div className="space-y-2 mt-2">
          <select className="form-input" value={showroomId} onChange={e => { setShowroomId(e.target.value); setCardId('') }}>
            <option value="">Select showroom…</option>
            {cardShowrooms.map(s => (
              <option key={s.id} value={s.id}>{isFlagshipShowroom(s.name) ? `★ ${s.name}` : s.name}</option>
            ))}
          </select>
          {showroomId && (
            <select className="form-input" value={cardId} onChange={e => setCardId(e.target.value)}>
              <option value="">Select account…</option>
              {cardsForShowroom(showroomId).map(a => (
                <option key={a.id} value={a.id}>{a.bank_name || 'Bank'} {maskCard(a.last_four)} ({formatCurrency(a.current_balance)})</option>
              ))}
            </select>
          )}
        </div>
      )
    }
    if (type === 'mano') {
      return manoAccount ? (
        <div className="flex items-center justify-between mt-2 px-3 py-2 bg-gray-50 dark:bg-white/5 rounded-lg">
          <span className="text-sm text-navy dark:text-white">{manoAccount.name}</span>
          <span className="text-sm font-semibold text-teal">{formatCurrency(manoAccount.balance)}</span>
        </div>
      ) : <p className="text-xs text-gray-400 mt-2">No Mano account available.</p>
    }
    if (type === 'mainCash' || type === 'showroomCash') {
      const list = type === 'mainCash' ? mainCashShowrooms : otherCashShowrooms
      return (
        <div className="space-y-2 mt-2">
          <select className="form-input" value={cashShowroomId} onChange={e => setCashShowroomId(e.target.value)}>
            <option value="">Select showroom…</option>
            {list.map(s => (
              <option key={s.showroom_id} value={s.showroom_id}>{isFlagshipShowroom(s.showroom_name) ? `★ ${s.showroom_name}` : s.showroom_name}</option>
            ))}
          </select>
          {cashItem && (
            <div className="flex items-center justify-between px-3 py-2 bg-gray-50 dark:bg-white/5 rounded-lg">
              <span className="text-xs text-gray-400">Cash Balance</span>
              <span className="text-sm font-semibold text-teal">{formatCurrency(cashItem.balance)}</span>
            </div>
          )}
        </div>
      )
    }
    return null
  }

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => { reset(); onClose() }} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm max-h-[90vh] overflow-y-auto animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Self Transfer</h3>
        <form onSubmit={handleSubmit} className="space-y-4">
          {/* From */}
          <div>
            <label className="form-label">From</label>
            {renderChips(FROM_TYPES, fromType, selectFromType)}
            {renderDetail(fromType, {
              showroomId: fromShowroomId, setShowroomId: setFromShowroomId,
              cardId: fromCardId, setCardId: setFromCardId,
              cashShowroomId: fromCashShowroomId, setCashShowroomId: setFromCashShowroomId,
              cashItem: fromCashItem,
            })}
          </div>

          {/* To */}
          <div>
            <label className="form-label">To</label>
            {renderChips(TO_TYPES, toType, selectToType)}
            {renderDetail(toType, {
              showroomId: toShowroomId, setShowroomId: setToShowroomId,
              cardId: toCardId, setCardId: setToCardId,
              cashShowroomId: toCashShowroomId, setCashShowroomId: setToCashShowroomId,
              cashItem: toCashItem,
            })}
          </div>

          {/* Amount */}
          <div>
            <label className="form-label">Amount (Rs.)</label>
            <input
              type="number" step="0.01" min="0.01" className="form-input"
              placeholder="0.00" value={amount}
              onChange={e => setAmount(e.target.value)} required
            />
            {insufficientBalance && (
              <p className="text-xs text-red-500 mt-1">
                Insufficient balance. Available: {formatCurrency(fromBalance)}
              </p>
            )}
          </div>

          {/* Notes */}
          <div>
            <label className="form-label">{notesRequired ? 'Notes (required)' : 'Notes (optional)'}</label>
            <input
              type="text" className="form-input"
              placeholder={notesRequired ? 'Required for Others' : 'Optional'}
              value={notes} onChange={e => setNotes(e.target.value)}
            />
            {notesRequired && !notes.trim() && (
              <p className="text-xs text-red-500 mt-1">Notes are required for Others.</p>
            )}
          </div>

          {/* Balance preview */}
          {parsedAmount > 0 && fromBalance != null && (
            <div className="bg-teal/5 border border-teal/20 rounded-xl px-3 py-2 text-xs space-y-2">
              <p className="font-medium text-gray-600 dark:text-gray-300">Balance Preview</p>
              <div>
                <p className="text-gray-400 truncate">From: {fromLabel}</p>
                <p className="flex items-center gap-1">
                  <span className="text-gray-500">{formatCurrency(fromBalance)}</span>
                  <MdArrowForward className="w-3 h-3 text-gray-400" />
                  <span className="font-semibold text-error">{formatCurrency(fromBalance - parsedAmount)}</span>
                </p>
              </div>
              {toBalance != null && (
                <div>
                  <p className="text-gray-400 truncate">To: {toLabel}</p>
                  <p className="flex items-center gap-1">
                    <span className="text-gray-500">{formatCurrency(toBalance)}</span>
                    <MdArrowForward className="w-3 h-3 text-gray-400" />
                    <span className="font-semibold text-success">{formatCurrency(toBalance + parsedAmount)}</span>
                  </p>
                </div>
              )}
            </div>
          )}

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => { reset(); onClose() }} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={saveDisabled} className="btn-primary flex-1 justify-center">Review</button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Page ──────────────────────────────────────────────────────────────────────
export default function SelfTransactionsPage() {
  const [page, setPage] = useState(1)
  const [showAdd, setShowAdd] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)
  const [bulkMode, setBulkMode] = useState(false)
  const [selected, setSelected] = useState(new Set())
  const [bulkDeleting, setBulkDeleting] = useState(false)

  const params = useMemo(() => ({ page, per_page: 20 }), [page])

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.SELF_TRANSACTIONS, params, [page])
  const { data: showroomsData } = useFetch(ENDPOINTS.SHOWROOMS)
  const { data: externalData } = useFetch(ENDPOINTS.EXTERNAL_ACCOUNTS)
  const { data: showroomCashData } = useFetch(ENDPOINTS.SHOWROOM_CASH_BALANCES)

  const transactions = data?.data || []
  const meta = data?.meta || {}
  const totalPages = meta.last_page || 1
  const total = transactions.reduce((s, t) => s + (parseFloat(t.amount) || 0), 0)

  // Flatten card accounts from showrooms
  const showrooms = Array.isArray(showroomsData) ? showroomsData : (showroomsData?.data || [])
  const cardAccounts = showrooms.flatMap(s =>
    (s.card_accounts || []).map(c => ({ ...c, showroom_name: s.name, showroom_id: s.id }))
  )
  const externalAccounts = Array.isArray(externalData) ? externalData : (externalData?.data || [])
  const showroomCash = Array.isArray(showroomCashData) ? showroomCashData : (showroomCashData?.data || [])

  const toggleSelect = (id) => {
    setSelected(prev => {
      const next = new Set(prev)
      next.has(id) ? next.delete(id) : next.add(id)
      return next
    })
  }

  const toggleSelectAll = () => {
    if (selected.size === transactions.length) {
      setSelected(new Set())
    } else {
      setSelected(new Set(transactions.map(t => t.id)))
    }
  }

  const handleDelete = async () => {
    setDeleting(true)
    try {
      await api.delete(`${ENDPOINTS.SELF_TRANSACTIONS}/${deleteTarget.id}`)
      toast.success('Transaction deleted. Balance reversed.')
      setDeleteTarget(null)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeleting(false)
    }
  }

  const handleBulkDelete = async () => {
    setBulkDeleting(true)
    try {
      await api.post(`${ENDPOINTS.SELF_TRANSACTIONS}/bulk-delete`, { ids: [...selected] })
      toast.success(`${selected.size} transaction(s) deleted.`)
      setSelected(new Set())
      setBulkMode(false)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Bulk delete failed.')
    } finally {
      setBulkDeleting(false)
    }
  }

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title={bulkMode ? `${selected.size} selected` : 'Self Transactions'}
        action={
          bulkMode ? (
            <div className="flex gap-2">
              <button onClick={toggleSelectAll} className="btn-outline text-xs py-1.5 px-3">
                {selected.size === transactions.length ? 'Deselect All' : 'Select All'}
              </button>
              <button
                onClick={handleBulkDelete}
                disabled={selected.size === 0 || bulkDeleting}
                className="btn-danger text-xs py-1.5 px-3 gap-1 disabled:opacity-40"
              >
                {bulkDeleting ? <LoadingSpinner size="sm" /> : <MdDelete className="w-4 h-4" />}
                Delete ({selected.size})
              </button>
              <button onClick={() => { setBulkMode(false); setSelected(new Set()) }} className="btn-outline text-xs py-1.5 px-3">Cancel</button>
            </div>
          ) : (
            <div className="flex gap-2">
              <button onClick={refetch} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>
              <button onClick={() => setBulkMode(true)} className="btn-outline p-2" title="Select multiple"><MdDelete className="w-5 h-5" /></button>
              <button onClick={() => setShowAdd(true)} className="btn-primary gap-1"><MdAdd className="w-5 h-5" />Add</button>
            </div>
          )
        }
      />

      {/* Summary bar */}
      {transactions.length > 0 && (
        <div className="bg-teal/5 border border-teal/20 rounded-xl px-4 py-2 flex justify-between items-center text-sm">
          <span className="text-gray-500">{meta.total || transactions.length} transaction(s)</span>
          <span className="font-semibold text-navy dark:text-white">Total: {formatCurrency(total)}</span>
        </div>
      )}

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && transactions.length === 0 ? (
        <div className="space-y-2">{[1,2,3,4,5].map(i => <div key={i} className="card animate-pulse h-20 bg-gray-100 dark:bg-white/5" />)}</div>
      ) : transactions.length === 0 ? (
        <EmptyState
          title="No transactions"
          action={<button onClick={() => setShowAdd(true)} className="btn-primary gap-1 mt-2"><MdAdd className="w-4 h-4" />Add Transaction</button>}
        />
      ) : (
        <div className="space-y-2">
          {transactions.map(tx => {
            const fromLabel = tx.from_card_account
              ? `${tx.from_card_account.showroom?.name || ''} — ${maskCard(tx.from_card_account.last_four)}`
              : tx.from_bank_name ? `${tx.from_bank_name} ${maskCard(tx.from_last_four)}` : '—'

            const toLabel = tx.to_card_account
              ? `${tx.to_card_account.showroom?.name || ''} — ${maskCard(tx.to_card_account.last_four)}`
              : tx.to_bank_name ? `${tx.to_bank_name} ${maskCard(tx.to_last_four)}`
              : tx.to_external_account ? tx.to_external_account.name
              : 'Others'

            const isSelected = selected.has(tx.id)

            return (
              <div
                key={tx.id}
                onClick={bulkMode ? () => toggleSelect(tx.id) : undefined}
                className={`card flex items-center gap-3 ${bulkMode ? 'cursor-pointer' : ''} ${isSelected ? 'ring-2 ring-teal' : ''}`}
              >
                {bulkMode && (
                  <input type="checkbox" readOnly checked={isSelected} className="w-4 h-4 accent-teal flex-shrink-0" />
                )}
                <div className="w-9 h-9 rounded-xl bg-teal/10 flex items-center justify-center flex-shrink-0">
                  <MdSwapHoriz className="w-5 h-5 text-teal" />
                </div>
                <div className="flex-1 min-w-0">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-semibold text-navy dark:text-white">{formatDateTime(tx.created_at)}</p>
                    <p className="font-bold text-teal text-sm flex-shrink-0">{formatCurrency(tx.amount)}</p>
                  </div>
                  <div className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                    <span className="truncate">{fromLabel}</span>
                    <MdArrowForward className="w-3 h-3 flex-shrink-0" />
                    <span className="truncate">{toLabel}</span>
                  </div>
                  {tx.notes && <p className="text-xs text-gray-400 italic truncate mt-0.5">"{tx.notes}"</p>}
                </div>
                {!bulkMode && (
                  <button
                    onClick={() => setDeleteTarget(tx)}
                    className="p-1.5 text-red-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors flex-shrink-0"
                  >
                    <MdDelete className="w-4 h-4" />
                  </button>
                )}
              </div>
            )
          })}
        </div>
      )}

      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-xs text-gray-500">Page {page} of {totalPages}</p>
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="btn-outline py-1 px-2 text-xs disabled:opacity-40">Prev</button>
            <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages} className="btn-outline py-1 px-2 text-xs disabled:opacity-40">Next</button>
          </div>
        </div>
      )}

      <AddModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onSaved={() => { setShowAdd(false); refetch() }}
        cardAccounts={cardAccounts}
        externalAccounts={externalAccounts}
        showroomCash={showroomCash}
      />

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Transaction"
        message={`Delete this transfer of ${deleteTarget ? formatCurrency(deleteTarget.amount) : ''}? Balance changes will be reversed.`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
        danger
      />
    </div>
  )
}
