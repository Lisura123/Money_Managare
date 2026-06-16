import { useEffect, useState } from 'react'
import {
  MdFilterAlt, MdRefresh, MdWallet, MdCreditCard, MdTune,
  MdSwapHoriz, MdHistory, MdArrowForward, MdPerson, MdInbox, MdCalendarMonth,
  MdStorefront, MdNotes, MdAccessTime,
} from 'react-icons/md'
import api from '../../config/api'
import { formatCurrency, formatDateTime, formatDate } from '../../utils/formatters'

// ─── Tab config ────────────────────────────────────────────────
const TABS = [
  { key: 'cashEntries',    label: 'Cash Entries',      Icon: MdWallet,     shortLabel: 'cash entries' },
  { key: 'bankEntries',    label: 'Bank Entries',       Icon: MdCreditCard, shortLabel: 'bank entries' },
  { key: 'cashAdj',        label: 'Cash Adjustments',  Icon: MdTune,       shortLabel: 'cash adjustments' },
  { key: 'bankAdj',        label: 'Bank Adjustments',  Icon: MdTune,       shortLabel: 'bank adjustments' },
  { key: 'selfTx',         label: 'Self Transactions', Icon: MdSwapHoriz,  shortLabel: 'self transactions' },
  { key: 'balanceUpdates', label: 'Balance Updates',   Icon: MdHistory,    shortLabel: 'balance updates' },
]

// ─── Quick date presets ───────────────────────────────────────
const QUICK_PRESETS = [
  { key: 'today',     label: 'Today' },
  { key: 'yesterday', label: 'Yesterday' },
  { key: 'week',      label: 'Last 7 days' },
  { key: 'month',     label: 'This month' },
]

// ─── Helpers ──────────────────────────────────────────────────────────────────
const maskCard = (last4) => last4 ? `••••${last4}` : '—'

// ─── Stat Card ────────────────────────────────────────────────────────────────
function StatCard({ label, value, colorClass, BgClass, Icon }) {
  return (
    <div className="card space-y-2 p-3 border border-gray-100 dark:border-white/5 hover:shadow-card-hover transition-shadow">
      <div className={`w-8 h-8 rounded-lg flex items-center justify-center ${BgClass}`}>
        <Icon className={`w-4 h-4 ${colorClass}`} />
      </div>
      <p className="text-[11px] text-gray-500 dark:text-gray-400 font-medium leading-tight">{label}</p>
      <p className={`text-sm font-heading font-bold ${colorClass} leading-none`}>{formatCurrency(value ?? 0)}</p>
    </div>
  )
}

// ─── Row Components ───────────────────────────────────────────────────────────
function CashEntryRow({ entry }) {
  const adjusted = entry.adjustments?.length
    ? entry.adjustments[entry.adjustments.length - 1].adjusted_amount
    : entry.cash_amount
  const isAdjusted = parseFloat(adjusted) !== parseFloat(entry.cash_amount)
  const isMain = entry.cash_account_type === 'main'

  return (
    <div className="card flex items-center justify-between gap-3">
      <div className="flex-1 min-w-0 space-y-0.5">
        <div className="flex items-center gap-1.5 flex-wrap">
          <p className="text-sm font-semibold text-navy dark:text-white">{formatDate(entry.entry_date)}</p>
          {entry.created_at && (
            <span className="text-[10px] text-gray-400 dark:text-gray-500 flex items-center gap-0.5">
              <MdAccessTime className="w-3 h-3" />{formatDateTime(entry.created_at)}
            </span>
          )}
        </div>
        {entry.user?.name && <p className="text-xs text-gray-500 dark:text-gray-400">{entry.user.name}</p>}
        <div className="flex items-center gap-2 flex-wrap">
          {entry.showroom?.name && (
            <span className="text-xs text-gray-400 dark:text-gray-500">{entry.showroom.name}</span>
          )}
          <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded-full ${
            isMain ? 'bg-teal/10 text-teal' : 'bg-blue-500/10 text-blue-600 dark:text-blue-400'
          }`}>
            {isMain ? 'Main' : "Mano's"}
          </span>
        </div>
        {entry.notes && (
          <p className="text-[11px] text-gray-400 dark:text-gray-500 italic truncate flex items-center gap-1">
            <MdNotes className="w-3 h-3 flex-shrink-0" />{entry.notes}
          </p>
        )}
      </div>
      <div className="text-right flex-shrink-0">
        <p className="text-sm font-bold text-navy dark:text-white">{formatCurrency(adjusted)}</p>
        {isAdjusted && (
          <p className="text-[10px] text-gray-400 line-through">{formatCurrency(entry.cash_amount)}</p>
        )}
      </div>
    </div>
  )
}

function CardEntryRow({ entry }) {
  const adjusted = entry.adjustments?.length
    ? entry.adjustments[entry.adjustments.length - 1].adjusted_amount
    : entry.amount
  const isAdjusted = parseFloat(adjusted) !== parseFloat(entry.amount)
  const card = entry.card_account
    ? `${entry.card_account.bank_name} ${maskCard(entry.card_account.last_four)}`
    : '—'

  return (
    <div className="card flex items-center justify-between gap-3">
      <div className="flex-1 min-w-0 space-y-0.5">
        <div className="flex items-center gap-1.5 flex-wrap">
          <p className="text-sm font-semibold text-navy dark:text-white">{formatDate(entry.entry_date)}</p>
          {entry.created_at && (
            <span className="text-[10px] text-gray-400 dark:text-gray-500 flex items-center gap-0.5">
              <MdAccessTime className="w-3 h-3" />{formatDateTime(entry.created_at)}
            </span>
          )}
        </div>
        {entry.user?.name && <p className="text-xs text-gray-500 dark:text-gray-400">{entry.user.name}</p>}
        {entry.showroom?.name && (
          <p className="text-xs text-gray-400 dark:text-gray-500">{entry.showroom.name}</p>
        )}
        <p className="text-xs text-gray-400 dark:text-gray-500">{card}</p>
        {entry.notes && (
          <p className="text-[11px] text-gray-400 dark:text-gray-500 italic truncate flex items-center gap-1">
            <MdNotes className="w-3 h-3 flex-shrink-0" />{entry.notes}
          </p>
        )}
      </div>
      <div className="text-right flex-shrink-0">
        <p className="text-sm font-bold text-navy dark:text-white">{formatCurrency(adjusted)}</p>
        {isAdjusted && (
          <p className="text-[10px] text-gray-400 line-through">{formatCurrency(entry.amount)}</p>
        )}
      </div>
    </div>
  )
}

function CashAdjRow({ adj }) {
  const amount = parseFloat(adj.adjusted_amount ?? adj.adjustedAmount ?? 0)
  const isPositive = amount >= 0
  const label = (adj.cash_account_type ?? adj.cashAccountType) === 'mano' ? "Mano's Cash" : 'Main Cash'

  return (
    <div className="card flex items-center justify-between gap-3">
      <div className="flex-1 min-w-0 space-y-0.5">
        <p className="text-sm font-semibold text-navy dark:text-white">{label}</p>
        {(adj.showroom_name || adj.showroom?.name) && (
          <p className="text-xs text-gray-400">{adj.showroom_name || adj.showroom?.name}</p>
        )}
        {adj.reason && <p className="text-xs text-gray-400 italic">{adj.reason}</p>}
        <div className="flex items-center gap-2 flex-wrap text-xs text-gray-400">
          {adj.admin?.name && (
            <span className="flex items-center gap-1"><MdPerson className="w-3 h-3" />{adj.admin.name}</span>
          )}
          <span>{formatDateTime(adj.created_at)}</span>
        </div>
      </div>
      <p className={`text-sm font-bold flex-shrink-0 ${isPositive ? 'text-success' : 'text-error'}`}>
        {isPositive ? '+' : ''}{formatCurrency(amount)}
      </p>
    </div>
  )
}

function CardAdjRow({ adj }) {
  const amount = parseFloat(adj.adjusted_amount ?? adj.adjustedAmount ?? 0)
  const isPositive = amount >= 0
  const label = adj.account_label || adj.accountLabel
    || `${adj.bank_name || adj.bankName || 'Unknown'} ${maskCard(adj.last_four || adj.lastFour)}`

  return (
    <div className="card flex items-center justify-between gap-3">
      <div className="flex-1 min-w-0 space-y-0.5">
        <p className="text-sm font-semibold text-navy dark:text-white">{label}</p>
        {(adj.showroom_name || adj.showroomName) && (
          <p className="text-xs text-gray-400">{adj.showroom_name || adj.showroomName}</p>
        )}
        {adj.reason && <p className="text-xs text-gray-400 italic">{adj.reason}</p>}
        <div className="flex items-center gap-2 flex-wrap text-xs text-gray-400">
          {adj.admin?.name && (
            <span className="flex items-center gap-1"><MdPerson className="w-3 h-3" />{adj.admin.name}</span>
          )}
          <span>{formatDateTime(adj.created_at)}</span>
        </div>
      </div>
      <p className={`text-sm font-bold flex-shrink-0 ${isPositive ? 'text-success' : 'text-error'}`}>
        {isPositive ? '+' : ''}{formatCurrency(amount)}
      </p>
    </div>
  )
}

function SelfTxRow({ tx }) {
  const fromLabel = tx.from_card_account
    ? `${tx.from_card_account.showroom?.name || ''} — ${maskCard(tx.from_card_account.last_four)}`
    : tx.from_external_account
    ? tx.from_external_account.name
    : tx.from_account_type === 'main'
    ? 'Main Cash'
    : '—'

  const toLabel = tx.to_card_account
    ? `${tx.to_card_account.showroom?.name || ''} — ${maskCard(tx.to_card_account.last_four)}`
    : tx.to_external_account
    ? tx.to_external_account.name
    : tx.to_account_type === 'main'
    ? 'Main Cash'
    : 'Others'

  return (
    <div className="card space-y-2">
      <div className="flex items-center justify-between gap-2">
        <div className="flex items-center gap-2 min-w-0 flex-1">
          <div className="w-8 h-8 rounded-lg bg-teal/10 flex items-center justify-center flex-shrink-0">
            <MdSwapHoriz className="w-4 h-4 text-teal" />
          </div>
          <div className="min-w-0 flex-1">
            <div className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400 min-w-0">
              <span className="truncate">{fromLabel}</span>
              <MdArrowForward className="w-3 h-3 flex-shrink-0 text-gray-400" />
              <span className="truncate">{toLabel}</span>
            </div>
            {tx.notes && (
              <p className="text-[10px] text-gray-400 italic truncate">"{tx.notes}"</p>
            )}
          </div>
        </div>
        <p className="text-sm font-bold text-teal flex-shrink-0">{formatCurrency(tx.amount)}</p>
      </div>
      <p className="text-[10px] text-gray-400">{formatDateTime(tx.created_at)}</p>
    </div>
  )
}

function BalanceUpdateRow({ update, hideShowroom }) {
  const change = parseFloat(update.change_amount ?? 0)
  const isIncrease = change >= 0

  return (
    <div className="card space-y-3">
      <div className="flex items-start justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <div className={`w-9 h-9 rounded-lg flex items-center justify-center flex-shrink-0 ${
            update.account_type === 'bank' ? 'bg-indigo-50 dark:bg-indigo-900/30' : 'bg-teal/10'
          }`}>
            {update.account_type === 'bank'
              ? <MdCreditCard className="w-4 h-4 text-indigo-500" />
              : <MdWallet className="w-4 h-4 text-teal" />}
          </div>
          <div className="min-w-0">
            <p className="font-semibold text-navy dark:text-white text-sm truncate">{update.account_label}</p>
            <div className="flex items-center gap-2 mt-0.5 flex-wrap">
              <span className={`text-[10px] font-medium px-1.5 py-0.5 rounded ${
                update.account_type === 'bank'
                  ? 'bg-indigo-50 dark:bg-indigo-900/30 text-indigo-600 dark:text-indigo-400'
                  : 'bg-teal/10 text-teal'
              }`}>
                {update.account_type === 'bank' ? 'Bank Account' : 'Main Cash'}
              </span>
              {!hideShowroom && update.showroom_name && (
                <span className="text-[10px] text-gray-400 dark:text-gray-500 truncate">{update.showroom_name}</span>
              )}
            </div>
          </div>
        </div>
        <div className="text-right flex-shrink-0">
          <p className={`text-sm font-bold ${isIncrease ? 'text-success' : 'text-error'}`}>
            {isIncrease ? '+' : ''}{formatCurrency(change)}
          </p>
          <p className={`text-[10px] ${isIncrease ? 'text-success' : 'text-error'}`}>
            {isIncrease ? '▲' : '▼'}
          </p>
        </div>
      </div>

      <div className="flex items-center gap-2">
        <div className="flex-1 bg-gray-50 dark:bg-white/5 rounded-lg px-3 py-2 text-center">
          <p className="text-[10px] text-gray-400 mb-0.5">Previous</p>
          <p className="text-sm font-semibold text-navy dark:text-white">{formatCurrency(update.previous_amount)}</p>
        </div>
        <span className="text-gray-300 dark:text-gray-600 text-xs">→</span>
        <div className="flex-1 bg-gray-50 dark:bg-white/5 rounded-lg px-3 py-2 text-center">
          <p className="text-[10px] text-gray-400 mb-0.5">Updated</p>
          <p className="text-sm font-semibold text-navy dark:text-white">{formatCurrency(update.new_amount)}</p>
        </div>
      </div>

      {update.reason && (
        <p className="text-xs text-gray-500 dark:text-gray-400">{update.reason}</p>
      )}

      <div className="flex items-center justify-between text-[10px] text-gray-400 dark:text-gray-500">
        {update.user_name && (
          <span className="flex items-center gap-1">
            <MdPerson className="w-3 h-3" />{update.user_name}
          </span>
        )}
        <span>{update.created_at
          ? new Date(update.created_at).toLocaleString('en-GB', {
              day: 'numeric', month: 'short', year: 'numeric',
              hour: '2-digit', minute: '2-digit',
            })
          : ''}</span>
      </div>
    </div>
  )
}

// ─── Balance Updates grouped by showroom ──────────────────────────────────────
function BalanceUpdatesGrouped({ list }) {
  const groups = []
  const index = new Map()
  for (const u of list) {
    const key = u.showroom_name || 'Unassigned'
    if (!index.has(key)) {
      index.set(key, groups.length)
      groups.push({ showroom: key, items: [] })
    }
    groups[index.get(key)].items.push(u)
  }
  groups.sort((a, b) => a.showroom.localeCompare(b.showroom))

  return (
    <div className="space-y-5 animate-fade-in">
      {groups.map(({ showroom, items }) => {
        const net = items.reduce((s, u) => s + (parseFloat(u.change_amount) || 0), 0)
        const isInc = net >= 0
        return (
          <div key={showroom} className="space-y-2">
            <div className="flex items-center justify-between gap-2 px-1">
              <div className="flex items-center gap-2 min-w-0">
                <div className="w-7 h-7 rounded-lg bg-navy/5 dark:bg-white/10 flex items-center justify-center flex-shrink-0">
                  <MdStorefront className="w-4 h-4 text-navy dark:text-gray-200" />
                </div>
                <h3 className="text-sm font-heading font-bold text-navy dark:text-white truncate">{showroom}</h3>
                <span className="text-[10px] font-bold px-1.5 py-0.5 rounded-full bg-gray-100 dark:bg-white/10 text-gray-500 dark:text-gray-300 flex-shrink-0">
                  {items.length}
                </span>
              </div>
              <div className="text-right flex-shrink-0">
                <p className="text-[10px] text-gray-400 dark:text-gray-500">Net change</p>
                <p className={`text-sm font-bold leading-none ${isInc ? 'text-success' : 'text-error'}`}>
                  {isInc ? '+' : ''}{formatCurrency(net)}
                </p>
              </div>
            </div>
            <div className="space-y-2">
              {items.map((u) => <BalanceUpdateRow key={u.id} update={u} hideShowroom />)}
            </div>
          </div>
        )
      })}
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function RecordsPage() {
  const today = new Date().toISOString().slice(0, 10)
  const [mode, setMode] = useState('single')
  const [date, setDate] = useState(today)
  const [from, setFrom] = useState(() => {
    const d = new Date(); d.setDate(d.getDate() - 7); return d.toISOString().slice(0, 10)
  })
  const [to, setTo] = useState(today)
  const [activeTab, setActiveTab] = useState('cashEntries')

  const [totals, setTotals] = useState(null)
  const [records, setRecords] = useState({
    cashEntries: [], bankEntries: [], cashAdj: [], bankAdj: [], selfTx: [], balanceUpdates: [],
  })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)

  const fetchAll = async (override) => {
    setLoading(true); setError(null)
    try {
      const params = override ?? (mode === 'range' ? { from, to } : { date })
      const bigPage = { ...params, per_page: 200 }

      const [
        totalsRes, cashRes, cardRes, cashAdjRes, cardAdjRes, selfRes, buRes,
      ] = await Promise.all([
        api.get('/admin/records-summary', { params }),
        api.get('/cash-entries',      { params: bigPage }),
        api.get('/card-entries',      { params: bigPage }),
        api.get('/adjustments/cash',  { params: bigPage }),
        api.get('/adjustments/card',  { params: bigPage }),
        api.get('/self-transactions', { params: bigPage }),
        api.get('/balance-updates',   { params: bigPage }),
      ])

      const extract = (res) => res.data?.data ?? res.data ?? []

      setTotals(totalsRes.data)
      setRecords({
        cashEntries:    extract(cashRes),
        bankEntries:    extract(cardRes),
        cashAdj:        extract(cashAdjRes),
        bankAdj:        extract(cardAdjRes),
        selfTx:         extract(selfRes),
        balanceUpdates: extract(buRes),
      })
    } catch (e) {
      setError(e.response?.data?.message || 'Failed to load records.')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { fetchAll() }, []) // eslint-disable-line react-hooks/exhaustive-deps

  // ── Quick date presets ──
  const applyPreset = (preset) => {
    const fmt = (d) => d.toISOString().slice(0, 10)
    const today = new Date()
    if (preset === 'today') {
      const d = fmt(today)
      setMode('single'); setDate(d); fetchAll({ date: d })
    } else if (preset === 'yesterday') {
      const y = new Date(); y.setDate(y.getDate() - 1)
      const d = fmt(y)
      setMode('single'); setDate(d); fetchAll({ date: d })
    } else if (preset === 'week') {
      const f = new Date(); f.setDate(f.getDate() - 6)
      const fr = fmt(f), t = fmt(today)
      setMode('range'); setFrom(fr); setTo(t); fetchAll({ from: fr, to: t })
    } else if (preset === 'month') {
      const f = new Date(today.getFullYear(), today.getMonth(), 1)
      const fr = fmt(f), t = fmt(today)
      setMode('range'); setFrom(fr); setTo(t); fetchAll({ from: fr, to: t })
    }
  }

  // ── Active filter label ──
  const filterLabel = mode === 'range'
    ? `${formatDate(from)} → ${formatDate(to)}`
    : formatDate(date)

  // ── Section summary ──
  const sectionInfo = (() => {
    const list = records[activeTab] ?? []
    let total = 0
    let totalLabel = 'Total in range'
    switch (activeTab) {
      case 'cashEntries':
        total = list.reduce((s, e) => {
          const v = e.adjustments?.length
            ? parseFloat(e.adjustments[e.adjustments.length - 1].adjusted_amount)
            : parseFloat(e.cash_amount)
          return s + (v || 0)
        }, 0)
        break
      case 'bankEntries':
        total = list.reduce((s, e) => {
          const v = e.adjustments?.length
            ? parseFloat(e.adjustments[e.adjustments.length - 1].adjusted_amount)
            : parseFloat(e.amount)
          return s + (v || 0)
        }, 0)
        break
      case 'cashAdj':
      case 'bankAdj':
        total = list.reduce((s, e) => s + (parseFloat(e.adjusted_amount ?? e.adjustedAmount) || 0), 0)
        totalLabel = 'Net adjustment'
        break
      case 'selfTx':
        total = list.reduce((s, e) => s + (parseFloat(e.amount) || 0), 0)
        totalLabel = 'Total transferred'
        break
      case 'balanceUpdates':
        total = list.reduce((s, e) => s + (parseFloat(e.change_amount) || 0), 0)
        totalLabel = 'Net change'
        break
    }
    const tab = TABS.find(t => t.key === activeTab)
    const count = list.length
    const label = count === 1 ? tab.shortLabel.replace(/s$/, '') : tab.shortLabel
    return { count, total, totalLabel, tabLabel: tab.label, shortLabel: label }
  })()

  const renderList = () => {
    const list = records[activeTab] ?? []
    if (list.length === 0) {
      return (
        <div className="card text-center py-12 flex flex-col items-center gap-3">
          <div className="w-14 h-14 rounded-2xl bg-gray-50 dark:bg-white/5 flex items-center justify-center">
            <MdInbox className="w-7 h-7 text-gray-300 dark:text-gray-600" />
          </div>
          <div>
            <p className="text-sm font-semibold text-gray-500 dark:text-gray-300">No records found</p>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-1">Nothing for {filterLabel}. Try another date or range.</p>
          </div>
        </div>
      )
    }
    return (
      <div className="space-y-2 animate-fade-in">
        {activeTab === 'balanceUpdates'
          ? <BalanceUpdatesGrouped list={list} />
          : list.map((item) => {
              switch (activeTab) {
                case 'cashEntries':    return <CashEntryRow     key={item.id} entry={item} />
                case 'bankEntries':    return <CardEntryRow     key={item.id} entry={item} />
                case 'cashAdj':        return <CashAdjRow       key={item.id} adj={item} />
                case 'bankAdj':        return <CardAdjRow       key={item.id} adj={item} />
                case 'selfTx':         return <SelfTxRow        key={item.id} tx={item} />
                default:               return null
              }
            })}
      </div>
    )
  }

  return (
    <div className="max-w-2xl mx-auto space-y-4 animate-fade-in">
      {/* Header */}
      <div className="flex items-center justify-between gap-3">
        <div className="min-w-0">
          <h1 className="text-2xl font-heading font-bold text-navy dark:text-white">Records</h1>
          <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5 flex items-center gap-1">
            <MdCalendarMonth className="w-3.5 h-3.5" />
            <span className="truncate">Showing <span className="font-medium text-gray-500 dark:text-gray-300">{filterLabel}</span></span>
          </p>
        </div>
        <button
          onClick={() => fetchAll()}
          className="p-2.5 rounded-xl bg-white dark:bg-white/5 border border-gray-200 dark:border-white/10 hover:bg-gray-50 dark:hover:bg-white/10 transition-colors disabled:opacity-50 flex-shrink-0"
          disabled={loading}
          title="Refresh"
        >
          <MdRefresh className={`w-5 h-5 text-gray-500 dark:text-gray-300 ${loading ? 'animate-spin' : ''}`} />
        </button>
      </div>

      {/* Filter card */}
      <div className="card space-y-4">
        <div className="flex rounded-xl bg-gray-100 dark:bg-white/5 p-1">
          {['single', 'range'].map((m) => (
            <button
              key={m}
              onClick={() => setMode(m)}
              className={`flex-1 py-2 text-sm font-semibold rounded-lg transition-colors ${
                mode === m
                  ? 'bg-teal text-white shadow-sm'
                  : 'text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-200'
              }`}
            >
              {m === 'single' ? 'Single Date' : 'Date Range'}
            </button>
          ))}
        </div>

        {/* Quick presets */}
        <div className="flex flex-wrap gap-2">
          {QUICK_PRESETS.map(({ key, label }) => (
            <button
              key={key}
              onClick={() => applyPreset(key)}
              disabled={loading}
              className="px-3 py-1 rounded-full text-xs font-medium bg-gray-50 dark:bg-white/5 text-gray-600 dark:text-gray-300 border border-gray-200 dark:border-white/10 hover:border-teal hover:text-teal transition-colors disabled:opacity-50"
            >
              {label}
            </button>
          ))}
        </div>

        {mode === 'single' ? (
          <div>
            <label className="form-label">Date</label>
            <input
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              className="form-input"
            />
          </div>
        ) : (
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label className="form-label">From</label>
              <input
                type="date"
                value={from}
                onChange={(e) => setFrom(e.target.value)}
                className="form-input"
              />
            </div>
            <div>
              <label className="form-label">To</label>
              <input
                type="date"
                value={to}
                onChange={(e) => setTo(e.target.value)}
                className="form-input"
              />
            </div>
          </div>
        )}

        <button onClick={() => fetchAll()} disabled={loading} className="btn-primary w-full">
          <MdFilterAlt className="w-4 h-4" />
          {loading ? 'Loading…' : 'Apply Filter'}
        </button>
      </div>

      {/* Stat cards */}
      <div className="grid grid-cols-3 gap-3">
        <StatCard label="Total Cash"   value={totals?.cash_total} colorClass="text-teal"        BgClass="bg-teal/10"                          Icon={MdWallet} />
        <StatCard label="Total Bank"   value={totals?.bank_total} colorClass="text-indigo-500"  BgClass="bg-indigo-50 dark:bg-indigo-900/30"  Icon={MdCreditCard} />
        <StatCard label="Total Mano's" value={totals?.mano_total} colorClass="text-accent"      BgClass="bg-teal/10"                          Icon={MdPerson} />
      </div>

      {error && (
        <div className="rounded-xl bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 px-4 py-3 text-sm text-error">
          {error}
        </div>
      )}

      {/* Tab bar */}
      <div className="flex gap-2 overflow-x-auto pb-1 -mx-1 px-1 scrollbar-thin">
        {TABS.map(({ key, label, Icon }) => {
          const active = activeTab === key
          const count = records[key]?.length ?? 0
          return (
            <button
              key={key}
              onClick={() => setActiveTab(key)}
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-colors flex-shrink-0 ${
                active
                  ? 'bg-navy text-white dark:bg-teal dark:text-white shadow-sm'
                  : 'bg-white dark:bg-white/10 text-gray-500 dark:text-gray-300 border border-gray-200 dark:border-white/10 hover:border-teal/50'
              }`}
            >
              <Icon className="w-3.5 h-3.5" />
              {label}
              {count > 0 && (
                <span className={`ml-0.5 min-w-[1.1rem] text-center px-1 py-0.5 rounded-full text-[10px] font-bold leading-none ${
                  active
                    ? 'bg-white/25 text-white'
                    : 'bg-gray-100 dark:bg-white/10 text-gray-500 dark:text-gray-300'
                }`}>{count}</span>
              )}
            </button>
          )
        })}
      </div>

      {/* Section summary */}
      <div className="card flex items-center justify-between gap-4">
        <div className="min-w-0">
          <p className="text-sm font-semibold text-navy dark:text-white">{sectionInfo.tabLabel}</p>
          <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">
            {sectionInfo.count} {sectionInfo.shortLabel}
          </p>
        </div>
        <div className="text-right flex-shrink-0">
          <p className="text-[10px] text-gray-400 dark:text-gray-500 font-medium">{sectionInfo.totalLabel}</p>
          <p className="text-base font-bold text-teal leading-tight">{formatCurrency(sectionInfo.total)}</p>
        </div>
      </div>

      {/* Records list */}
      {loading ? (
        <div className="space-y-3">
          {[...Array(3)].map((_, i) => (
            <div key={i} className="card animate-pulse">
              <div className="h-4 bg-gray-200 dark:bg-white/10 rounded w-3/4 mb-2" />
              <div className="h-3 bg-gray-100 dark:bg-white/5 rounded w-1/2" />
            </div>
          ))}
        </div>
      ) : renderList()}
    </div>
  )
}
