import { useState, useMemo, useCallback, useEffect } from 'react'
import { MdFilterList, MdEdit, MdDelete, MdTune, MdRefresh, MdAdd, MdAccessTime, MdNotes } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import Card from '../../components/common/Card'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { prioritizeShowrooms, showroomOptionLabel } from '../../utils/showroomPriority'
import { formatCurrency, formatDate, formatDateTimeShort, todayString } from '../../utils/formatters'
import api from '../../config/api'

const ACCOUNT_TYPES = [
  { value: '', label: 'All Accounts' },
  { value: 'main', label: 'Main Account' },
  { value: 'mano', label: "Mano's Account" },
]

// ─── Create Cash Entry Modal ──────────────────────────────────────────────────
function CreateEntryModal({ open, showrooms, onClose, onSaved }) {
  const [showroomId, setShowroomId] = useState('')
  const [accountType, setAccountType] = useState('main')
  const [entryDate, setEntryDate] = useState(todayString())
  const [amount, setAmount] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)

  const reset = () => {
    setShowroomId(''); setAccountType('main'); setEntryDate(todayString())
    setAmount(''); setNotes('')
  }

  const handleClose = () => { reset(); onClose() }

  const handleSubmit = async (e) => {
    e.preventDefault()
    const isMano = accountType === 'mano'
    if (!isMano && !showroomId) { toast.error('Please select a showroom.'); return }
    const value = parseFloat(amount)
    if (!(value > 0)) { toast.error('Enter a valid amount.'); return }
    if (value >= 1_000_000 && !window.confirm(`You entered ${formatCurrency(value)}. Is this correct?`)) return
    setLoading(true)
    try {
      await api.post('/cash-entries', {
        cash_account_type: accountType,
        entry_date: entryDate,
        cash_amount: value,
        notes: notes.trim() || null,
        ...(isMano ? {} : { showroom_id: Number(showroomId) }),
      })
      toast.success('Cash entry created.')
      reset()
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to create entry.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={handleClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">New Cash Entry</h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Account *</label>
            <select className="form-input" value={accountType} onChange={e => setAccountType(e.target.value)}>
              <option value="main">Main Account</option>
              <option value="mano">Mano's Account</option>
            </select>
          </div>
          {accountType !== 'mano' && (
            <div>
              <label className="form-label">Showroom *</label>
              <select className="form-input" value={showroomId} onChange={e => setShowroomId(e.target.value)} required>
                <option value="">Select a showroom…</option>
                {prioritizeShowrooms(showrooms).map(s => <option key={s.id} value={s.id}>{showroomOptionLabel(s.name)}</option>)}
              </select>
            </div>
          )}
          <div>
            <label className="form-label">Date *</label>
            <input className="form-input" type="date" value={entryDate} max={todayString()} onChange={e => setEntryDate(e.target.value)} required />
          </div>
          <div>
            <label className="form-label">Cash Amount (Rs.) *</label>
            <input className="form-input" type="number" value={amount} onChange={e => setAmount(e.target.value)} step="0.01" min="0" placeholder="0.00" required />
          </div>
          <div>
            <label className="form-label">Notes</label>
            <textarea className="form-input" rows={2} value={notes} onChange={e => setNotes(e.target.value)} placeholder="Optional" />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={handleClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : 'Create'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Edit Cash Entry Modal ────────────────────────────────────────────────────
function EditEntryModal({ open, entry, onClose, onSaved }) {
  const [mode, setMode] = useState('add')
  const [delta, setDelta] = useState('')
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open && entry) {
      setMode('add')
      setDelta('')
      setNotes(entry.notes || '')
    }
  }, [open, entry])

  const currentVal = parseFloat(entry?.cash_amount || 0)
  const deltaVal = parseFloat(delta) || 0
  const newAmount = mode === 'add' ? currentVal + deltaVal : currentVal - deltaVal

  const handleSubmit = async (e) => {
    e.preventDefault()
    const dVal = parseFloat(delta)
    if (isNaN(dVal) || dVal <= 0) {
      toast.error('Please enter a valid adjustment amount.')
      return
    }
    if (newAmount < 0) {
      toast.error('Resulting amount cannot be negative.')
      return
    }
    setLoading(true)
    try {
      await api.put(`/cash-entries/${entry.id}`, {
        cash_amount: parseFloat(newAmount.toFixed(2)),
        notes: notes.trim() || null,
      })
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
        <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
          {entry?.showroom?.name || "Mano's Account"} · {formatDate(entry?.entry_date)}
        </p>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="flex justify-between items-center text-xs text-gray-500 dark:text-gray-400 border-b border-gray-100 dark:border-gray-800 pb-2">
            <span>Current Amount:</span>
            <span className="font-semibold text-gray-700 dark:text-gray-300">{formatCurrency(currentVal)}</span>
          </div>

          <div>
            <label className="form-label mb-1.5">Adjustment Action</label>
            <div className="grid grid-cols-2 gap-2">
              <button
                type="button"
                onClick={() => setMode('add')}
                className={`py-2 px-3 text-xs font-semibold rounded-lg transition-colors border ${
                  mode === 'add'
                    ? 'bg-teal/10 border-teal text-teal dark:bg-teal/20'
                    : 'border-gray-200 dark:border-gray-700 text-gray-500 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                Add Amount
              </button>
              <button
                type="button"
                onClick={() => setMode('deduct')}
                className={`py-2 px-3 text-xs font-semibold rounded-lg transition-colors border ${
                  mode === 'deduct'
                    ? 'bg-red-500/10 border-red-500 text-red-500 dark:bg-red-500/20'
                    : 'border-gray-200 dark:border-gray-700 text-gray-500 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                Deduct Amount
              </button>
            </div>
          </div>

          <div>
            <label className="form-label">
              {mode === 'add' ? 'Amount to Add (Rs.) *' : 'Amount to Deduct (Rs.) *'}
            </label>
            <input
              className="form-input"
              type="number"
              value={delta}
              onChange={(e) => setDelta(e.target.value)}
              step="0.01"
              min="0.01"
              placeholder="0.00"
              required
            />
          </div>

          <div className="flex justify-between items-center text-sm font-semibold border-t border-gray-100 dark:border-gray-800 pt-3">
            <span className="text-gray-600 dark:text-gray-400">New Resulting Amount:</span>
            <span className={`font-bold ${newAmount >= 0 ? 'text-teal' : 'text-red-500'}`}>
              {formatCurrency(newAmount)}
            </span>
          </div>

          <div>
            <label className="form-label">Notes</label>
            <textarea
              className="form-input"
              rows={2}
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
              placeholder="Provide a reason for the adjustment"
            />
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
  const [showroomId, setShowroomId] = useState('')
  const [accountType, setAccountType] = useState('')
  const [page, setPage] = useState(1)
  const [createOpen, setCreateOpen] = useState(false)
  const [editEntry, setEditEntry] = useState(null)
  const [adjEntry, setAdjEntry] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const { data: showroomsData } = useFetch(ENDPOINTS.SHOWROOMS)
  const showrooms = Array.isArray(showroomsData) ? showroomsData : (showroomsData?.data || [])

  const params = useMemo(() => {
    const p = { page, per_page: 20 }
    if (showroomId) p.showroom_id = showroomId
    if (accountType) p.cash_account_type = accountType
    return p
  }, [page, showroomId, accountType])

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
          <div className="flex items-center gap-2">
            <button onClick={() => setCreateOpen(true)} className="btn-primary py-2 px-3 text-sm">
              <MdAdd className="w-4 h-4" /> New Entry
            </button>
            <button onClick={() => refetch()} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>
          </div>
        }
      />

      {/* Filters */}
      <Card>
        <div className="flex items-center gap-2 mb-3">
          <MdFilterList className="w-4 h-4 text-gray-400" />
          <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Filters</span>
        </div>
        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className="form-label">Showroom</label>
            <select className="form-input" value={showroomId} onChange={e => { setShowroomId(e.target.value); setPage(1) }}>
              <option value="">All Showrooms</option>
              {prioritizeShowrooms(showrooms).map(s => <option key={s.id} value={s.id}>{showroomOptionLabel(s.name)}</option>)}
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
            const isMano = entry.cash_account_type === 'mano'
            const submittedAt = entry.created_at ? formatDateTimeShort(entry.created_at) : null
            return (
              <div key={entry.id} className="card flex items-start justify-between gap-3">
                <div className="flex-1 min-w-0 space-y-1">
                  {/* Date + time */}
                  <div className="flex items-center gap-2">
                    <p className="text-sm font-semibold text-navy dark:text-white">{formatDate(entry.entry_date)}</p>
                    {submittedAt && (
                      <span className="flex items-center gap-1 text-[10px] text-gray-400">
                        <MdAccessTime className="w-3 h-3" />{submittedAt}
                      </span>
                    )}
                  </div>
                  {/* Staff name */}
                  <p className="text-xs font-medium text-gray-500 dark:text-gray-400">{entry.user?.name}</p>
                  {/* Showroom + account badge */}
                  <div className="flex items-center gap-2 flex-wrap">
                    {entry.showroom?.name && (
                      <p className="text-xs text-gray-400 dark:text-gray-500">{entry.showroom.name}</p>
                    )}
                    <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded-full ${
                      isMano ? 'bg-blue-500/10 text-blue-500 dark:text-blue-400' : 'bg-teal/10 text-teal'
                    }`}>
                      {isMano ? "Mano's" : 'Main'}
                    </span>
                  </div>
                  {/* Notes */}
                  {entry.notes && (
                    <div className="flex items-start gap-1 text-[11px] text-gray-400">
                      <MdNotes className="w-3.5 h-3.5 mt-px flex-shrink-0" />
                      <span className="italic">{entry.notes}</span>
                    </div>
                  )}
                </div>
                <div className="flex items-start gap-2 flex-shrink-0">
                  <div className="text-right space-y-0.5">
                    <p className="text-base font-bold text-navy dark:text-white">{formatCurrency(adjustedAmount)}</p>
                    {isAdjusted && (
                      <p className="text-[10px] text-gray-400 line-through">{formatCurrency(entry.cash_amount)}</p>
                    )}
                    {entry.is_locked && (
                      <p className="text-[10px] text-amber-500 font-medium">Locked</p>
                    )}
                  </div>
                  <div className="flex flex-col gap-1">
                    <button onClick={() => setEditEntry(entry)} className="p-1.5 rounded text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors" title="Edit">
                      <MdEdit className="w-4 h-4" />
                    </button>
                    <button onClick={() => setAdjEntry(entry)} className="p-1.5 rounded text-gray-400 hover:text-blue-500 hover:bg-blue-500/10 transition-colors" title="Add Adjustment">
                      <MdTune className="w-4 h-4" />
                    </button>
                    <button onClick={() => setDeleteTarget(entry)} className="p-1.5 rounded text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors" title="Delete">
                      <MdDelete className="w-4 h-4" />
                    </button>
                  </div>
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

      <CreateEntryModal
        open={createOpen}
        showrooms={showrooms}
        onClose={() => setCreateOpen(false)}
        onSaved={() => { setCreateOpen(false); setPage(1); refetch() }}
      />
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
