import { useState, useMemo } from 'react'
import { MdAdd, MdDelete, MdRefresh } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, formatDate } from '../../utils/formatters'
import api from '../../config/api'

const TYPE_OPTIONS = [
  { value: 'cash_in', label: 'Cash In' },
  { value: 'cash_out', label: 'Cash Out' },
]

function AddModal({ open, onClose, onSaved }) {
  const [form, setForm] = useState({ date: new Date().toISOString().slice(0, 10), type: 'cash_in', amount: '', notes: '' })
  const [loading, setLoading] = useState(false)

  const set = (k, v) => setForm(f => ({ ...f, [k]: v }))

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!form.amount || Number(form.amount) <= 0) { toast.error('Enter a valid amount.'); return }
    setLoading(true)
    try {
      await api.post(ENDPOINTS.SELF_TRANSACTIONS, form)
      toast.success('Transaction added.')
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to add transaction.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Self Transaction</h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Date</label>
            <input type="date" className="form-input" value={form.date} onChange={e => set('date', e.target.value)} required />
          </div>
          <div>
            <label className="form-label">Type</label>
            <select className="form-input" value={form.type} onChange={e => set('type', e.target.value)}>
              {TYPE_OPTIONS.map(t => <option key={t.value} value={t.value}>{t.label}</option>)}
            </select>
          </div>
          <div>
            <label className="form-label">Amount</label>
            <input type="number" step="0.01" min="0.01" className="form-input" placeholder="0.00" value={form.amount} onChange={e => set('amount', e.target.value)} required />
          </div>
          <div>
            <label className="form-label">Notes</label>
            <input type="text" className="form-input" placeholder="Optional notes" value={form.notes} onChange={e => set('notes', e.target.value)} />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : 'Add'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

export default function SelfTransactionsPage() {
  const [page, setPage] = useState(1)
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [showAdd, setShowAdd] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const params = useMemo(() => {
    const p = { page, per_page: 20 }
    if (from) p.from = from
    if (to) p.to = to
    return p
  }, [page, from, to])

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.SELF_TRANSACTIONS, params, [JSON.stringify(params)])

  const transactions = data?.data || []
  const meta = data?.meta || {}
  const totalPages = meta.last_page || 1
  const summary = data?.summary || {}

  const handleDelete = async () => {
    setDeleting(true)
    try {
      await api.delete(`${ENDPOINTS.SELF_TRANSACTIONS}/${deleteTarget.id}`)
      toast.success('Transaction deleted.')
      setDeleteTarget(null)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeleting(false)
    }
  }

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Self Transactions"
        action={
          <div className="flex gap-2">
            <button onClick={refetch} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>
            <button onClick={() => setShowAdd(true)} className="btn-primary gap-1"><MdAdd className="w-5 h-5" />Add</button>
          </div>
        }
      />

      {/* Filters */}
      <div className="card">
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="form-label">From</label>
            <input type="date" className="form-input" value={from} onChange={e => { setFrom(e.target.value); setPage(1) }} />
          </div>
          <div>
            <label className="form-label">To</label>
            <input type="date" className="form-input" value={to} onChange={e => { setTo(e.target.value); setPage(1) }} />
          </div>
        </div>
      </div>

      {/* Summary */}
      {(summary.total_in !== undefined || summary.total_out !== undefined) && (
        <div className="grid grid-cols-3 gap-3">
          <div className="card text-center">
            <p className="text-xs text-gray-500 mb-1">Cash In</p>
            <p className="font-bold text-green-600 dark:text-green-400">{formatCurrency(summary.total_in || 0)}</p>
          </div>
          <div className="card text-center">
            <p className="text-xs text-gray-500 mb-1">Cash Out</p>
            <p className="font-bold text-red-500">{formatCurrency(summary.total_out || 0)}</p>
          </div>
          <div className="card text-center">
            <p className="text-xs text-gray-500 mb-1">Net</p>
            <p className={`font-bold ${(summary.net || 0) >= 0 ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>{formatCurrency(summary.net || 0)}</p>
          </div>
        </div>
      )}

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && transactions.length === 0 ? (
        <div className="space-y-2">{[1,2,3].map(i => <div key={i} className="card animate-pulse h-16 bg-gray-100 dark:bg-white/5" />)}</div>
      ) : transactions.length === 0 ? (
        <EmptyState title="No transactions" />
      ) : (
        <div className="space-y-2">
          {transactions.map(tx => (
            <div key={tx.id} className="card flex items-center justify-between gap-4">
              <div className="flex items-center gap-3 min-w-0">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0 ${
                  tx.type === 'cash_in' ? 'bg-green-100 dark:bg-green-500/20 text-green-600 dark:text-green-400' : 'bg-red-100 dark:bg-red-500/20 text-red-500'
                }`}>
                  {tx.type === 'cash_in' ? '+' : '−'}
                </div>
                <div className="min-w-0">
                  <p className="text-sm font-medium text-navy dark:text-white">
                    {tx.type === 'cash_in' ? 'Cash In' : 'Cash Out'}
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 truncate">
                    {formatDate(tx.date)}{tx.notes ? ` · ${tx.notes}` : ''}
                  </p>
                </div>
              </div>
              <div className="flex items-center gap-3">
                <span className={`font-bold text-sm ${tx.type === 'cash_in' ? 'text-green-600 dark:text-green-400' : 'text-red-500'}`}>
                  {tx.type === 'cash_in' ? '+' : '−'}{formatCurrency(tx.amount)}
                </span>
                <button onClick={() => setDeleteTarget(tx)} className="p-1.5 text-red-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors">
                  <MdDelete className="w-4 h-4" />
                </button>
              </div>
            </div>
          ))}
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

      <AddModal open={showAdd} onClose={() => setShowAdd(false)} onSaved={() => { setShowAdd(false); refetch() }} />

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Transaction"
        message={`Delete this ${deleteTarget?.type === 'cash_in' ? 'cash in' : 'cash out'} of ${deleteTarget ? formatCurrency(deleteTarget.amount) : ''}?`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
        danger
      />
    </div>
  )
}
