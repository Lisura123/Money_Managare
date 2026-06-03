import { useState, useEffect, useCallback } from 'react'
import { MdAdd, MdDelete, MdRefresh, MdTune } from 'react-icons/md'
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
function AddModal({ open, onClose, onSaved }) {
  const [accountType, setAccountType] = useState('main')
  const [operation, setOperation] = useState('add')
  const [amount, setAmount] = useState('')
  const [reason, setReason] = useState('')
  const [loading, setLoading] = useState(false)
  const [balanceLoading, setBalanceLoading] = useState(false)
  const [mainBalance, setMainBalance] = useState(null)
  const [manoBalance, setManoBalance] = useState(null)

  const currentBalance = accountType === 'mano' ? manoBalance : mainBalance

  const fetchBalances = useCallback(async () => {
    setBalanceLoading(true)
    try {
      const res = await api.get('/cash-summary')
      setMainBalance(res.data?.main_cash_balance ?? res.data?.mainCashBalance ?? 0)
      setManoBalance(res.data?.mano_cash_balance ?? res.data?.manoCashBalance ?? 0)
    } catch {
      // ignore — balance will show '—'
    } finally {
      setBalanceLoading(false)
    }
  }, [])

  useEffect(() => {
    if (open) fetchBalances()
  }, [open, fetchBalances])

  const parsed = parseFloat(amount) || 0
  const signedAmount = operation === 'add' ? parsed : -parsed
  const newBalance = (currentBalance ?? 0) + signedAmount
  const showPreview = parsed > 0

  const reset = () => { setAccountType('main'); setOperation('add'); setAmount(''); setReason('') }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (parsed <= 0) { toast.error('Enter a valid amount.'); return }
    if (!reason.trim()) { toast.error('Reason is required.'); return }
    setLoading(true)
    try {
      await api.post(ENDPOINTS.CASH_ADJUSTMENTS, {
        adjusted_amount: signedAmount,
        reason: reason.trim(),
        cash_account_type: accountType,
      })
      toast.success('Adjustment saved.')
      reset()
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save adjustment.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={() => { reset(); onClose() }} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in overflow-y-auto max-h-[90vh]">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Cash Adjustment</h3>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Account Type */}
          <div>
            <label className="form-label mb-1.5">Account</label>
            <div className="grid grid-cols-2 gap-2">
              {['main', 'mano'].map(type => (
                <button
                  key={type}
                  type="button"
                  onClick={() => setAccountType(type)}
                  className={`py-2 px-3 rounded-lg text-sm font-medium border transition-colors ${
                    accountType === type
                      ? 'bg-teal text-white border-teal'
                      : 'border-gray-200 dark:border-white/10 text-gray-600 dark:text-gray-300 hover:border-teal/40'
                  }`}
                >
                  {type === 'main' ? 'Main Cash' : 'Mano Cash'}
                </button>
              ))}
            </div>
            <div className="mt-2 flex items-center justify-between text-xs text-gray-500 bg-gray-50 dark:bg-white/5 rounded-lg px-3 py-2">
              <span>Current Balance</span>
              {balanceLoading
                ? <LoadingSpinner size="sm" />
                : <span className="font-semibold text-teal">{currentBalance !== null ? formatCurrency(currentBalance) : '—'}</span>
              }
            </div>
          </div>

          {/* Operation */}
          <div>
            <label className="form-label mb-1.5">Operation</label>
            <div className="grid grid-cols-2 gap-2">
              {[{ val: 'add', label: 'Add (+)' }, { val: 'deduct', label: 'Deduct (−)' }].map(op => (
                <button
                  key={op.val}
                  type="button"
                  onClick={() => setOperation(op.val)}
                  className={`py-2 px-3 rounded-lg text-sm font-medium border transition-colors ${
                    operation === op.val
                      ? op.val === 'add' ? 'bg-green-500 text-white border-green-500' : 'bg-red-500 text-white border-red-500'
                      : 'border-gray-200 dark:border-white/10 text-gray-600 dark:text-gray-300 hover:border-teal/40'
                  }`}
                >
                  {op.label}
                </button>
              ))}
            </div>
          </div>

          {/* Amount */}
          <div>
            <label className="form-label">Amount (Rs.) *</label>
            <input
              className="form-input" type="number" step="0.01" min="0.01"
              value={amount} onChange={e => setAmount(e.target.value)} required
            />
          </div>

          {/* Reason */}
          <div>
            <label className="form-label">Reason *</label>
            <input
              className="form-input" type="text"
              value={reason} onChange={e => setReason(e.target.value)}
              placeholder="e.g. Petty cash expense" required
            />
          </div>

          {/* Preview */}
          {showPreview && (
            <div className="bg-gray-50 dark:bg-white/5 rounded-xl px-4 py-3 flex items-center justify-between">
              <span className="text-xs text-gray-500">New Balance</span>
              <span className={`text-sm font-bold ${newBalance >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                {formatCurrency(newBalance)}
              </span>
            </div>
          )}

          <div className="flex gap-3 pt-1">
            <button type="button" onClick={() => { reset(); onClose() }} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : 'Save'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Row ──────────────────────────────────────────────────────────────────────
function AdjRow({ adj, onDelete }) {
  const amount = parseFloat(adj.adjusted_amount ?? adj.adjustedAmount ?? 0)
  const isPositive = amount >= 0
  const accountLabel = (adj.cash_account_type ?? adj.cashAccountType) === 'mano' ? 'Mano Cash' : 'Main Cash'

  return (
    <div className="card flex items-center justify-between gap-4">
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-navy dark:text-white">{accountLabel}</p>
        {adj.reason && <p className="text-xs text-gray-400 mt-0.5">{adj.reason}</p>}
        <p className="text-xs text-gray-400 mt-0.5">{formatDateTime(adj.created_at || adj.createdAt)}</p>
      </div>
      <div className="flex items-center gap-3 flex-shrink-0">
        <span className={`text-base font-bold ${isPositive ? 'text-green-500' : 'text-red-500'}`}>
          {isPositive ? '+' : ''}{formatCurrency(amount)}
        </span>
        <button
          onClick={() => onDelete(adj)}
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
export default function CashAdjustmentsPage() {
  const [showAdd, setShowAdd] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.CASH_ADJUSTMENTS)

  const adjustments = data?.data || data || []

  const handleSaved = () => {
    refetch()
    setShowAdd(false)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await api.delete(`${ENDPOINTS.CASH_ADJUSTMENTS}/${deleteTarget.id}`)
      toast.success('Adjustment deleted.')
      refetch()
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
        title="Cash Adjustments"
        subtitle="Add or deduct amounts from main or mano cash."
        action={
          <div className="flex items-center gap-2">
            <button onClick={refetch} className="btn-outline p-2" title="Refresh">
              <MdRefresh className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button onClick={() => setShowAdd(true)} className="btn-primary gap-1.5">
              <MdAdd className="w-5 h-5" /> New Adjustment
            </button>
          </div>
        }
      />

      {error ? (
        <ErrorState message={error} onRetry={refetch} />
      ) : loading && !adjustments.length ? (
        <div className="flex justify-center py-16"><LoadingSpinner /></div>
      ) : !adjustments.length ? (
        <EmptyState icon={MdTune} title="No Cash Adjustments" description="Add your first adjustment above." />
      ) : (
        <div className="space-y-2">
          {adjustments.map(adj => (
            <AdjRow key={adj.id} adj={adj} onDelete={setDeleteTarget} />
          ))}
        </div>
      )}

      <AddModal open={showAdd} onClose={() => setShowAdd(false)} onSaved={handleSaved} />

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Adjustment?"
        message="This adjustment will be permanently deleted. This cannot be undone."
        confirmLabel="Delete"
        variant="danger"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
