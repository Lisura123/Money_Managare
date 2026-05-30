import { useState, useMemo, useCallback } from 'react'
import { MdFilterList, MdEdit, MdDelete, MdTune, MdRefresh } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import Card from '../../components/common/Card'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
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
  const showrooms = showroomsData?.data || []

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

      {/* Table */}
      <Card padding={false}>
        {loading && entries.length === 0 ? (
          <div className="p-8 text-center"><LoadingSpinner /></div>
        ) : entries.length === 0 ? (
          <div className="p-8"><EmptyState title="No entries found" /></div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-white/10 bg-gray-50 dark:bg-white/5">
                  <th className="text-left py-3 px-4 text-gray-500 font-medium">Date</th>
                  <th className="text-left py-3 px-4 text-gray-500 font-medium">Showroom</th>
                  <th className="text-left py-3 px-4 text-gray-500 font-medium">Staff</th>
                  <th className="text-left py-3 px-4 text-gray-500 font-medium">Type</th>
                  <th className="text-right py-3 px-4 text-gray-500 font-medium">Amount</th>
                  <th className="text-right py-3 px-4 text-gray-500 font-medium">Adjusted</th>
                  <th className="py-3 px-4"></th>
                </tr>
              </thead>
              <tbody>
                {entries.map(entry => (
                  <tr key={entry.id} className="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors">
                    <td className="py-3 px-4 text-navy dark:text-white font-medium">{formatDate(entry.entry_date)}</td>
                    <td className="py-3 px-4 text-gray-700 dark:text-gray-300">{entry.showroom?.name}</td>
                    <td className="py-3 px-4 text-gray-700 dark:text-gray-300">{entry.user?.name}</td>
                    <td className="py-3 px-4">
                      <span className={`text-xs font-medium px-2 py-0.5 rounded-full ${entry.cash_account_type === 'main' ? 'bg-teal/10 text-teal' : 'bg-blue-500/10 text-blue-600'}`}>
                        {entry.cash_account_type === 'main' ? 'Main' : "Mano's"}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right text-gray-700 dark:text-gray-300">{formatCurrency(entry.cash_amount)}</td>
                    <td className="py-3 px-4 text-right font-medium text-navy dark:text-white">{formatCurrency(entry.adjustments?.length > 0 ? entry.adjustments[entry.adjustments.length - 1].adjusted_amount : entry.cash_amount)}</td>
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-1 justify-end">
                        {!entry.is_locked && (
                          <button onClick={() => setEditEntry(entry)} className="p-1.5 rounded text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors" title="Edit"><MdEdit className="w-4 h-4" /></button>
                        )}
                        <button onClick={() => setAdjEntry(entry)} className="p-1.5 rounded text-gray-400 hover:text-blue-500 hover:bg-blue-500/10 transition-colors" title="Add Adjustment"><MdTune className="w-4 h-4" /></button>
                        <button onClick={() => setDeleteTarget(entry)} className="p-1.5 rounded text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors" title="Delete"><MdDelete className="w-4 h-4" /></button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-gray-200 dark:border-white/10">
            <p className="text-xs text-gray-500">Page {page} of {totalPages} · {meta.total} entries</p>
            <div className="flex gap-2">
              <button onClick={() => setPage(p => Math.max(1, p - 1))} disabled={page <= 1} className="btn-outline py-1 px-2 text-xs disabled:opacity-40">Prev</button>
              <button onClick={() => setPage(p => Math.min(totalPages, p + 1))} disabled={page >= totalPages} className="btn-outline py-1 px-2 text-xs disabled:opacity-40">Next</button>
            </div>
          </div>
        )}
      </Card>

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
