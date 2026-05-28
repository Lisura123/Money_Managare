import { useCallback, useEffect } from 'react'
import { Link } from 'react-router-dom'
import { MdRefresh, MdEditNote, MdTrendingUp, MdTrendingDown, MdStorefront } from 'react-icons/md'
import Card from '../../components/common/Card'
import PageHeader from '../../components/common/PageHeader'
import { useFetch } from '../../hooks/useFetch'
import { useAuth } from '../../hooks/useAuth'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency, getGreeting } from '../../utils/formatters'

const POLL = 60_000

function StatCard({ label, value, sub, color = 'teal' }) {
  const colors = {
    teal: 'bg-teal/10 text-teal',
    blue: 'bg-blue-500/10 text-blue-500',
    purple: 'bg-purple-500/10 text-purple-500',
    amber: 'bg-amber-500/10 text-amber-600',
  }
  return (
    <div className="card">
      <p className="text-xs text-gray-500 dark:text-gray-400 font-medium uppercase tracking-wide mb-1">{label}</p>
      <p className={`text-2xl font-heading font-bold ${color === 'teal' ? 'text-navy dark:text-white' : 'text-navy dark:text-white'}`}>{value}</p>
      {sub && <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{sub}</p>}
    </div>
  )
}

export default function AdminDashboardPage() {
  const { user } = useAuth()

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.ADMIN_DASHBOARD_SUMMARY)
  const { data: pendingData, refetch: refetchPending } = useFetch(ENDPOINTS.ADMIN_EDIT_REQUESTS_PENDING_COUNT)

  useEffect(() => {
    const t = setInterval(() => {
      refetch(true)
      refetchPending(true)
    }, POLL)
    return () => clearInterval(t)
  }, [refetch, refetchPending])

  const handleRefresh = useCallback(() => {
    refetch()
    refetchPending()
  }, [refetch, refetchPending])

  const today = data?.today
  const yesterday = data?.yesterday
  const pendingCount = pendingData?.count ?? 0

  return (
    <div className="space-y-6 animate-fade-in">
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

      {/* Today's totals */}
      <div>
        <h2 className="font-heading font-semibold text-gray-700 dark:text-gray-300 text-sm uppercase tracking-wide mb-3">Today</h2>
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard label="Cash (Main)" value={formatCurrency(today?.cash_main_adjusted ?? today?.cash_main_total)} sub={today?.cash_main_adjusted !== today?.cash_main_total ? `Raw: ${formatCurrency(today?.cash_main_total)}` : null} />
          <StatCard label="Cash (Mano)" value={formatCurrency(today?.cash_mano_adjusted ?? today?.cash_mano_total)} color="blue" sub={today?.cash_mano_adjusted !== today?.cash_mano_total ? `Raw: ${formatCurrency(today?.cash_mano_total)}` : null} />
          <StatCard label="Card Total" value={formatCurrency(today?.card_adjusted ?? today?.card_total)} color="purple" />
          <StatCard label="Grand Total" value={formatCurrency(today?.grand_adjusted ?? today?.grand_total)} color="amber" />
        </div>
      </div>

      {/* Yesterday comparison */}
      {yesterday && (
        <div>
          <h2 className="font-heading font-semibold text-gray-700 dark:text-gray-300 text-sm uppercase tracking-wide mb-3">Yesterday</h2>
          <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
            <StatCard label="Cash (Main)" value={formatCurrency(yesterday.cash_main_adjusted ?? yesterday.cash_main_total)} />
            <StatCard label="Cash (Mano)" value={formatCurrency(yesterday.cash_mano_adjusted ?? yesterday.cash_mano_total)} color="blue" />
            <StatCard label="Card Total" value={formatCurrency(yesterday.card_adjusted ?? yesterday.card_total)} color="purple" />
            <StatCard label="Grand Total" value={formatCurrency(yesterday.grand_adjusted ?? yesterday.grand_total)} color="amber" />
          </div>
        </div>
      )}

      {/* Per-showroom breakdown */}
      {today?.per_showroom?.length > 0 && (
        <Card>
          <div className="flex items-center gap-2 mb-4">
            <MdStorefront className="w-5 h-5 text-teal" />
            <h2 className="font-heading font-semibold text-navy dark:text-white">Today by Showroom</h2>
          </div>
          <div className="overflow-x-auto -mx-4 md:mx-0">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-gray-200 dark:border-white/10">
                  <th className="text-left py-2 px-4 text-gray-500 dark:text-gray-400 font-medium">Showroom</th>
                  <th className="text-right py-2 px-4 text-gray-500 dark:text-gray-400 font-medium">Cash (Main)</th>
                  <th className="text-right py-2 px-4 text-gray-500 dark:text-gray-400 font-medium">Cash (Mano)</th>
                  <th className="text-right py-2 px-4 text-gray-500 dark:text-gray-400 font-medium">Card</th>
                  <th className="text-right py-2 px-4 text-gray-500 dark:text-gray-400 font-medium">Total</th>
                  <th className="text-right py-2 px-4 text-gray-500 dark:text-gray-400 font-medium">Entries</th>
                </tr>
              </thead>
              <tbody>
                {today.per_showroom.map((s) => (
                  <tr key={s.showroom_id} className="border-b border-gray-100 dark:border-white/5 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors">
                    <td className="py-3 px-4 font-medium text-navy dark:text-white">{s.showroom_name}</td>
                    <td className="py-3 px-4 text-right text-gray-700 dark:text-gray-300">{formatCurrency(s.cash_main_adjusted ?? s.cash_main_total)}</td>
                    <td className="py-3 px-4 text-right text-gray-700 dark:text-gray-300">{formatCurrency(s.cash_mano_adjusted ?? s.cash_mano_total)}</td>
                    <td className="py-3 px-4 text-right text-gray-700 dark:text-gray-300">{formatCurrency(s.card_adjusted ?? s.card_total)}</td>
                    <td className="py-3 px-4 text-right font-semibold text-navy dark:text-white">{formatCurrency(s.combined_total)}</td>
                    <td className="py-3 px-4 text-right text-gray-500">{s.entry_count}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t-2 border-gray-200 dark:border-white/20">
                  <td className="py-3 px-4 font-semibold text-navy dark:text-white">Total</td>
                  <td className="py-3 px-4 text-right font-semibold text-navy dark:text-white">{formatCurrency(today.cash_main_adjusted ?? today.cash_main_total)}</td>
                  <td className="py-3 px-4 text-right font-semibold text-navy dark:text-white">{formatCurrency(today.cash_mano_adjusted ?? today.cash_mano_total)}</td>
                  <td className="py-3 px-4 text-right font-semibold text-navy dark:text-white">{formatCurrency(today.card_adjusted ?? today.card_total)}</td>
                  <td className="py-3 px-4 text-right font-bold text-teal">{formatCurrency(today.grand_adjusted ?? today.grand_total)}</td>
                  <td className="py-3 px-4 text-right font-semibold text-gray-500">{today.per_showroom.reduce((s, r) => s + (r.entry_count || 0), 0)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        </Card>
      )}

      {/* Quick links */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
        {[
          { to: '/admin/showrooms', label: 'Showrooms' },
          { to: '/admin/staff', label: 'Staff' },
          { to: '/admin/cash-entries', label: 'Cash Entries' },
          { to: '/admin/reports', label: 'Reports' },
        ].map((l) => (
          <Link key={l.to} to={l.to} className="card text-center text-sm font-medium text-teal hover:bg-teal/5 transition-colors cursor-pointer">
            {l.label} →
          </Link>
        ))}
      </div>
    </div>
  )
}
