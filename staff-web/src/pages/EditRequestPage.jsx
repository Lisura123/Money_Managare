import { useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import LoadingSpinner from '../components/common/LoadingSpinner'
import ErrorState from '../components/common/ErrorState'
import Card from '../components/common/Card'
import PageHeader from '../components/common/PageHeader'
import EditRequestForm from '../components/editRequests/EditRequestForm'
import StatusBadge from '../components/common/StatusBadge'
import AmountDisplay from '../components/common/AmountDisplay'
import { useFetch } from '../hooks/useFetch'
import { ENDPOINTS } from '../utils/constants'
import { formatDate } from '../utils/formatters'

export default function EditRequestPage() {
  const { entryType, entryId } = useParams()
  const navigate = useNavigate()

  const endpoint =
    entryType === 'cash'
      ? ENDPOINTS.CASH_ENTRIES_HISTORY
      : ENDPOINTS.CARD_ENTRIES_HISTORY

  // We need to find the specific entry — fetch history then find by id
  const { data, loading, error, refetch } = useFetch(endpoint, { per_page: 100 })

  const entries = data?.data || []
  const entry = entries.find((e) => String(e.id) === String(entryId))

  if (loading) {
    return (
      <div className="flex justify-center items-center py-20">
        <LoadingSpinner size="lg" />
      </div>
    )
  }

  if (error) {
    return <ErrorState message={error} onRetry={refetch} />
  }

  if (!entry) {
    return (
      <div className="max-w-2xl mx-auto py-12 text-center">
        <p className="text-gray-600 dark:text-gray-400 mb-4">
          Entry not found. It may have been deleted or you don't have access to it.
        </p>
        <button onClick={() => navigate(-1)} className="btn-outline">
          Go Back
        </button>
      </div>
    )
  }

  if (entry.is_locked) {
    return (
      <div className="max-w-2xl mx-auto">
        <PageHeader title="Edit Request" />
        <Card>
          <div className="text-center py-8">
            <p className="text-gray-600 dark:text-gray-400 text-lg mb-2">🔒 Entry is locked</p>
            <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
              This entry has been locked and cannot be edited via a request.
            </p>
            <button onClick={() => navigate(-1)} className="btn-outline">
              Go Back
            </button>
          </div>
        </Card>
      </div>
    )
  }

  const originalAmount =
    entryType === 'cash' ? entry.cash_amount : entry.amount

  return (
    <div className="max-w-2xl mx-auto space-y-6 animate-fade-in">
      <PageHeader
        title="Submit Edit Request"
        subtitle={`Request a correction to this ${entryType} entry.`}
      />

      {/* Entry summary */}
      <div className="bg-gray-50 dark:bg-white/5 rounded-xl border border-gray-200 dark:border-white/10 p-4">
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-3">
          Entry Summary
        </p>
        <div className="flex flex-wrap gap-2 mb-2">
          <StatusBadge status={entryType} />
          {entryType === 'cash' && (
            <StatusBadge
              status={entry.cash_account_type}
              label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
            />
          )}
        </div>
        <div className="flex items-center justify-between gap-4">
          <AmountDisplay amount={originalAmount} size="lg" />
          <span className="text-sm text-gray-500 dark:text-gray-400">
            {formatDate(entry.entry_date)}
          </span>
        </div>
      </div>

      <Card>
        <EditRequestForm entry={entry} entryType={entryType} />
      </Card>
    </div>
  )
}
