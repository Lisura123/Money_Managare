import { useCallback, useEffect, useState } from 'react'
import { MdRefresh, MdEditNote, MdExpandMore, MdStorefront, MdStar, MdAttachMoney, MdCreditCard, MdPerson } from 'react-icons/md'
import { useFetch } from '../../hooks/useFetch'
import { useAuth } from '../../hooks/useAuth'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, getGreeting } from '../../utils/formatters'
import { prioritizeShowrooms, isFlagshipShowroom } from '../../utils/showroomPriority'
import { Link } from 'react-router-dom'

const POLL = 60_000

// Live summary card (matches iOS SummaryCard — cumulative balances)
function SummaryCard({ title, value, icon: Icon, colorClass, bgClass }) {
  return (
    <div className="card flex flex-col gap-3">
      <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${bgClass}`}>
        <Icon className={`w-4 h-4 ${colorClass}`} />
      </div>
      <div>
        <p className="text-xs text-gray-500 dark:text-gray-400">{title}</p>
        <p className={`text-lg font-heading font-bold leading-tight ${colorClass}`}>
          {formatCurrency(value)}
        </p>
      </div>
    </div>
  )
}

// Expandable per-showroom card (matches iOS ShowroomSnapshotCard — live balances)
function ShowroomCard({ name, isMain, liveCash, cards }) {
  const [expanded, setExpanded] = useState(false)
  const liveBank = cards.reduce((s, a) => s + (parseFloat(a.current_balance) || 0), 0)

  return (
    <div className={`card !p-0 overflow-hidden ${isMain ? 'ring-1 ring-amber-400/50' : ''}`}>
      <button
        onClick={() => setExpanded((v) => !v)}
        className="w-full flex items-center gap-3 px-4 py-3 text-left"
      >
        <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${
          isMain ? 'bg-amber-100 dark:bg-amber-500/20' : 'bg-navy/10 dark:bg-white/10'
        }`}>
          {isMain
            ? <MdStar className="w-4 h-4 text-amber-500" />
            : <MdStorefront className="w-4 h-4 text-navy dark:text-white" />}
        </div>
        <div className="min-w-0 flex-1">
          <p className={`text-sm truncate ${isMain ? 'font-bold' : 'font-semibold'} text-navy dark:text-white`}>{name}</p>
          {isMain && <p className="text-[11px] font-medium text-amber-500">Main showroom</p>}
        </div>
        <div className="text-right flex-shrink-0">
          <p className="text-[13px] font-bold text-teal flex items-center gap-1 justify-end">
            <MdAttachMoney className="w-3 h-3" />{formatCurrency(liveCash)}
          </p>
          <p className="text-[13px] font-bold text-[#6366F1] flex items-center gap-1 justify-end">
            <MdCreditCard className="w-3 h-3" />{formatCurrency(liveBank)}
          </p>
        </div>
        <MdExpandMore className={`w-5 h-5 text-gray-400 flex-shrink-0 transition-transform ${expanded ? 'rotate-180' : ''}`} />
      </button>

      {expanded && (
        <div className="border-t border-gray-100 dark:border-white/10 px-4 py-3 space-y-2">
          <div className="flex items-center justify-between text-xs">
            <span className="text-gray-500 dark:text-gray-400">Total Main Cash Amount</span>
            <span className="font-semibold text-teal">{formatCurrency(liveCash)}</span>
          </div>
          <div className="flex items-center justify-between text-xs">
            <span className="text-gray-500 dark:text-gray-400">Total Bank Amount</span>
            <span className="font-semibold text-[#6366F1]">{formatCurrency(liveBank)}</span>
          </div>
          {cards.length > 0 && (
            <div className="pt-2 mt-1 border-t border-gray-100 dark:border-white/10 space-y-1.5">
              {cards.map((acc) => (
                <div key={acc.id} className="flex items-center justify-between text-[11px]">
                  <span className="text-gray-500 dark:text-gray-400 truncate">
                    {acc.bank_name || 'Unknown'} •••• {acc.last_four}
                  </span>
                  <span className={`font-medium ${parseFloat(acc.current_balance) < 0 ? 'text-error' : 'text-navy dark:text-white'}`}>
                    {formatCurrency(parseFloat(acc.current_balance) || 0)}
                  </span>
                </div>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  )
}

export default function AdminDashboardPage() {
  const { user } = useAuth()

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.ADMIN_DASHBOARD_SUMMARY)
  const { data: pendingData, refetch: refetchPending } = useFetch(ENDPOINTS.ADMIN_EDIT_REQUESTS_PENDING_COUNT)
  const { data: cardAccountsRaw, refetch: refetchCards } = useFetch(ENDPOINTS.CARD_ACCOUNTS)
  const { data: extAccountsRaw, refetch: refetchExt } = useFetch(ENDPOINTS.EXTERNAL_ACCOUNTS)
  const { data: showroomCashRaw, refetch: refetchCash } = useFetch(ENDPOINTS.SHOWROOM_CASH_BALANCES)

  useEffect(() => {
    const t = setInterval(() => {
      refetch(true); refetchPending(true); refetchCards(true); refetchExt(true); refetchCash(true)
    }, POLL)
    return () => clearInterval(t)
  }, [refetch, refetchPending, refetchCards, refetchExt, refetchCash])

  const handleRefresh = useCallback(() => {
    refetch(); refetchPending(); refetchCards(); refetchExt(); refetchCash()
  }, [refetch, refetchPending, refetchCards, refetchExt, refetchCash])

  const pendingCount = pendingData?.count ?? 0

  const cardAccounts = Array.isArray(cardAccountsRaw) ? cardAccountsRaw : (cardAccountsRaw?.data || [])
  const extAccounts = Array.isArray(extAccountsRaw) ? extAccountsRaw : (extAccountsRaw?.data || [])
  const showroomCash = Array.isArray(showroomCashRaw) ? showroomCashRaw : (showroomCashRaw?.data || [])

  // Live cumulative totals (match iOS top summary cards)
  const liveTotalCash = showroomCash.reduce((s, sr) => s + (parseFloat(sr.balance) || 0), 0)
  const liveTotalBank = cardAccounts.reduce((s, a) => s + (parseFloat(a.current_balance) || 0), 0)
  const liveTotalMano = extAccounts
    .filter((a) => a.cash_account_type === 'mano')
    .reduce((s, a) => s + (parseFloat(a.balance) || 0), 0)

  // Per-showroom live breakdown (flagship first)
  const orderedShowrooms = prioritizeShowrooms(showroomCash, 'showroom_name')

  // Last updated display
  const lastUpdated = data?.last_updated_at
    ? (() => {
        const d = new Date(data.last_updated_at)
        return isNaN(d) ? data.last_updated_at : d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      })()
    : null

  return (
    <div className="space-y-5 animate-fade-in">
      {/* Header */}
      <div className="flex items-start justify-between gap-4">
        <div>
          <h1 className="font-heading font-bold text-xl text-navy dark:text-white">
            {getGreeting()}, {user?.name?.split(' ')[0]}!
          </h1>
          <p className="text-sm text-gray-500 dark:text-gray-400 mt-0.5">
            Admin Dashboard
            {data?.server_date && (
              <span className="ml-2 inline-block bg-teal/10 text-teal text-xs px-2 py-0.5 rounded-full font-medium">
                {data.server_date}
              </span>
            )}
          </p>
        </div>
        <button onClick={handleRefresh} className="btn-outline p-2" title="Refresh">
          <MdRefresh className={`w-5 h-5 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* Pending requests banner */}
      {pendingCount > 0 && (
        <div className="bg-amber-50 dark:bg-amber-500/10 border border-amber-200 dark:border-amber-500/30 rounded-xl px-4 py-3 flex items-center justify-between gap-4">
          <div className="flex items-center gap-2">
            <MdEditNote className="w-5 h-5 text-amber-600 dark:text-amber-400 flex-shrink-0" />
            <p className="text-sm text-amber-700 dark:text-amber-300 font-medium">
              {pendingCount} pending edit {pendingCount === 1 ? 'request' : 'requests'} awaiting review
            </p>
          </div>
          <Link to="/admin/edit-requests" className="text-xs text-amber-700 dark:text-amber-300 font-semibold hover:underline flex-shrink-0">
            Review →
          </Link>
        </div>
      )}

      {error && (
        <div className="bg-red-50 dark:bg-red-500/10 border border-red-200 dark:border-red-500/30 rounded-xl px-4 py-3 text-sm text-error">
          {error}
        </div>
      )}

      {/* Today date + last updated row */}
      {(data?.server_date || lastUpdated) && (
        <div className="flex items-center justify-between">
          <div>
            <p className="text-xs text-gray-400 dark:text-gray-500">Today</p>
            <p className="text-base font-bold text-navy dark:text-white">{data?.server_date}</p>
          </div>
          {lastUpdated && (
            <p className="text-xs text-gray-400 dark:text-gray-500 text-right">
              Last updated {lastUpdated}
            </p>
          )}
        </div>
      )}

      {/* Live summary cards (match iOS) */}
      <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
        <SummaryCard
          title="Total Cash Amount"
          value={liveTotalCash}
          icon={MdAttachMoney}
          colorClass="text-teal"
          bgClass="bg-teal/10"
        />
        <SummaryCard
          title="Total Mano's Amount"
          value={liveTotalMano}
          icon={MdPerson}
          colorClass="text-accent"
          bgClass="bg-accent/10"
        />
        <SummaryCard
          title="Total Bank Amount"
          value={liveTotalBank}
          icon={MdCreditCard}
          colorClass="text-[#6366F1]"
          bgClass="bg-[#6366F1]/10"
        />
      </div>

      {/* Per-showroom live breakdown */}
      {orderedShowrooms.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Per Showroom
          </p>
          {orderedShowrooms.map((sr) => (
            <ShowroomCard
              key={sr.showroom_id}
              name={sr.showroom_name}
              isMain={isFlagshipShowroom(sr.showroom_name)}
              liveCash={parseFloat(sr.balance) || 0}
              cards={cardAccounts.filter((a) => a.showroom_id === sr.showroom_id)}
            />
          ))}
        </div>
      )}
    </div>
  )
}
