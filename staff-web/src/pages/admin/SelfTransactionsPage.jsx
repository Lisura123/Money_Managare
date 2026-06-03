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
import api from '../../config/api'

// ─── helpers ──────────────────────────────────────────────────────────────────
const maskCard = (lastFour) => lastFour ? `••••${lastFour}` : '—'
const cardLabel = (bankName, lastFour, balance) =>
  `${bankName || 'Unknown'} ${maskCard(lastFour)}${balance !== undefined ? ` (${formatCurrency(balance)})` : ''}`

// ─── New Transaction Modal ─────────────────────────────────────────────────────
function AddModal({ open, onClose, onSaved, cardAccounts, externalAccounts }) {
  const [fromId, setFromId] = useState('')
  const [toValue, setToValue] = useState('') // card id, 'ext:{id}', or 'others'
  const [amount, setAmount] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)
  const [showConfirm, setShowConfirm] = useState(false)

  const fromAccount = cardAccounts.find(c => String(c.id) === String(fromId))
  const toCardAccount = toValue && !toValue.startsWith('ext:') && toValue !== 'others'
    ? cardAccounts.find(c => String(c.id) === String(toValue))
    : null
  const toExternal = toValue?.startsWith('ext:')
    ? externalAccounts.find(e => String(e.id) === toValue.replace('ext:', ''))
    : null
  const isOthers = toValue === 'others'

  const toLabel = toCardAccount
    ? `${toCardAccount.showroom_name || toCardAccount.showroomName || ''} — ${maskCard(toCardAccount.last_four || toCardAccount.lastFour)}`
    : toExternal
    ? `${toExternal.name} — ${formatCurrency(toExternal.balance)}`
    : isOthers ? 'Others (External)' : ''

  const parsedAmount = parseFloat(amount) || 0
  const insufficientBalance = fromAccount && parsedAmount > 0 && parsedAmount > (fromAccount.current_balance ?? fromAccount.currentBalance ?? 0)

  const availableToAccounts = cardAccounts.filter(c => String(c.id) !== String(fromId))

  const reset = () => { setFromId(''); setToValue(''); setAmount(''); setNotes(''); setShowConfirm(false) }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!fromId) { toast.error('Select a From account.'); return }
    if (!toValue) { toast.error('Select a To account.'); return }
    if (parsedAmount <= 0) { toast.error('Enter a valid amount.'); return }
    if (insufficientBalance) { toast.error('Insufficient balance in source account.'); return }
    setShowConfirm(true)
  }

  const handleConfirm = async () => {
    setLoading(true)
    try {
      const payload = {
        from_card_account_id: Number(fromId),
        amount: parsedAmount,
      }
      if (toCardAccount) payload.to_card_account_id = toCardAccount.id
      if (toExternal) payload.to_external_account_id = toExternal.id
      // 'others' → no to_card_account_id and no to_external_account_id
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
                <p className="text-sm font-semibold text-navy dark:text-white truncate">
                  {fromAccount ? `${fromAccount.showroom_name || fromAccount.showroomName || ''} — ${maskCard(fromAccount.last_four || fromAccount.lastFour)}` : '—'}
                </p>
              </div>
              <MdArrowForward className="w-5 h-5 text-teal flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <p className="text-xs text-gray-400">To</p>
                <p className="text-sm font-semibold text-navy dark:text-white truncate">{toLabel || '—'}</p>
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

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => { reset(); onClose() }} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Self Transaction</h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          {/* From */}
          <div>
            <label className="form-label">From Account</label>
            <select className="form-input" value={fromId} onChange={e => { setFromId(e.target.value); setToValue('') }} required>
              <option value="">Select account</option>
              {cardAccounts.map(c => (
                <option key={c.id} value={c.id}>
                  {c.showroom_name || c.showroomName || ''} — {cardLabel(c.bank_name || c.bankName, c.last_four || c.lastFour, c.current_balance ?? c.currentBalance)}
                </option>
              ))}
            </select>
            {fromAccount && (
              <p className="text-xs text-gray-400 mt-1">
                Balance: <span className="font-medium text-navy dark:text-white">{formatCurrency(fromAccount.current_balance ?? fromAccount.currentBalance ?? 0)}</span>
              </p>
            )}
          </div>

          {/* To */}
          <div>
            <label className="form-label">To Account</label>
            <select className="form-input" value={toValue} onChange={e => setToValue(e.target.value)} required>
              <option value="">Select account</option>
              {availableToAccounts.map(c => (
                <option key={c.id} value={c.id}>
                  {c.showroom_name || c.showroomName || ''} — {cardLabel(c.bank_name || c.bankName, c.last_four || c.lastFour, c.current_balance ?? c.currentBalance)}
                </option>
              ))}
              {externalAccounts.map(e => (
                <option key={`ext:${e.id}`} value={`ext:${e.id}`}>
                  {e.name} — {formatCurrency(e.balance)}
                </option>
              ))}
              <option value="others">Others (External)</option>
            </select>
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
                Insufficient balance. Available: {formatCurrency(fromAccount.current_balance ?? fromAccount.currentBalance ?? 0)}
              </p>
            )}
          </div>

          {/* Live summary */}
          {fromId && toValue && parsedAmount > 0 && (
            <div className="bg-teal/5 border border-teal/20 rounded-xl px-3 py-2 text-xs space-y-1">
              <p className="font-medium text-gray-600 dark:text-gray-300">Transfer Summary</p>
              <div className="flex items-center gap-1 text-gray-500">
                <span className="truncate">{fromAccount ? maskCard(fromAccount.last_four || fromAccount.lastFour) : '—'}</span>
                <MdArrowForward className="w-3 h-3 flex-shrink-0" />
                <span className="truncate">{toLabel || '—'}</span>
              </div>
              <p className="font-bold text-teal">{formatCurrency(parsedAmount)}</p>
            </div>
          )}

          {/* Notes */}
          <div>
            <label className="form-label">Notes (optional)</label>
            <input type="text" className="form-input" placeholder="Optional" value={notes} onChange={e => setNotes(e.target.value)} />
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => { reset(); onClose() }} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={insufficientBalance} className="btn-primary flex-1 justify-center">Review</button>
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

  const transactions = data?.data || []
  const meta = data?.meta || {}
  const totalPages = meta.last_page || 1
  const total = transactions.reduce((s, t) => s + (parseFloat(t.amount) || 0), 0)

  // Flatten card accounts from showrooms
  const showrooms = Array.isArray(showroomsData) ? showroomsData : (showroomsData?.data || [])
  const cardAccounts = showrooms.flatMap(s =>
    (s.card_accounts || []).map(c => ({ ...c, showroom_name: s.name }))
  )
  const externalAccounts = Array.isArray(externalData) ? externalData : (externalData?.data || [])

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
