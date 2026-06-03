import { useState, useMemo } from 'react'
import { MdDelete, MdRefresh, MdExpandMore, MdExpandLess, MdFilterList, MdClose } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatDateTime, formatCurrency } from '../../utils/formatters'
import api from '../../config/api'

// ─── Constants ────────────────────────────────────────────────────────────────

const TABLE_OPTIONS = [
  { value: '', label: 'All Types' },
  { value: 'daily_cash_entries', label: 'Cash Entries' },
  { value: 'daily_card_entries', label: 'Card Entries' },
  { value: 'card_accounts', label: 'Card Accounts' },
  { value: 'self_transactions', label: 'Self Transfers' },
  { value: 'cash_transactions', label: 'Cash Transfers' },
  { value: 'admin_cash_adjustments', label: 'Cash Adjustments' },
  { value: 'admin_card_adjustments', label: 'Card Adjustments' },
  { value: 'users', label: 'Users' },
  { value: 'showrooms', label: 'Showrooms' },
]

const ACTION_OPTIONS = [
  { value: '', label: 'All Actions', color: '' },
  { value: 'created', label: 'Created', color: 'text-green-500' },
  { value: 'updated', label: 'Updated', color: 'text-blue-400' },
  { value: 'deleted', label: 'Deleted', color: 'text-red-500' },
  { value: 'password_changed', label: 'Password Changed', color: 'text-yellow-400' },
]

const TABLE_LABELS = Object.fromEntries(TABLE_OPTIONS.filter(o => o.value).map(o => [o.value, o.label]))

const entityLabel = (tableName) =>
  TABLE_LABELS[tableName] || tableName?.replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase()) || 'Record'

const ACTION_BADGE = {
  created: 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400',
  updated: 'bg-blue-100 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400',
  deleted: 'bg-red-100 text-red-600 dark:bg-red-500/20 dark:text-red-400',
  password_changed: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-500/20 dark:text-yellow-400',
}

const actionColor = (action) =>
  ACTION_BADGE[action?.toLowerCase()] || 'bg-gray-100 text-gray-600 dark:bg-white/10 dark:text-gray-400'

// Extract a human-readable one-line summary from the values object
function valueSummary(values) {
  if (!values || typeof values !== 'object') return null
  const v = values
  const parts = []
  if (v.amount != null) parts.push(`Amount: ${formatCurrency(v.amount)}`)
  if (v.cash_amount != null) parts.push(`Cash: ${formatCurrency(v.cash_amount)}`)
  if (v.adjusted_amount != null) parts.push(`Adjusted: ${formatCurrency(v.adjusted_amount)}`)
  if (v.cash_account_type) parts.push(`Account: ${v.cash_account_type === 'mano' ? 'Mano Cash' : 'Main Cash'}`)
  if (v.entry_date) parts.push(`Date: ${v.entry_date?.slice(0, 10)}`)
  if (v.name) parts.push(`Name: ${v.name}`)
  if (v.email) parts.push(`Email: ${v.email}`)
  if (v.reason) parts.push(`Reason: ${v.reason}`)
  if (v.notes) parts.push(`Notes: ${v.notes}`)
  if (v.bank_name) parts.push(`Bank: ${v.bank_name}`)
  if (v.last_four) parts.push(`Card: ••••${v.last_four}`)
  if (v.status) parts.push(`Status: ${v.status}`)
  return parts.length > 0 ? parts.slice(0, 3).join(' · ') : null
}

// Show diff between old and new values for updates
function ChangeDiff({ oldValues, newValues }) {
  if (!oldValues || !newValues) return null
  const SKIP = ['id', 'created_at', 'updated_at', 'user_id', 'admin_id', 'showroom_id']
  const keys = Object.keys(newValues).filter(k => !SKIP.includes(k) && oldValues[k] !== newValues[k])
  if (keys.length === 0) return null
  return (
    <div className="mt-2 space-y-1">
      {keys.map(k => (
        <div key={k} className="text-[11px] flex items-start gap-1.5 flex-wrap">
          <span className="text-gray-400 font-medium">{k.replace(/_/g, ' ')}:</span>
          <span className="text-red-400 line-through">{String(oldValues[k] ?? '—')}</span>
          <span className="text-gray-400">→</span>
          <span className="text-green-400">{String(newValues[k] ?? '—')}</span>
        </div>
      ))}
    </div>
  )
}

// ─── Filter Panel ─────────────────────────────────────────────────────────────
function FilterPanel({ tableFilter, actionFilter, dateFrom, dateTo, useDateFilter,
  onTableChange, onActionChange, onDateFromChange, onDateToChange, onUseDateChange,
  onApply, onReset, onClose }) {
  return (
    <div className="fixed inset-0 z-50 flex items-end sm:items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl w-full max-w-sm animate-fade-in overflow-y-auto max-h-[85vh]">
        <div className="flex items-center justify-between p-4 border-b border-gray-100 dark:border-white/10">
          <h3 className="font-heading font-semibold text-navy dark:text-white text-base">Filter Audit Log</h3>
          <button onClick={onClose} className="p-1.5 rounded-lg text-gray-400 hover:text-navy dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/10 transition-colors">
            <MdClose className="w-5 h-5" />
          </button>
        </div>

        <div className="p-4 space-y-5">
          {/* Record Type */}
          <div>
            <p className="form-label mb-2">Record Type</p>
            <div className="space-y-1">
              {TABLE_OPTIONS.map(opt => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => onTableChange(opt.value)}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm transition-colors ${
                    tableFilter === opt.value
                      ? 'bg-teal/10 text-teal font-medium'
                      : 'text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5'
                  }`}
                >
                  <span>{opt.label}</span>
                  {tableFilter === opt.value && (
                    <span className="w-2 h-2 rounded-full bg-teal" />
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Action */}
          <div>
            <p className="form-label mb-2">Action</p>
            <div className="space-y-1">
              {ACTION_OPTIONS.map(opt => (
                <button
                  key={opt.value}
                  type="button"
                  onClick={() => onActionChange(opt.value)}
                  className={`w-full flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-colors ${
                    actionFilter === opt.value
                      ? 'bg-teal/10 text-teal font-medium'
                      : 'text-gray-600 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5'
                  }`}
                >
                  <span className={`w-2 h-2 rounded-full flex-shrink-0 ${opt.color ? opt.color.replace('text-', 'bg-') : 'bg-gray-400'}`} />
                  <span className="flex-1 text-left">{opt.label}</span>
                  {actionFilter === opt.value && (
                    <span className="w-2 h-2 rounded-full bg-teal" />
                  )}
                </button>
              ))}
            </div>
          </div>

          {/* Date Range */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <p className="form-label mb-0">Date Range</p>
              <label className="flex items-center gap-2 cursor-pointer">
                <div
                  onClick={() => onUseDateChange(!useDateFilter)}
                  className={`w-10 h-5 rounded-full relative transition-colors ${useDateFilter ? 'bg-teal' : 'bg-gray-300 dark:bg-white/20'}`}
                >
                  <span className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-transform ${useDateFilter ? 'translate-x-5' : 'translate-x-0.5'}`} />
                </div>
              </label>
            </div>
            {useDateFilter && (
              <div className="space-y-2">
                <div>
                  <label className="form-label text-xs">From</label>
                  <input type="date" className="form-input" value={dateFrom} onChange={e => onDateFromChange(e.target.value)} />
                </div>
                <div>
                  <label className="form-label text-xs">To</label>
                  <input type="date" className="form-input" min={dateFrom} value={dateTo} onChange={e => onDateToChange(e.target.value)} />
                </div>
              </div>
            )}
          </div>
        </div>

        <div className="flex gap-3 p-4 border-t border-gray-100 dark:border-white/10">
          <button onClick={onReset} className="btn-outline flex-1 justify-center text-red-500 border-red-200 dark:border-red-500/30 hover:bg-red-50 dark:hover:bg-red-500/10">Reset</button>
          <button onClick={onApply} className="btn-primary flex-1 justify-center">Apply</button>
        </div>
      </div>
    </div>
  )
}

// ─── Active Filter Chip ───────────────────────────────────────────────────────
function FilterChip({ label, onRemove }) {
  return (
    <span className="inline-flex items-center gap-1.5 px-3 py-1 bg-teal/10 text-teal rounded-full text-xs font-medium">
      {label}
      <button onClick={onRemove} className="hover:text-teal/70 transition-colors">
        <MdClose className="w-3 h-3" />
      </button>
    </span>
  )
}
function LogRow({ log, onDelete }) {
  const [expanded, setExpanded] = useState(false)
  const values = log.action === 'deleted' ? log.old_values : log.new_values
  const summary = valueSummary(values)
  const hasDetails = log.action === 'updated' && log.old_values && log.new_values

  return (
    <div className="card">
      <div className="flex items-start justify-between gap-3">
        <div className="flex-1 min-w-0">
          {/* Badges */}
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wide ${actionColor(log.action)}`}>
              {log.action || 'unknown'}
            </span>
            <span className="text-[10px] text-gray-400 bg-gray-100 dark:bg-white/10 px-2 py-0.5 rounded-full">
              {entityLabel(log.table_name)}
              {log.record_id ? ` #${log.record_id}` : ''}
            </span>
          </div>

          {/* User */}
          <p className="text-sm font-semibold text-navy dark:text-white">
            {log.user?.name || 'System'}
            {log.user?.role && (
              <span className="ml-1.5 text-[10px] font-normal text-gray-400 capitalize">({log.user.role})</span>
            )}
          </p>

          {/* Summary line */}
          {summary && <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 truncate">{summary}</p>}

          {/* Diff (updates) */}
          {expanded && hasDetails && (
            <ChangeDiff oldValues={log.old_values} newValues={log.new_values} />
          )}

          {/* Date */}
          <p className="text-[11px] text-gray-400 mt-1">{formatDateTime(log.created_at)}</p>
        </div>

        <div className="flex items-center gap-1 flex-shrink-0">
          {hasDetails && (
            <button
              onClick={() => setExpanded(e => !e)}
              className="p-1.5 text-gray-400 hover:text-navy dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/10 rounded-lg transition-colors"
              title={expanded ? 'Collapse' : 'Show changes'}
            >
              {expanded ? <MdExpandLess className="w-4 h-4" /> : <MdExpandMore className="w-4 h-4" />}
            </button>
          )}
          <button
            onClick={() => onDelete(log)}
            className="p-1.5 text-red-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors"
            title="Delete"
          >
            <MdDelete className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function AuditLogsPage() {
  const [page, setPage] = useState(1)
  const [showFilters, setShowFilters] = useState(false)

  // filter state
  const [tableFilter, setTableFilter] = useState('')
  const [actionFilter, setActionFilter] = useState('')
  const [useDateFilter, setUseDateFilter] = useState(false)
  const today = new Date().toISOString().slice(0, 10)
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().slice(0, 10)
  const [dateFrom, setDateFrom] = useState(sevenDaysAgo)
  const [dateTo, setDateTo] = useState(today)

  // applied (committed) filters — only sent to API after Apply
  const [applied, setApplied] = useState({ tableFilter: '', actionFilter: '', useDateFilter: false, dateFrom: sevenDaysAgo, dateTo: today })

  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const params = useMemo(() => {
    const p = { page, per_page: 30 }
    if (applied.tableFilter) p.table_name = applied.tableFilter
    if (applied.actionFilter) p.action = applied.actionFilter
    if (applied.useDateFilter && applied.dateFrom) p.date_from = applied.dateFrom
    if (applied.useDateFilter && applied.dateTo) p.date_to = applied.dateTo
    return p
  }, [page, applied])

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.AUDIT_LOGS, params, [JSON.stringify(params)])

  const logs = data?.data || []
  const totalPages = data?.last_page || 1

  const activeCount = (applied.tableFilter ? 1 : 0) + (applied.actionFilter ? 1 : 0) + (applied.useDateFilter ? 1 : 0)

  const handleApply = () => {
    setApplied({ tableFilter, actionFilter, useDateFilter, dateFrom, dateTo })
    setPage(1)
    setShowFilters(false)
  }

  const handleReset = () => {
    setTableFilter(''); setActionFilter(''); setUseDateFilter(false)
    setDateFrom(sevenDaysAgo); setDateTo(today)
    setApplied({ tableFilter: '', actionFilter: '', useDateFilter: false, dateFrom: sevenDaysAgo, dateTo: today })
    setPage(1)
    setShowFilters(false)
  }

  const handleDelete = async () => {
    setDeleting(true)
    try {
      await api.delete(`${ENDPOINTS.AUDIT_LOGS}/${deleteTarget.id}`)
      toast.success('Log entry deleted.')
      setDeleteTarget(null)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete log.')
    } finally {
      setDeleting(false)
    }
  }

  const tableLabel = TABLE_OPTIONS.find(o => o.value === applied.tableFilter)?.label
  const actionLabel = ACTION_OPTIONS.find(o => o.value === applied.actionFilter)?.label

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Audit Logs"
        action={
          <div className="flex items-center gap-2">
            <button onClick={refetch} className="btn-outline p-2" title="Refresh">
              <MdRefresh className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
            </button>
            <button
              onClick={() => setShowFilters(true)}
              className={`btn-outline flex items-center gap-1.5 relative ${activeCount > 0 ? 'border-teal text-teal' : ''}`}
            >
              <MdFilterList className="w-5 h-5" />
              Filter
              {activeCount > 0 && (
                <span className="ml-0.5 bg-teal text-white text-[10px] font-bold w-4 h-4 rounded-full flex items-center justify-center">
                  {activeCount}
                </span>
              )}
            </button>
          </div>
        }
      />

      {/* Active filter chips */}
      {activeCount > 0 && (
        <div className="flex flex-wrap gap-2">
          {applied.tableFilter && (
            <FilterChip label={tableLabel} onRemove={() => { setTableFilter(''); setApplied(a => ({ ...a, tableFilter: '' })); setPage(1) }} />
          )}
          {applied.actionFilter && (
            <FilterChip label={actionLabel} onRemove={() => { setActionFilter(''); setApplied(a => ({ ...a, actionFilter: '' })); setPage(1) }} />
          )}
          {applied.useDateFilter && (
            <FilterChip
              label={`${applied.dateFrom} – ${applied.dateTo}`}
              onRemove={() => { setUseDateFilter(false); setApplied(a => ({ ...a, useDateFilter: false })); setPage(1) }}
            />
          )}
        </div>
      )}

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && logs.length === 0 ? (
        <div className="space-y-2">{[1,2,3,4,5].map(i => <div key={i} className="card animate-pulse h-16 bg-gray-100 dark:bg-white/5" />)}</div>
      ) : logs.length === 0 ? (
        <EmptyState title="No audit logs" description={activeCount > 0 ? 'No records match the current filters.' : undefined} />
      ) : (
        <div className="space-y-2">
          {logs.map(log => (
            <LogRow key={log.id} log={log} onDelete={setDeleteTarget} />
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

      {showFilters && (
        <FilterPanel
          tableFilter={tableFilter} actionFilter={actionFilter}
          dateFrom={dateFrom} dateTo={dateTo} useDateFilter={useDateFilter}
          onTableChange={setTableFilter} onActionChange={setActionFilter}
          onDateFromChange={setDateFrom} onDateToChange={setDateTo}
          onUseDateChange={setUseDateFilter}
          onApply={handleApply} onReset={handleReset}
          onClose={() => setShowFilters(false)}
        />
      )}

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Log Entry"
        message="Permanently delete this audit log entry?"
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
        variant="danger"
      />
    </div>
  )
}
