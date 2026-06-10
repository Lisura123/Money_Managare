import { useCallback } from 'react'
import { useNavigate, useParams } from 'react-router-dom'
import CashEntryForm from '../components/entries/CashEntryForm'
import Card from '../components/common/Card'
import PageHeader from '../components/common/PageHeader'
import AmountDisplay from '../components/common/AmountDisplay'
import DateDisplay from '../components/common/DateDisplay'
import LoadingSpinner from '../components/common/LoadingSpinner'
import ErrorState from '../components/common/ErrorState'
import { useFetch } from '../hooks/useFetch'
import { useEditWindow } from '../hooks/useEditWindow'
import { ACCOUNT_TYPE_LABELS, ENDPOINTS } from '../utils/constants'
import { formatTime12h, todayString } from '../utils/formatters'
import { Link } from 'react-router-dom'
import { MdEditNote, MdLock } from 'react-icons/md'

export default function CashEntryPage() {
  const { accountType } = useParams() // 'main' | 'mano'
  const navigate = useNavigate()

  const accountLabel = ACCOUNT_TYPE_LABELS[accountType] || 'Account'

  const { isOpen, windowStart, windowEnd, cashEntriesEnabled, loading: windowLoading } = useEditWindow()

  // Fetch today's entries for this account to show as reference
  const { data: todayHistory, loading: todayLoading, error: todayError, refetch: refetchToday } = useFetch(
    ENDPOINTS.CASH_ENTRIES_HISTORY,
    { cash_account_type: accountType, from: todayString(), to: todayString(), per_page: 5 },
    [accountType],
  )

  const todayEntries = todayHistory?.data || []

  const handleSuccess = useCallback(() => {
    refetchToday()
    navigate('/dashboard')
  }, [refetchToday, navigate])

  return (
    <div className="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-5 gap-6 animate-fade-in">
      {/* Left column: form */}
      <div className="lg:col-span-3">
        <PageHeader
          title={`New Cash Entry — ${accountLabel}`}
          subtitle="Submit today's cash amount for your showroom."
        />
        {!windowLoading && !cashEntriesEnabled ? (
          <Card>
            <div className="flex flex-col items-center justify-center py-10 text-center">
              <div className="w-14 h-14 rounded-full bg-gray-100 dark:bg-white/10 flex items-center justify-center mb-4">
                <MdLock className="w-7 h-7 text-gray-400 dark:text-gray-500" />
              </div>
              <h3 className="font-heading font-semibold text-gray-800 dark:text-gray-200 text-base mb-1">
                Cash Entries Disabled
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400 max-w-xs">
                Cash entry submission has been disabled by the administrator.
              </p>
            </div>
          </Card>
        ) : !windowLoading && !isOpen ? (
          <Card>
            <div className="flex flex-col items-center justify-center py-10 text-center">
              <div className="w-14 h-14 rounded-full bg-gray-100 dark:bg-white/10 flex items-center justify-center mb-4">
                <MdLock className="w-7 h-7 text-gray-400 dark:text-gray-500" />
              </div>
              <h3 className="font-heading font-semibold text-gray-800 dark:text-gray-200 text-base mb-1">
                Entry Submission Closed
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400 max-w-xs">
                Entries can only be submitted between{' '}
                <span className="font-semibold text-gray-700 dark:text-gray-300">{formatTime12h(windowStart)}</span>
                {' '}and{' '}
                <span className="font-semibold text-gray-700 dark:text-gray-300">{formatTime12h(windowEnd)}</span>.
              </p>
            </div>
          </Card>
        ) : (
          <Card>
            <CashEntryForm accountType={accountType} onSuccess={handleSuccess} />
          </Card>
        )}
      </div>

      {/* Right column: reference */}
      <div className="lg:col-span-2">
        <div className="font-heading font-semibold text-gray-700 dark:text-gray-300 text-sm uppercase tracking-wide mb-3">
          Today's Entries — {accountLabel}
        </div>

        {todayLoading ? (
          <div className="flex justify-center py-8">
            <LoadingSpinner />
          </div>
        ) : todayError ? (
          <ErrorState message={todayError} />
        ) : todayEntries.length === 0 ? (
          <Card>
            <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-4">
              No entries submitted yet for today.
            </p>
          </Card>
        ) : (
          <div className="space-y-3">
            {todayEntries.map((entry) => (
              <Card key={entry.id} className="!p-4">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <AmountDisplay amount={entry.cash_amount} size="lg" />
                    <DateDisplay date={entry.entry_date} className="mt-0.5 text-xs" />
                    {entry.notes && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-2">
                        {entry.notes}
                      </p>
                    )}
                  </div>
                  {!entry.is_locked && (
                    <Link
                      to={`/edit-request/cash/${entry.id}`}
                      className="btn-outline text-xs py-1.5 flex-shrink-0"
                    >
                      <MdEditNote className="w-4 h-4" />
                      Edit Request
                    </Link>
                  )}
                </div>
              </Card>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
