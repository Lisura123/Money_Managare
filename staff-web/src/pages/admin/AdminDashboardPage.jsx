import { useCallback, useEffect, useState } from 'react'
import { MdRefresh, MdEditNote, MdCreditCard, MdAccountBalance, MdStorefront, MdAttachMoney } from 'react-icons/md'
import Card from '../../components/common/Card'
import { useFetch } from '../../hooks/useFetch'
import { useAuth } from '../../hooks/useAuth'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, getGreeting } from '../../utils/formatters'
import { Link } from 'react-router-dom'

const POLL = 60_000

// iOS AdjustedStatCard equivalent
function StatCard({ label, adjValue, rawValue, colorClass }) {
  const different = Math.abs((adjValue ?? 0) - (rawValue ?? 0)) > 0.001
  return (
    <div className="card">
      <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mb-1 leading-tight">{label}</p>
      <p className={`text-xl font-heading font-bold leading-tight ${colorClass}`}>
        {formatCurrency(adjValue ?? rawValue ?? 0)}
      </p>
      {different && (
        <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">Raw: {formatCurrency(rawValue)}</p>
      )}
    </div>
  )
}

// iOS ShowroomSnapshotRow equivalent
function ShowroomRow({ snap }) {
  return (
    <div className="card">
      <div className="flex items-center justify-between mb-2">
        <p className="font-semibold text-navy dark:text-white text-sm">{snap.showroom_name}</p>
        <p className="text-xs text-gray-400">{snap.entry_count} {snap.entry_count === 1 ? 'entry' : 'entries'}</p>
      </div>
      <div className="flex gap-4 flex-wrap">
        <div>
          <p className="text-[10px] text-gray-400 dark:text-gray-500">Cash Main</p>
          <p className="text-sm font-medium text-navy dark:text-gray-200">{formatCurrency(snap.cash_main_adjusted ?? snap.cash_main_total)}</p>
        </div>
        <div>
          <p className="text-[10px] text-gray-400 dark:text-gray-500">Cash Mano</p>
          <p className="text-sm font-medium text-navy dark:text-gray-200">{formatCurrency(snap.cash_mano_adjusted ?? snap.cash_mano_total)}</p>
        </div>
        <div>
          <p className="text-[10px] text-gray-400 dark:text-gray-500">Card</p>
          <p className="text-sm font-medium text-navy dark:text-gray-200">{formatCurrency(snap.card_adjusted ?? snap.card_total)}</p>
        </div>
        <div className="ml-auto text-right">
          <p className="text-[10px] text-gray-400 dark:text-gray-500">Total</p>
          <p className="text-sm font-bold text-teal">{formatCurrency(snap.combined_total)}</p>
        </div>
      </div>
    </div>
  )
}

// iOS LiveBalanceRow equivalent
function BalanceRow({ icon: Icon, iconBg, iconColor, label, balance }) {
  return (
    <div className="card flex items-center gap-3">
      <div className={`w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0 ${iconBg}`}>
        <Icon className={`w-4 h-4 ${iconColor}`} />
      </div>
      <p className="text-sm text-gray-700 dark:text-gray-200 flex-1 truncate">{label}</p>
      <p className={`text-sm font-semibold ${balance < 0 ? 'text-red-500' : 'text-navy dark:text-white'}`}>
        {formatCurrency(balance)}
      </p>
    </div>
  )
}

export default function AdminDashboardPage() {
  const { user } = useAuth()
  const [showroomFilter, setShowroomFilter] = useState(null)

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.ADMIN_DASHBOARD_SUMMARY)
  const { data: pendingData, refetch: refetchPending } = useFetch(ENDPOINTS.ADMIN_EDIT_REQUESTS_PENDING_COUNT)
  const { data: cardAccountsRaw, refetch: refetchCards } = useFetch(ENDPOINTS.CARD_ACCOUNTS)
  const { data: extAccountsRaw, refetch: refetchExt } = useFetch(ENDPOINTS.EXTERNAL_ACCOUNTS)

  useEffect(() => {
    const t = setInterval(() => {
      refetch(true); refetchPending(true); refetchCards(true); refetchExt(true)
    }, POLL)
    return () => clearInterval(t)
  }, [refetch, refetchPending, refetchCards, refetchExt])

  const handleRefresh = useCallback(() => {
    refetch(); refetchPending(); refetchCards(); refetchExt()
  }, [refetch, refetchPending, refetchCards, refetchExt])

  const today = data?.today
  const pendingCount = pendingData?.count ?? 0

  const cardAccounts = Array.isArray(cardAccountsRaw) ? cardAccountsRaw : (cardAccountsRaw?.data || [])
  const extAccounts = Array.isArray(extAccountsRaw) ? extAccountsRaw : (extAccountsRaw?.data || [])

  // Showroom filter options for Account Balances
  const showroomOptions = [...new Map(
    cardAccounts.filter(a => a.showroom?.name || a.showroom_name).map(a => {
      const id = a.showroom_id
      const name = a.showroom?.name || a.showroom_name
      return [id, { id, name }]
    })
  ).values()].sort((a, b) => a.name.localeCompare(b.name))

  const filteredCards = showroomFilter
    ? cardAccounts.filter(a => a.showroom_id === showroomFilter)
    : cardAccounts

  const cardTotal = filteredCards.reduce((s, a) => s + (parseFloat(a.current_balance) || 0), 0)

  const hasBalances = cardAccounts.length > 0 || extAccounts.length > 0

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

      {/* Today stat cards — 2×2 like iOS */}
      <div className="grid grid-cols-2 gap-3">
        <StatCard
          label="Main Cash"
          adjValue={today?.cash_main_adjusted}
          rawValue={today?.cash_main_total}
          colorClass="text-teal"
        />
        <StatCard
          label="Mano Cash"
          adjValue={today?.cash_mano_adjusted}
          rawValue={today?.cash_mano_total}
          colorClass="text-navy dark:text-white"
        />
        <StatCard
          label="Card Total"
          adjValue={today?.card_adjusted}
          rawValue={today?.card_total}
          colorClass="text-[#6366F1]"
        />
        <StatCard
          label="Grand Total"
          adjValue={today?.grand_adjusted}
          rawValue={today?.grand_total}
          colorClass="text-green-500 dark:text-green-400"
        />
      </div>

      {/* Per Showroom — Today */}
      {today?.per_showroom?.length > 0 && (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Per Showroom — Today
          </p>
          {today.per_showroom.map(snap => (
            <ShowroomRow key={snap.showroom_id} snap={snap} />
          ))}
        </div>
      )}

      {/* Account Balances */}
      {hasBalances && (
        <div className="space-y-2">
          <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide">
            Account Balances
          </p>

          {/* Showroom filter chips */}
          {showroomOptions.length > 1 && (
            <div className="flex gap-2 flex-wrap">
              <button
                onClick={() => setShowroomFilter(null)}
                className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                  showroomFilter === null ? 'bg-teal text-white' : 'bg-teal/10 text-teal'
                }`}
              >
                All
              </button>
              {showroomOptions.map(s => (
                <button
                  key={s.id}
                  onClick={() => setShowroomFilter(s.id)}
                  className={`px-3 py-1 rounded-full text-xs font-medium transition-colors ${
                    showroomFilter === s.id ? 'bg-teal text-white' : 'bg-teal/10 text-teal'
                  }`}
                >
                  {s.name}
                </button>
              ))}
            </div>
          )}

          {/* External (cash) accounts */}
          {extAccounts.map(acc => {
            const isMain = acc.cash_account_type === 'main'
            return (
              <BalanceRow
                key={acc.id}
                icon={isMain ? MdAccountBalance : MdAttachMoney}
                iconBg={isMain ? 'bg-navy/10 dark:bg-white/10' : 'bg-teal/10'}
                iconColor={isMain ? 'text-navy dark:text-white' : 'text-teal'}
                label={acc.name}
                balance={parseFloat(acc.balance) || 0}
              />
            )
          })}

          {/* Card accounts */}
          {filteredCards.map(acc => (
            <BalanceRow
              key={acc.id}
              icon={MdCreditCard}
              iconBg="bg-[#6366F1]/10"
              iconColor="text-[#6366F1]"
              label={`${acc.bank_name} •••• ${acc.last_four}`}
              balance={parseFloat(acc.current_balance) || 0}
            />
          ))}

          {/* Card total */}
          {filteredCards.length > 0 && (
            <div className="card flex items-center justify-between">
              <p className="text-sm font-semibold text-gray-500 dark:text-gray-400">
                {showroomFilter ? 'Filtered Card Total' : 'Card Total'}
              </p>
              <p className="text-sm font-bold text-[#6366F1]">{formatCurrency(cardTotal)}</p>
            </div>
          )}
        </div>
      )}
    </div>
  )
}
