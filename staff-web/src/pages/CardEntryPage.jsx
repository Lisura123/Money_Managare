import { useCallback } from 'react'
import { MdEditNote, MdLock } from 'react-icons/md'
import { Link, useNavigate } from 'react-router-dom'
import AmountDisplay from '../components/common/AmountDisplay'
import Card from '../components/common/Card'
import DateDisplay from '../components/common/DateDisplay'
import ErrorState from '../components/common/ErrorState'
import CardEntryForm from '../components/entries/CardEntryForm'
import LoadingSpinner from '../components/common/LoadingSpinner'
import PageHeader from '../components/common/PageHeader'
import { useFetch } from '../hooks/useFetch'
import { useEditWindow } from '../hooks/useEditWindow'
import { ENDPOINTS } from '../utils/constants'
import { formatTime12h, maskCard, todayString } from '../utils/formatters'

export default function CardEntryPage() {
  const navigate = useNavigate()

  const {
    data: cardAccountsData,
    loading: accountsLoading,
    error: accountsError,
    refetch: refetchAccounts,
  } = useFetch(ENDPOINTS.MY_CARD_ACCOUNTS)

  const { data: todayHistory, loading: todayLoading, refetch: refetchToday } = useFetch(
    ENDPOINTS.CARD_ENTRIES_HISTORY,
    { from: todayString(), to: todayString(), per_page: 10 },
  )

  const handleSuccess = useCallback(() => {
    refetchToday()
    refetchAccounts()
    navigate('/dashboard')
  }, [refetchToday, refetchAccounts, navigate])

  const cardAccounts = (cardAccountsData?.data || cardAccountsData || []).filter(
    (c) => c.is_active,
  )
  const todayEntries = todayHistory?.data || []

  const { isOpen, windowStart, windowEnd, bankEntriesEnabled, loading: windowLoading } = useEditWindow()

  return (
    <div className="max-w-5xl mx-auto grid grid-cols-1 lg:grid-cols-5 gap-6 animate-fade-in">
      {/* Left column: form */}
      <div className="lg:col-span-3">
        <PageHeader
          title="New Bank Entry"
          subtitle="Submit a card transaction for your showroom."
        />

        {!windowLoading && !bankEntriesEnabled ? (
          <Card>
            <div className="flex flex-col items-center justify-center py-10 text-center">
              <div className="w-14 h-14 rounded-full bg-gray-100 dark:bg-white/10 flex items-center justify-center mb-4">
                <MdLock className="w-7 h-7 text-gray-400 dark:text-gray-500" />
              </div>
              <h3 className="font-heading font-semibold text-gray-800 dark:text-gray-200 text-base mb-1">
                Bank Entries Disabled
              </h3>
              <p className="text-sm text-gray-500 dark:text-gray-400 max-w-xs">
                Bank entry submission has been disabled by the administrator.
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
        ) : accountsLoading ? (
          <div className="flex justify-center py-12">
            <LoadingSpinner />
          </div>
        ) : accountsError ? (
          <ErrorState message={accountsError} onRetry={refetchAccounts} />
        ) : (
          <Card>
            <CardEntryForm
              cardAccounts={cardAccounts}
              onSuccess={handleSuccess}
            />
          </Card>
        )}
      </div>

      {/* Right column: today's card entries */}
      <div className="lg:col-span-2">
        <div className="font-heading font-semibold text-gray-700 dark:text-gray-300 text-sm uppercase tracking-wide mb-3">
          Today's Bank Entries
        </div>

        {todayLoading ? (
          <div className="flex justify-center py-8">
            <LoadingSpinner />
          </div>
        ) : todayEntries.length === 0 ? (
          <Card>
            <p className="text-sm text-gray-500 dark:text-gray-400 text-center py-4">
              No bank entries submitted yet today.
            </p>
          </Card>
        ) : (
          <div className="space-y-3">
            {todayEntries.map((entry) => (
              <Card key={entry.id} className="!p-4">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <AmountDisplay amount={entry.amount} size="lg" />
                    {entry.card_account && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5 font-mono">
                        {entry.card_account.bank_name}{' '}
                        {maskCard(entry.card_account.last_four)}
                      </p>
                    )}
                    <DateDisplay date={entry.entry_date} className="mt-0.5 text-xs" />
                    {entry.notes && (
                      <p className="text-xs text-gray-500 dark:text-gray-400 mt-1 line-clamp-2">
                        {entry.notes}
                      </p>
                    )}
                  </div>
                  {!entry.is_locked && (
                    <Link
                      to={`/edit-request/card/${entry.id}`}
                      className="btn-outline text-xs py-1.5 flex-shrink-0"
                    >
                      <MdEditNote className="w-4 h-4" />
                      Edit
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
