import { useState, useMemo, useCallback } from 'react'
import { MdFilterList, MdEdit, MdDelete, MdTune, MdRefresh } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import Card from '../../components/common/Card'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, formatDate, todayString } from '../../utils/formatters'
import api from '../../config/api'

const ACCOUNT_TYPES = [
  { value: '', label: 'All Accounts' },
  { value: 'main', label: 'Main Account' },
  { value: 'mano', label: "Mano's Account" },
]

// ─── Edit Cash Entry Modal ────────────────────────────────────────────────────
function EditEntryModal({ open, entry, onClose, onSaved }) {
  const [amount, setAmount] = useState(entry?.cash_amount || '')
  const [notes, setNotes] = useState(entry?.notes || '')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      await api.put(`/cash-entries/${entry.id}`, { cash_amount: parseFloat(amount), notes: notes.trim() || null })
      toast.success('Entry updated.')
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to update.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-1">Edit Cash Entry</h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">{entry?.showroom?.name} · {formatDate(entry?.entry_date)}</p>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Cash Amount (Rs.) *</label>
            <input className="form-input" type="number" value={amount} onChange={e => setAmount(e.target.value)} step="0.01" min="0" required />
          </div>
          <div>
            <label className="form-label">Notes</label>
            <textarea className="form-input" rows={2} value={notes} onChange={e => setNotes(e.target.value)} />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : 'Update'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Adjustment Modal ─────────────────────────────────────────────────────────
function AdjustmentModal({ open, entry, type, onClose, onSaved }) {
  const [amount, setAmount] = useState('')
  const [reason, setReason] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      const endpoint = type === 'cash'
        ? `/cash-entries/${entry.id}/adjustments`
        : `/card-entries/${entry.id}/adjustments`
      await api.post(endpoint, { amount: parseFloat(amount), reason: reason.trim() })
      toast.success('Adjustment added.')
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to add adjustment.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-1">Add Adjustment</h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">{formatDate(entry?.entry_date)}</p>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Amount (Rs.) — positive or negative *</label>
            <input className="form-input" type="number" value={amount} onChange={e => setAmount(e.target.value)} step="0.01" required />
          </div>
          <div>
            <label className="form-label">Reason *</label>
            <input className="form-input" value={reason} onChange={e => setReason(e.target.value)} placeholder="e.g. Correction for missed sale" required />
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

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function CashEntriesAdminPage() {
  const today = todayString()
  const [from, setFrom] = useState(today)
  const [to, setTo] = useState(today)
  const [showroomId, setShowroomId] = useState('')
  const [accountType, setAccountType] = useState('')
  const [page, setPage] = useState(1)
  const [editEntry, setEditEntry] = useState(null)
  const [adjEntry, setAdjEntry] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const { data: showroomsData } = useFetch(ENDPOINTS.SHOWROOMS)
  const showrooms = Array.isArray(showroomsData) ? showroomsData : (showroomsData?.data || [])

  const params = useMemo(() => {
    const p = { page, per_page: 20 }
    if (from) p.from = from
    if (to) p.to = to
    if (showroomId) p.showroom_id = showroomId
    if (accountType) p.cash_account_type = accountType
    return p
  }, [page, from, to, showroomId, accountType])

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.ADMIN_CASH_ENTRIES, params, [JSON.stringify(params)])

  const entries = data?.data || []
  const meta = data?.meta || {}
  const totalPages = meta.last_page || 1

  const handleDelete = useCallback(async () => {
    setDeleting(true)
    try {
      await api.delete(`/cash-entries/${deleteTarget.id}`)
      toast.success('Entry deleted.')
      setDeleteTarget(null)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeleting(false)
    }
  }, [deleteTarget, refetch])

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Cash Entries"
        action={
          <button onClick={() => refetch()} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>
        }
      />

      {/* Filters */}
      <Card>
        <div className="flex items-center gap-2 mb-3">
          <MdFilterList className="w-4 h-4 text-gray-400" />
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Filters</span>
        </div>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          <div>
            <label className="form-label">From</label>
            <input type="date" className="form-input" value={from} onChange={e => { setFrom(e.target.value); setPage(1) }} />
          </div>
          <div>
            <label className="form-label">To</label>
            <input type="date" className="form-input" value={to} onChange={e => { setTo(e.target.value); setPage(1) }} />
          </div>
          <div>
            <label className="form-label">Showroom</label>
            <select className="form-input" value={showroomId} onChange={e => { setShowroomId(e.target.value); setPage(1) }}>
              <option value="">All Showrooms</option>
              {showrooms.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>
          <div>
            <label className="form-label">Account</label>
            <select className="form-input" value={accountType} onChange={e => { setAccountType(e.target.value); setPage(1) }}>
              {ACCOUNT_TYPES.map(a => <option key={a.value} value={a.value}>{a.label}</option>)}
            </select>
          </div>
        </div>
      </Card>

      {error && <ErrorState message={error} onRetry={refetch} />}

      {/* Entry List */}
      {loading && entries.length === 0 ? (
        <div className="space-y-2">
          {[1, 2, 3, 4].map(i => <div key={i} className="card animate-pulse h-20 bg-gray-100 dark:bg-white/5" />)}
        </div>
      ) : entries.length === 0 ? (
        <EmptyState title="No entries found" />
      ) : (
        <div className="space-y-2">
          {entries.map(entry => {
            const adjustedAmount = entry.adjustments?.length > 0
              ? entry.adjustments[entry.adjustments.length - 1].adjusted_amount
              : entry.cash_amount
            const isAdjusted = parseFloat(adjustedAmount) !== parseFloat(entry.cash_amount)
            return (
              <div key={entry.id} className="card flex items-center justify-between gap-3">
                <div className="flex-1 min-w-0 space-y-0.5">
                  <p className="text-sm font-semibold text-navy dark:text-white">{formatDate(entry.entry_date)}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400">{entry.user?.name}</p>
                  <div className="flex items-center gap-2">
                    <p className="text-xs text-gray-400 dark:text-gray-500">{entry.showroom?.name}</p>
                    <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded-full ${
                      entry.cash_account_type === 'main' ? 'bg-teal/10 text-teal' : 'bg-blue-500/10 text-blue-600 dark:text-blue-400'
                    }`}>
                      {entry.cash_account_type === 'main' ? 'Main' : "Mano's"}
                    </span>
                  </div>
                </div>
                <div className="text-right flex-shrink-0 space-y-0.5">
                  <p className="text-base font-bold text-navy dark:text-white">{formatCurrency(adjustedAmount)}</p>
                  {isAdjusted && (
                    <p className="text-[10px] text-gray-400 line-through">{formatCurrency(entry.cash_amount)}</p>
                  )}
                  {entry.is_locked && (
                    <p className="text-[10px] text-amber-500 font-medium">Locked</p>
                  )}
                </div>
                <div className="flex flex-col gap-1 flex-shrink-0">
                  {!entry.is_locked && (
                    <button onClick={() => setEditEntry(entry)} className="p-1.5 rounded text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors" title="Edit">
                      <MdEdit className="w-4 h-4" />
                    </button>
                  )}
                  <button onClick={() => setAdjEntry(entry)} className="p-1.5 rounded text-gray-400 hover:text-blue-500 hover:bg-blue-500/10 transition-colors" title="Add Adjustment">
                    <MdTune className="w-4 h-4" />
                  </button>
                  <button onClick={() => setDeleteTarget(entry)} className="p-1.5 rounded text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors" title="Delete">
                    <MdDelete className="w-4 h-4" />
                  </button>
                </div>
              </div>
            )
          })}
        </div>
      )}

      {/* Pagination */}
      {totalPages > 1 && (
        <div className="flex items-center justify-between">
          <p className="text-xs text-gray-500">Page {page} of {totalPages} · {meta.total} entries</p>
          <div className="flex gap-2">
            <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="btn-outline py-1 px-2 text-xs disabled:opacity-40">Prev</button>
            <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages} className="btn-outline py-1 px-2 text-xs disabled:opacity-40">Next</button>
          </div>
        </div>
      )}

      <EditEntryModal
        open={!!editEntry}
        entry={editEntry}
        onClose={() => setEditEntry(null)}
        onSaved={() => { setEditEntry(null); refetch() }}
      />
      <AdjustmentModal
        open={!!adjEntry}
        entry={adjEntry}
        type="cash"
        onClose={() => setAdjEntry(null)}
        onSaved={() => { setAdjEntry(null); refetch() }}
      />
      <ConfirmDialog
        open={!!deleteTarget}
        danger
        title="Delete Entry"
        message={`Delete this cash entry of ${formatCurrency(deleteTarget?.cash_amount)} for ${deleteTarget?.showroom?.name}?`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}
