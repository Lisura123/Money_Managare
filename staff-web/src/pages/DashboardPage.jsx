import { useEffect, useCallback } from 'react'
import { MdCreditCard, MdEditNote, MdLock, MdRefresh, MdWallet } from 'react-icons/md'
import { Link } from 'react-router-dom'
import StatusCard from '../components/dashboard/StatusCard'
import QuickActionCard from '../components/dashboard/QuickActionCard'
import RecentEntries from '../components/dashboard/RecentEntries'
import Card from '../components/common/Card'
import { useFetch } from '../hooks/useFetch'
import { useEditWindow } from '../hooks/useEditWindow'
import { useAuth } from '../hooks/useAuth'
import { ENDPOINTS } from '../utils/constants'
import { formatTime12h, getGreeting, getTodayLabel } from '../utils/formatters'

// Poll interval: 60 seconds
const POLL_INTERVAL = 60_000

export default function DashboardPage() {
  const { user } = useAuth()

  const {
    data: statusData,
    loading: statusLoading,
    refetch: refetchStatus,
  } = useFetch(ENDPOINTS.TODAY_STATUS)

  const {
    data: cashData,
    loading: cashLoading,
    refetch: refetchCash,
  } = useFetch(ENDPOINTS.CASH_ENTRIES_HISTORY, { per_page: 10 })

  const {
    data: cardData,
    loading: cardLoading,
    refetch: refetchCard,
  } = useFetch(ENDPOINTS.CARD_ENTRIES_HISTORY, { per_page: 10 })

  const {
    data: editRequestsData,
  } = useFetch(ENDPOINTS.MY_EDIT_REQUESTS, { status: 'pending' })

  // Silent background polling every 60s
  useEffect(() => {
    const interval = setInterval(() => {
      refetchStatus(true)
      refetchCash(true)
      refetchCard(true)
    }, POLL_INTERVAL)
    return () => clearInterval(interval)
  }, [refetchStatus, refetchCash, refetchCard])

  const handleRefresh = useCallback(() => {
    refetchStatus()
    refetchCash()
    refetchCard()
  }, [refetchStatus, refetchCash, refetchCard])

  const cashEntries = cashData?.data || []
  const cardEntries = cardData?.data || []
  const status = statusData

  const pendingRequests = editRequestsData?.data?.filter((r) => r.status === 'pending') || []

  const { isOpen, windowStart, windowEnd } = useEditWindow()

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="font-heading font-bold text-xl text-navy dark:text-white">
            {getGreeting()}, {user?.name?.split(' ')[0]}!
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">
            {getTodayLabel()}
            {user?.showroom && (
              <span className="ml-2 inline-block bg-teal/10 text-teal text-xs px-2 py-0.5 rounded-full font-medium">
                {user.showroom.name}
              </span>
            )}
          </p>
        </div>
        <button
          onClick={handleRefresh}
          className="btn-outline p-2"
          title="Refresh"
          aria-label="Refresh dashboard"
        >
          <MdRefresh className="w-5 h-5" />
        </button>
      </div>

      {/* Pending edit request notice */}
      {pendingRequests.length > 0 && (
        <div className="bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/30 rounded-xl px-4 py-3 flex items-center justify-between gap-4">
          <p className="text-sm text-amber-700 dark:text-amber-300 font-medium">
            You have {pendingRequests.length} pending edit{' '}
            {pendingRequests.length === 1 ? 'request' : 'requests'}
          </p>
          <Link
            to="/edit-requests"
            className="text-xs text-amber-700 dark:text-amber-300 font-semibold hover:underline flex-shrink-0"
          >
            View →
          </Link>
        </div>
      )}

      {/* Edit window notice */}
      {!isOpen && windowStart && (
        <div className="bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 flex items-center gap-3">
          <MdLock className="w-5 h-5 text-gray-400 flex-shrink-0" />
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Entry submission is closed. The edit window is open from{' '}
            <span className="font-semibold text-gray-700 dark:text-gray-300">{formatTime12h(windowStart)}</span>
            {' '}to{' '}
            <span className="font-semibold text-gray-700 dark:text-gray-300">{formatTime12h(windowEnd)}</span>.
          </p>
        </div>
      )}

      {/* Today's Status Section */}
      <div>
        <h2 className="font-heading font-semibold text-gray-800 dark:text-gray-200 text-sm uppercase tracking-wide mb-3">
          Today's Status
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <StatusCard
            label="Main Account"
            submitted={status?.main_cash?.submitted}
            amount={status?.main_cash?.amount}
            accent="teal"
            actionTo="/cash-entry/main"
          />
          <StatusCard
            label="Mano's Account"
            submitted={status?.mano_cash?.submitted}
            amount={status?.mano_cash?.amount}
            accent="purple"
            actionTo="/cash-entry/mano"
          />
          <StatusCard
            label="Card Entries"
            submitted={(status?.card?.count || 0) > 0}
            amount={status?.card?.total}
            count={status?.card?.count}
            accent="navy"
            actionTo="/card-entry"
          />
        </div>
      </div>

      {/* Quick Actions */}
      <div>
        <h2 className="font-heading font-semibold text-gray-800 dark:text-gray-200 text-sm uppercase tracking-wide mb-3">
          Quick Actions
        </h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <QuickActionCard
            icon={MdWallet}
            label="Main Account Entry"
            gradient="bg-gradient-to-br from-teal to-teal-hover"
            to="/cash-entry/main"
            done={status?.main_cash?.submitted}
            disabled={!isOpen}
          />
          <QuickActionCard
            icon={MdWallet}
            label="Mano's Account Entry"
            gradient="bg-gradient-to-br from-purple-500 to-purple-700"
            to="/cash-entry/mano"
            done={status?.mano_cash?.submitted}
            disabled={!isOpen}
          />
          <QuickActionCard
            icon={MdCreditCard}
            label="Card Entry"
            gradient="bg-gradient-to-br from-navy to-navy-light"
            to="/card-entry"
            done={(status?.card?.count || 0) > 0}
            disabled={!isOpen}
          />
        </div>
      </div>

      {/* Recent Entries */}
      <Card padding={false}>
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 dark:border-white/10">
          <h2 className="font-heading font-semibold text-gray-800 dark:text-white text-sm uppercase tracking-wide">
            Recent Entries
          </h2>
          <Link
            to="/history"
            className="text-xs text-teal hover:underline font-medium"
          >
            View all →
          </Link>
        </div>
        <div className="p-1">
          <RecentEntries
            cashEntries={cashEntries}
            cardEntries={cardEntries.map((e) => ({ ...e, _type: 'card' }))}
            loading={cashLoading || cardLoading}
          />
        </div>
      </Card>

      {/* Edit Requests quick link */}
      <Card>
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-navy/5 dark:bg-white/10 flex items-center justify-center">
              <MdEditNote className="w-5 h-5 text-navy dark:text-teal" />
            </div>
            <div>
              <p className="font-medium text-gray-800 dark:text-gray-200 text-sm">
                My Edit Requests
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400">
                Request corrections to past entries
              </p>
            </div>
          </div>
          <Link to="/edit-requests" className="btn-outline text-sm py-2">
            View
          </Link>
        </div>
      </Card>
    </div>
  )
}
