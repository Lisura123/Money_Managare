import { useEffect, useCallback } from 'react'
import { MdCreditCard, MdLock, MdRefresh, MdWallet } from 'react-icons/md'
import { Link } from 'react-router-dom'
import Card from '../components/common/Card'
import { useFetch } from '../hooks/useFetch'
import { useEditWindow } from '../hooks/useEditWindow'
import { useAuth } from '../hooks/useAuth'
import { ENDPOINTS } from '../utils/constants'
import { formatCurrency, formatTime12h, getGreeting } from '../utils/formatters'

const POLL_INTERVAL = 60_000

// ─── Avatar ────────────────────────────────────────────────────────────────────
function Avatar({ name }) {
  const initials = name?.split(' ').slice(0, 2).map(n => n[0]).join('').toUpperCase() || '?'
  return (
    <div className="w-12 h-12 rounded-full bg-navy dark:bg-teal/90 flex items-center justify-center flex-shrink-0">
      <span className="text-sm font-bold text-white dark:text-navy">{initials}</span>
    </div>
  )
}

// ─── Status Pill ───────────────────────────────────────────────────────────────
function StatusPill({ label, submitted, amount }) {
  return (
    <div className={`rounded-xl p-3 ${
      submitted
        ? 'bg-green-50 dark:bg-green-500/10 border border-green-200 dark:border-green-500/20'
        : 'bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/20'
    }`}>
      <p className="text-[10px] text-gray-500 dark:text-gray-400 font-medium mb-1">{label}</p>
      {submitted ? (
        <p className="text-sm font-bold text-green-600 dark:text-green-400">{formatCurrency(amount)}</p>
      ) : (
        <p className="text-xs font-medium text-red-500 dark:text-red-400">Not submitted</p>
      )}
    </div>
  )
}

// ─── Today Status Card ─────────────────────────────────────────────────────────
function TodayStatusCard({ status }) {
  const today = new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric' })
  return (
    <Card>
      <p className="text-xs font-medium text-gray-500 dark:text-gray-400 mb-3">Today — {today}</p>
      <div className="grid grid-cols-2 gap-3 mb-3">
        <StatusPill
          label="Main Cash"
          submitted={status?.main_cash?.submitted}
          amount={status?.main_cash?.amount}
        />
        <StatusPill
          label="Mano Cash"
          submitted={status?.mano_cash?.submitted}
          amount={status?.mano_cash?.amount}
        />
      </div>
      {(status?.card?.count || 0) > 0 ? (
        <div className="flex items-center justify-between pt-1">
          <p className="text-xs text-gray-500 dark:text-gray-400">
            Card Entries ({status.card.count})
          </p>
          <p className="text-sm font-bold text-navy dark:text-white">
            {formatCurrency(status.card.total)}
          </p>
        </div>
      ) : (
        <p className="text-xs text-gray-400 dark:text-gray-500 pt-1">No card entries today</p>
      )}
    </Card>
  )
}

// ─── Action Button ─────────────────────────────────────────────────────────────
function ActionButton({ icon: Icon, label, accent, to }) {
  return (
    <Link
      to={to}
      className="card flex flex-col items-center justify-center py-5 gap-2.5 hover:bg-gray-50 dark:hover:bg-white/5 active:scale-[0.98] transition-all"
    >
      <Icon className={`w-8 h-8 ${accent}`} />
      <p className="text-sm font-medium text-navy dark:text-white">{label}</p>
    </Link>
  )
}

export default function DashboardPage() {
  const { user } = useAuth()

  const { data: statusData, loading: statusLoading, refetch: refetchStatus } = useFetch(ENDPOINTS.TODAY_STATUS)
  const { data: editRequestsData } = useFetch(ENDPOINTS.MY_EDIT_REQUESTS, { status: 'pending' })
  const { isOpen, windowStart, windowEnd } = useEditWindow()

  useEffect(() => {
    const interval = setInterval(() => refetchStatus(true), POLL_INTERVAL)
    return () => clearInterval(interval)
  }, [refetchStatus])

  const handleRefresh = useCallback(() => refetchStatus(), [refetchStatus])

  const pendingRequests = editRequestsData?.data?.filter(r => r.status === 'pending') || []

  return (
    <div className="space-y-4 animate-fade-in">
      {/* Greeting card */}
      <div className="card flex items-center justify-between gap-4">
        <div>
          <p className="text-sm text-gray-500 dark:text-gray-400">{getGreeting()}!</p>
          <p className="text-xl font-heading font-bold text-navy dark:text-white mt-0.5">{user?.name}</p>
          {user?.showroom?.name && (
            <span className="inline-block mt-1.5 text-xs bg-teal/10 text-teal px-2 py-0.5 rounded-full font-medium">
              {user.showroom.name}
            </span>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={handleRefresh}
            className="p-2 rounded-lg text-gray-400 hover:text-navy dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/10 transition-colors"
            aria-label="Refresh"
          >
            <MdRefresh className={`w-5 h-5 ${statusLoading ? 'animate-spin' : ''}`} />
          </button>
          <Avatar name={user?.name} />
        </div>
      </div>

      {/* Pending edit requests banner */}
      {pendingRequests.length > 0 && (
        <div className="bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/30 rounded-xl px-4 py-3 flex items-center justify-between gap-4">
          <p className="text-sm text-amber-700 dark:text-amber-300 font-medium">
            {pendingRequests.length} edit {pendingRequests.length === 1 ? 'request' : 'requests'} pending review
          </p>
          <Link to="/edit-requests" className="text-xs text-amber-700 dark:text-amber-300 font-semibold hover:underline flex-shrink-0">
            View →
          </Link>
        </div>
      )}

      {/* Edit window notice */}
      {!isOpen && windowStart && (
        <div className="bg-gray-50 dark:bg-white/5 border border-gray-200 dark:border-white/10 rounded-xl px-4 py-3 flex items-center gap-3">
          <MdLock className="w-4 h-4 text-gray-400 flex-shrink-0" />
          <p className="text-xs text-gray-500 dark:text-gray-400">
            Entry window closed — open {formatTime12h(windowStart)} to {formatTime12h(windowEnd)}
          </p>
        </div>
      )}

      {/* Today's Status */}
      <TodayStatusCard status={statusData} />

      {/* Quick Entry */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2">Quick Entry</p>
        <div className="grid grid-cols-2 gap-3">
          <ActionButton icon={MdWallet} label="Cash Entry" accent="text-teal" to="/cash-entry/main" />
          <ActionButton icon={MdCreditCard} label="Card Entry" accent="text-navy dark:text-white" to="/card-entry" />
        </div>
      </div>
    </div>
  )
}


