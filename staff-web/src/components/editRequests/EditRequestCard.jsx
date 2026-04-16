import { useState } from 'react'
import toast from 'react-hot-toast'
import { MdClose } from 'react-icons/md'
import api from '../../config/api'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, formatDateShort } from '../../utils/formatters'
import ConfirmDialog from '../common/ConfirmDialog'
import StatusBadge from '../common/StatusBadge'

export default function EditRequestCard({ request, onCancelled }) {
  const [showConfirm, setShowConfirm] = useState(false)
  const [cancelling, setCancelling] = useState(false)

  const handleCancel = async () => {
    setCancelling(true)
    try {
      await api.delete(`${ENDPOINTS.EDIT_REQUESTS}/${request.id}`)
      toast.success('Edit request cancelled.')
      onCancelled?.()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to cancel request.')
    } finally {
      setCancelling(false)
      setShowConfirm(false)
    }
  }

  const originalAmount =
    request.original_values?.cash_amount ??
    request.original_values?.amount ??
    null

  const requestedAmount =
    request.requested_changes?.cash_amount ??
    request.requested_changes?.amount ??
    null

  return (
    <>
      <div className="card border-l-4 border-l-transparent" style={{
        borderLeftColor: request.status === 'pending'
          ? '#FFC107'
          : request.status === 'approved'
            ? '#4CAF50'
            : '#EF5363',
      }}>
        <div className="flex items-start justify-between gap-3 mb-3">
          <div className="flex flex-wrap gap-2 items-center">
            <StatusBadge status={request.entry_type} />
            <StatusBadge status={request.status} />
          </div>
          {request.status === 'pending' && (
            <button
              onClick={() => setShowConfirm(true)}
              className="text-xs text-error hover:text-red-600 font-medium flex items-center gap-1 flex-shrink-0"
            >
              <MdClose className="w-3.5 h-3.5" />
              Cancel
            </button>
          )}
        </div>

        <div className="grid grid-cols-2 gap-3 text-sm mb-3">
          <div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">Original</p>
            <p className="font-semibold text-gray-800 dark:text-gray-200">
              {originalAmount !== null ? formatCurrency(originalAmount) : '—'}
            </p>
          </div>
          <div>
            <p className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">Requested</p>
            <p className="font-semibold text-gray-800 dark:text-gray-200">
              {requestedAmount !== null ? formatCurrency(requestedAmount) : '—'}
            </p>
          </div>
        </div>

        <div className="text-sm text-gray-600 dark:text-gray-400 mb-2">
          <span className="text-xs font-medium text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Reason:{' '}
          </span>
          {request.reason}
        </div>

        <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
          <span>Submitted {formatDateShort(request.created_at)}</span>
          {request.reviewed_at && (
            <span>Reviewed {formatDateShort(request.reviewed_at)}</span>
          )}
        </div>

        {request.admin_remarks && (
          <blockquote className="mt-3 border-l-2 border-gray-300 dark:border-gray-600 pl-3 text-sm text-gray-600 dark:text-gray-400 italic">
            "{request.admin_remarks}"
          </blockquote>
        )}
      </div>

      <ConfirmDialog
        open={showConfirm}
        title="Cancel edit request?"
        message="This will withdraw your edit request. This action cannot be undone."
        confirmLabel="Yes, cancel it"
        cancelLabel="Keep request"
        onConfirm={handleCancel}
        onCancel={() => setShowConfirm(false)}
        loading={cancelling}
        danger
      />
    </>
  )
}
