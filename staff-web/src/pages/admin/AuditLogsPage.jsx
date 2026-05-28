import { useState, useMemo } from 'react'
import { MdDelete, MdRefresh } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatDateTime } from '../../utils/formatters'
import api from '../../config/api'

export default function AuditLogsPage() {
  const [page, setPage] = useState(1)
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const params = useMemo(() => {
    const p = { page, per_page: 30 }
    if (from) p.from = from
    if (to) p.to = to
    return p
  }, [page, from, to])

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.AUDIT_LOGS, params, [JSON.stringify(params)])

  const logs = data?.data || []
  const meta = data?.meta || {}
  const totalPages = meta.last_page || 1

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

  const actionColor = (action) => {
    if (!action) return 'bg-gray-100 text-gray-600 dark:bg-white/10 dark:text-gray-400'
    const a = action.toLowerCase()
    if (a.includes('delete') || a.includes('destroy')) return 'bg-red-100 text-red-600 dark:bg-red-500/20 dark:text-red-400'
    if (a.includes('create') || a.includes('store')) return 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400'
    if (a.includes('update') || a.includes('edit') || a.includes('approve') || a.includes('reject')) return 'bg-blue-100 text-blue-600 dark:bg-blue-500/20 dark:text-blue-400'
    return 'bg-gray-100 text-gray-600 dark:bg-white/10 dark:text-gray-400'
  }

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Audit Logs"
        action={<button onClick={refetch} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>}
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

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && logs.length === 0 ? (
        <div className="space-y-2">{[1,2,3,4,5].map(i => <div key={i} className="card animate-pulse h-16 bg-gray-100 dark:bg-white/5" />)}</div>
      ) : logs.length === 0 ? (
        <EmptyState title="No audit logs" />
      ) : (
        <div className="space-y-2">
          {logs.map(log => (
            <div key={log.id} className="card flex items-start justify-between gap-3">
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-2 flex-wrap mb-0.5">
                  <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase ${actionColor(log.action)}`}>
                    {log.action || 'unknown'}
                  </span>
                  {log.auditable_type && (
                    <span className="text-[10px] text-gray-400 bg-gray-100 dark:bg-white/10 px-1.5 py-0.5 rounded">
                      {log.auditable_type?.split('\\').pop()}
                      {log.auditable_id ? ` #${log.auditable_id}` : ''}
                    </span>
                  )}
                </div>
                <p className="text-sm text-navy dark:text-white font-medium truncate">
                  {log.user?.name || log.user_name || 'System'}
                </p>
                {log.description && (
                  <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{log.description}</p>
                )}
                <p className="text-[11px] text-gray-400 mt-0.5">{formatDateTime(log.created_at)}</p>
              </div>
              <button
                onClick={() => setDeleteTarget(log)}
                className="p-1.5 text-red-400 hover:text-red-500 hover:bg-red-50 dark:hover:bg-red-500/10 rounded-lg transition-colors flex-shrink-0"
              >
                <MdDelete className="w-4 h-4" />
              </button>
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

      <ConfirmDialog
        open={!!deleteTarget}
        title="Delete Log Entry"
        message="Permanently delete this audit log entry?"
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
        danger
      />
    </div>
  )
}
