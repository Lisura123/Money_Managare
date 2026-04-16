import { formatCurrency, formatDateShort } from '../../utils/formatters'
import StatusBadge from '../common/StatusBadge'
import EditRequestCard from './EditRequestCard'

export default function EditRequestTimeline({ requests = [], onCancelled }) {
  if (requests.length === 0) return null

  return (
    <div className="relative">
      {/* Timeline line */}
      <div className="absolute left-5 top-0 bottom-0 w-0.5 bg-gray-200 dark:bg-white/10" />

      <div className="space-y-6">
        {requests.map((request) => {
          const dotColor =
            request.status === 'pending'
              ? 'bg-warning'
              : request.status === 'approved'
                ? 'bg-success'
                : 'bg-error'

          return (
            <div key={request.id} className="relative flex gap-4">
              {/* Timeline dot */}
              <div
                className={`flex-shrink-0 w-10 h-10 rounded-full ${dotColor} flex items-center justify-center z-10 shadow-sm`}
              >
                <span className="text-white text-xs font-bold">
                  {request.entry_type === 'cash' ? '₹' : '💳'}
                </span>
              </div>

              {/* Content — desktop: inline summary; mobile: card */}
              <div className="flex-1 min-w-0 pt-1.5">
                {/* Desktop timeline row */}
                <div className="hidden lg:block">
                  <div className="flex items-center flex-wrap gap-2 mb-1">
                    <StatusBadge status={request.entry_type} />
                    <StatusBadge status={request.status} />
                    <span className="text-xs text-gray-500 dark:text-gray-400">
                      {formatDateShort(request.created_at)}
                    </span>
                  </div>
                  <p className="text-sm text-gray-700 dark:text-gray-300">
                    <span className="font-medium">{formatCurrency(
                      request.original_values?.cash_amount ??
                      request.original_values?.amount
                    )}</span>
                    {' → '}
                    <span className="font-medium">{formatCurrency(
                      request.requested_changes?.cash_amount ??
                      request.requested_changes?.amount
                    )}</span>
                  </p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 truncate max-w-md">
                    {request.reason}
                  </p>
                  {request.admin_remarks && (
                    <blockquote className="mt-2 border-l-2 border-gray-300 dark:border-gray-600 pl-3 text-xs text-gray-600 dark:text-gray-400 italic">
                      "{request.admin_remarks}"
                    </blockquote>
                  )}
                </div>

                {/* Mobile / tablet card */}
                <div className="lg:hidden">
                  <EditRequestCard request={request} onCancelled={onCancelled} />
                </div>
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
