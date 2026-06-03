import { useState, useEffect, useCallback } from 'react'
import { MdAdd, MdDelete, MdRefresh, MdCreditCard } from 'react-icons/md'
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

const maskCard = (lastFour) => lastFour ? `••••${lastFour}` : '—'

// ─── Add Modal ────────────────────────────────────────────────────────────────
function AddModal({ open, onClose, onSaved }) {
  const [cardAccounts, setCardAccounts] = useState([])
  const [accsLoading, setAccsLoading] = useState(false)
  const [selectedShowroom, setSelectedShowroom] = useState('')
  const [selectedAccountId, setSelectedAccountId] = useState('')
  const [operation, setOperation] = useState('add')
  const [amount, setAmount] = useState('')
  const [reason, setReason] = useState('')
  const [loading, setLoading] = useState(false)

  const fetchAccounts = useCallback(async () => {
    setAccsLoading(true)
    try {
      const res = await api.get(ENDPOINTS.CARD_ACCOUNTS)
      setCardAccounts(res.data?.data || res.data || [])
    } catch {
      toast.error('Failed to load card accounts.')
    } finally {
      setAccsLoading(false)
    }
  }, [])

  useEffect(() => {
    if (open) fetchAccounts()
  }, [open, fetchAccounts])

  const uniqueShowrooms = [...new Set(
    cardAccounts.map(c => c.showroom_name || c.showroomName || '').filter(Boolean)
  )].sort()

  const filteredAccounts = cardAccounts.filter(
    c => (c.showroom_name || c.showroomName) === selectedShowroom
  )

  const selectedAccount = cardAccounts.find(c => String(c.id) === String(selectedAccountId))

  const parsed = parseFloat(amount) || 0
  const signedAmount = operation === 'add' ? parsed : -parsed
  const currentBalance = parseFloat(selectedAccount?.current_balance ?? selectedAccount?.currentBalance ?? 0)
  const newBalance = currentBalance + signedAmount
  const showPreview = parsed > 0 && selectedAccount

  const reset = () => {
    setSelectedShowroom('')
    setSelectedAccountId('')
    setOperation('add')
    setAmount('')
    setReason('')
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!selectedAccountId) { toast.error('Select a card account.'); return }
    if (parsed <= 0) { toast.error('Enter a valid amount.'); return }
    if (!reason.trim()) { toast.error('Reason is required.'); return }
    setLoading(true)
    try {
      await api.post(ENDPOINTS.CARD_ADJUSTMENTS, {
        card_account_id: Number(selectedAccountId),
        adjusted_amount: signedAmount,
        reason: reason.trim(),
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
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Card Adjustment</h3>

        <form onSubmit={handleSubmit} className="space-y-4">
          {/* Showroom */}
          <div>
            <label className="form-label">Showroom</label>
            {accsLoading ? (
              <div className="flex items-center gap-2 py-2"><LoadingSpinner size="sm" /><span className="text-sm text-gray-400">Loading accounts…</span></div>
            ) : (
              <select
                className="form-input"
                value={selectedShowroom}
                onChange={e => { setSelectedShowroom(e.target.value); setSelectedAccountId('') }}
                required
              >
                <option value="">Select showroom</option>
                {uniqueShowrooms.map(name => (
                  <option key={name} value={name}>{name}</option>
                ))}
              </select>
            )}
          </div>

          {/* Card Account */}
          {selectedShowroom && (
            <div>
              <label className="form-label">Card Account</label>
              <select
                className="form-input"
                value={selectedAccountId}
                onChange={e => setSelectedAccountId(e.target.value)}
                required
              >
                <option value="">Select account</option>
                {filteredAccounts.map(c => (
                  <option key={c.id} value={c.id}>
                    {c.bank_name || c.bankName || 'Unknown'} {maskCard(c.last_four || c.lastFour)}
                  </option>
                ))}
              </select>
              {selectedAccount && (
                <p className="text-xs text-gray-400 mt-1">
                  Balance: <span className="font-semibold text-teal">{formatCurrency(currentBalance)}</span>
                </p>
              )}
            </div>
          )}

          {/* Operation */}
          {selectedAccountId && (
            <>
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

              <div>
                <label className="form-label">Amount (Rs.) *</label>
                <input
                  className="form-input" type="number" step="0.01" min="0.01"
                  value={amount} onChange={e => setAmount(e.target.value)} required
                />
              </div>

              <div>
                <label className="form-label">Reason *</label>
                <input
                  className="form-input" type="text"
                  value={reason} onChange={e => setReason(e.target.value)}
                  placeholder="e.g. Commission payment" required
                />
              </div>

              {showPreview && (
                <div className="bg-gray-50 dark:bg-white/5 rounded-xl px-4 py-3 flex items-center justify-between">
                  <span className="text-xs text-gray-500">New Balance</span>
                  <span className={`text-sm font-bold ${newBalance >= 0 ? 'text-green-500' : 'text-red-500'}`}>
                    {formatCurrency(newBalance)}
                  </span>
                </div>
              )}
            </>
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
  const accountLabel = adj.account_label || adj.accountLabel
    || `${adj.bank_name || adj.bankName || 'Unknown'} ${maskCard(adj.last_four || adj.lastFour)}`

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
export default function CardAdjustmentsPage() {
  const [showAdd, setShowAdd] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.CARD_ADJUSTMENTS)

  const adjustments = data?.data || data || []

  const handleSaved = () => {
    refetch()
    setShowAdd(false)
  }

  const handleDelete = async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      await api.delete(`${ENDPOINTS.CARD_ADJUSTMENTS}/${deleteTarget.id}`)
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
        title="Card Adjustments"
        subtitle="Add or deduct amounts from card accounts."
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
        <EmptyState icon={MdCreditCard} title="No Card Adjustments" description="Add your first adjustment above." />
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
