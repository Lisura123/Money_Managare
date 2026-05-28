import { useState, useMemo, useCallback } from 'react'
import { MdCheck, MdClose, MdRefresh } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import Card from '../../components/common/Card'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, formatDate, formatDateTime } from '../../utils/formatters'
import api from '../../config/api'

const STATUS_TABS = [
  { value: 'pending', label: 'Pending' },
  { value: 'approved', label: 'Approved' },
  { value: 'rejected', label: 'Rejected' },
  { value: '', label: 'All' },
]

// ─── Review Modal ─────────────────────────────────────────────────────────────
function ReviewModal({ open, request, action, onClose, onSaved }) {
  const [notes, setNotes] = useState('')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    setLoading(true)
    try {
      const endpoint = `/edit-requests/${request.id}/${action}`
      await api.put(endpoint, { reviewer_notes: notes.trim() || null })
      toast.success(`Request ${action}d.`)
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || `Failed to ${action} request.`)
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  const isApprove = action === 'approve'

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-1">
          {isApprove ? 'Approve' : 'Reject'} Edit Request
        </h3>
        <p className="text-xs text-gray-500 dark:text-gray-400 mb-4">
          By {request?.user?.name} · {formatDate(request?.created_at)}
        </p>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Notes (optional)</label>
            <textarea
              className="form-input"
              rows={3}
              value={notes}
              onChange={e => setNotes(e.target.value)}
              placeholder={isApprove ? 'Approval notes...' : 'Reason for rejection...'}
            />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button
              type="submit"
              disabled={loading}
              className={`flex-1 justify-center ${isApprove ? 'btn-primary' : 'btn-danger'}`}
            >
              {loading ? <LoadingSpinner size="sm" /> : (isApprove ? 'Approve' : 'Reject')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Request Card ─────────────────────────────────────────────────────────────
function RequestCard({ req, onReview }) {
  const changes = req.requested_changes || {}
  const originals = req.original_values || {}
  const isPending = req.status === 'pending'

  return (
    <div className="card">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-2 flex-wrap mb-1">
            <span className="font-semibold text-navy dark:text-white text-sm">{req.user?.name}</span>
            <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full ${
              req.status === 'pending' ? 'bg-amber-100 text-amber-700 dark:bg-amber-500/20 dark:text-amber-400' :
              req.status === 'approved' ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' :
              'bg-red-100 text-red-700 dark:bg-red-500/20 dark:text-red-400'
            }`}>
              {req.status?.charAt(0).toUpperCase() + req.status?.slice(1)}
            </span>
            <span className="text-[10px] text-gray-400 uppercase font-medium px-1.5 py-0.5 rounded bg-gray-100 dark:bg-white/10">
              {req.entry_type || (req.requestable_type?.includes('Cash') ? 'cash' : 'card')}
            </span>
          </div>
          <p className="text-xs text-gray-500 dark:text-gray-400">{req.showroom?.name} · {formatDate(req.created_at)}</p>
          {req.reason && <p className="text-xs text-gray-600 dark:text-gray-300 mt-1 italic">"{req.reason}"</p>}

          {/* Changes */}
          <div className="mt-2 grid grid-cols-2 gap-2 text-xs">
            {Object.entries(changes).map(([key, newVal]) => (
              <div key={key} className="bg-gray-50 dark:bg-white/5 rounded-lg px-3 py-2">
                <p className="text-gray-400 capitalize">{key.replace(/_/g, ' ')}</p>
                <p className="text-gray-500 dark:text-gray-400 line-through">{originals[key] !== undefined ? formatCurrency(originals[key]) : '—'}</p>
                <p className="font-medium text-navy dark:text-white">{formatCurrency(newVal)}</p>
              </div>
            ))}
          </div>

          {req.reviewer_notes && (
            <p className="mt-2 text-xs text-gray-500 italic">Note: {req.reviewer_notes}</p>
          )}
        </div>

        {isPending && (
          <div className="flex flex-col gap-2 flex-shrink-0">
            <button
              onClick={() => onReview(req, 'approve')}
              className="p-2 rounded-lg bg-green-50 dark:bg-green-500/20 text-green-600 dark:text-green-400 hover:bg-green-100 dark:hover:bg-green-500/30 transition-colors"
              title="Approve"
            >
              <MdCheck className="w-5 h-5" />
            </button>
            <button
              onClick={() => onReview(req, 'reject')}
              className="p-2 rounded-lg bg-red-50 dark:bg-red-500/20 text-red-600 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/30 transition-colors"
              title="Reject"
            >
              <MdClose className="w-5 h-5" />
            </button>
          </div>
        )}
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function EditRequestsAdminPage() {
  const [activeTab, setActiveTab] = useState('pending')
  const [page, setPage] = useState(1)
  const [reviewModal, setReviewModal] = useState(null) // { request, action }

  const params = useMemo(() => {
    const p = { page, per_page: 20 }
    if (activeTab) p.status = activeTab
    return p
  }, [page, activeTab])

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.ADMIN_EDIT_REQUESTS, params, [JSON.stringify(params)])

  const requests = data?.data || []
  const meta = data?.meta || {}
  const totalPages = meta.last_page || 1

  const handleTabChange = (tab) => {
    setActiveTab(tab)
    setPage(1)
  }

  const pendingCount = activeTab === 'pending' ? meta.total : undefined

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Edit Requests"
        action={<button onClick={() => refetch()} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>}
      />

      {/* Tabs */}
      <div className="flex gap-1 bg-gray-100 dark:bg-white/5 rounded-xl p-1">
        {STATUS_TABS.map(tab => (
          <button
            key={tab.value}
            onClick={() => handleTabChange(tab.value)}
            className={`flex-1 py-2 px-3 rounded-lg text-sm font-medium transition-all ${
              activeTab === tab.value
                ? 'bg-white dark:bg-navy shadow text-navy dark:text-white'
                : 'text-gray-500 dark:text-gray-400 hover:text-navy dark:hover:text-white'
            }`}
          >
            {tab.label}
            {tab.value === 'pending' && pendingCount > 0 && (
              <span className="ml-1.5 bg-red-500 text-white text-[9px] font-bold rounded-full px-1 py-px">{pendingCount}</span>
            )}
          </button>
        ))}
      </div>

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && requests.length === 0 ? (
        <div className="space-y-3">{[1,2,3].map(i => <div key={i} className="card animate-pulse h-24 bg-gray-100 dark:bg-white/5" />)}</div>
      ) : requests.length === 0 ? (
        <EmptyState title={`No ${activeTab || ''} requests`} />
      ) : (
        <div className="space-y-3">
          {requests.map(req => (
            <RequestCard key={req.id} req={req} onReview={(r, action) => setReviewModal({ request: r, action })} />
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

      <ReviewModal
        open={!!reviewModal}
        request={reviewModal?.request}
        action={reviewModal?.action}
        onClose={() => setReviewModal(null)}
        onSaved={() => { setReviewModal(null); refetch() }}
      />
    </div>
  )
}
