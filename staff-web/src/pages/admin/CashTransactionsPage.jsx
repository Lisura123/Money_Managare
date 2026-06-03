import { useState } from 'react'
import { MdAdd, MdDelete, MdRefresh, MdArrowForward, MdAccountBalance } from 'react-icons/md'
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

// ─── Add Modal ────────────────────────────────────────────────────────────────
function AddModal({ open, onClose, onSaved, mainCashBalance }) {
  const [amount, setAmount] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)

  const parsed = parseFloat(amount) || 0
  const insufficient = parsed > 0 && parsed > (mainCashBalance ?? 0)

  const reset = () => { setAmount(''); setNotes('') }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (parsed <= 0) { toast.error('Enter a valid amount.'); return }
    if (insufficient) { toast.error('Insufficient main cash balance.'); return }
    setLoading(true)
    try {
      const today = new Date().toISOString().slice(0, 10)
      await api.post(ENDPOINTS.CASH_TRANSACTIONS, {
        from_account_type: 'main',
        amount: parsed,
        notes: notes.trim() || null,
        transaction_date: today,
      })
      toast.success('Cash transfer created.')
      reset()
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create transfer.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => { reset(); onClose() }} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Cash Transfer</h3>

        {/* Balance pill */}
        <div className="bg-teal/5 border border-teal/20 rounded-xl px-4 py-3 mb-4 flex items-center justify-between">
          <span className="text-xs text-gray-500">Main Cash Balance</span>
          <span className="text-sm font-bold text-teal">{formatCurrency(mainCashBalance ?? 0)}</span>
        </div>

        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Amount (Rs.) *</label>
            <input
              className={`form-input ${insufficient ? 'border-red-400 focus:ring-red-400' : ''}`}
              type="number" step="0.01" min="0.01"
              value={amount} onChange={e => setAmount(e.target.value)} required
            />
            {insufficient && <p className="text-xs text-red-500 mt-1">Amount exceeds main cash balance.</p>}
          </div>
          <div>
            <label className="form-label">Notes (optional)</label>
            <textarea className="form-input" rows={2} value={notes} onChange={e => setNotes(e.target.value)} placeholder="e.g. Paid to showroom..." />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => { reset(); onClose() }} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading || insufficient} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : 'Transfer'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Row ─────────────────────────────────────────────────────────────────────
function TxRow({ tx, onDelete }) {
  const fromLabel = tx.from_account_type === 'main' ? 'Main Cash' : tx.from_account_type || '—'
  const toLabel = tx.to_external_account_name || tx.to_account_type || 'External'

  return (
    <div className="card flex items-center justify-between gap-4">
      <div className="flex-1 min-w-0">
        <div className="flex items-center gap-2 mb-1">
          <span className="text-sm font-semibold text-navy dark:text-white truncate">{toLabel}</span>
        </div>
        <div className="flex items-center gap-1.5 text-xs text-gray-400">
          <span>{fromLabel}</span>
          <MdArrowForward className="w-3 h-3" />
          <span>{toLabel}</span>
        </div>
        {tx.notes && <p className="text-xs text-gray-400 mt-0.5 italic">"{tx.notes}"</p>}
        <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(tx.created_at || tx.createdAt)}</p>
      </div>
      <div className="flex items-center gap-3 flex-shrink-0">
        <span className="text-base font-bold text-teal">{formatCurrency(tx.amount)}</span>
        <button
          onClick={() => onDelete(tx)}
          className="p-1.5 rounded-lg text-gray-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
          title="Delete"
        >
          <MdDelete className="w-4 h-4" />
        </button>
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function CashTransactionsPage() {
  const [showAdd, setShowAdd] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.CASH_TRANSACTIONS)
  const { data: balanceData, refetch: refetchBalance } = useFetch('/cash-summary')

  const transactions = data?.data || data || []
  const mainCashBalance = balanceData?.main_cash_balance ?? balanceData?.mainCashBalance ?? null

  const handleSaved = () => {
    refetch()
    refetchBalance()
    setShowAdd(false)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await api.delete(`${ENDPOINTS.CASH_TRANSACTIONS}/${deleteTarget.id}`)
      toast.success('Transfer deleted.')
      refetch()
      refetchBalance()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeleting(false)
      setDeleteTarget(null)
    }
  }

  return (
    <div className="space-y-6 animate-fade-in">
      <PageHeader
        title="Cash Transfers"
        subtitle="Track outgoing transfers from main cash."
        action={
          <div className="flex items-center gap-2">
            <button onClick={() => { refetch(); refetchBalance() }} className="btn-outline p-2" title="Refresh">
              <MdRefresh className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button onClick={() => setShowAdd(true)} className="btn-primary gap-1.5">
              <MdAdd className="w-5 h-5" /> New Transfer
            </button>
          </div>
        }
      />

      {/* Balance card */}
      <div className="card flex items-center justify-between">
        <div>
          <p className="text-xs text-gray-500 dark:text-gray-400 uppercase font-medium tracking-wide mb-1">Main Cash Balance</p>
          <p className="text-2xl font-heading font-bold text-navy dark:text-white">
            {mainCashBalance !== null ? formatCurrency(mainCashBalance) : '—'}
          </p>
        </div>
        <div className="w-12 h-12 rounded-full bg-teal/10 flex items-center justify-center">
          <MdAccountBalance className="w-6 h-6 text-teal" />
        </div>
      </div>

      {/* List */}
      {error ? (
        <ErrorState message={error} onRetry={refetch} />
      ) : loading && !transactions.length ? (
        <div className="flex justify-center py-16"><LoadingSpinner /></div>
      ) : !transactions.length ? (
        <EmptyState icon={MdArrowForward} title="No Cash Transfers" description="Add your first cash transfer above." />
      ) : (
        <div className="space-y-2">
          {transactions.map(tx => (
            <TxRow key={tx.id} tx={tx} onDelete={setDeleteTarget} />
          ))}
        </div>
      )}

      <AddModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onSaved={handleSaved}
        mainCashBalance={mainCashBalance}
      />

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Transfer?"
        message="This transfer will be permanently deleted. This cannot be undone."
        confirmLabel="Delete"
        variant="danger"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
