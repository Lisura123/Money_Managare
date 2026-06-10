import { useState } from 'react'
import { MdArrowDownward, MdArrowUpward, MdLock, MdUnfoldMore } from 'react-icons/md'
import { Link } from 'react-router-dom'
import AmountDisplay from '../common/AmountDisplay'
import DateDisplay from '../common/DateDisplay'
import StatusBadge from '../common/StatusBadge'
import EntryDetailModal from '../entries/EntryDetailModal'
import { maskCard, truncate } from '../../utils/formatters'

function SortIcon({ field, sortField, sortDir }) {
  if (sortField !== field) return <MdUnfoldMore className="w-4 h-4 text-gray-400" />
  return sortDir === 'asc'
    ? <MdArrowUpward className="w-4 h-4 text-teal" />
    : <MdArrowDownward className="w-4 h-4 text-teal" />
}

export default function HistoryTable({ entries = [], loading = false }) {
  const [selected, setSelected] = useState(null)
  const [sortField, setSortField] = useState('entry_date')
  const [sortDir, setSortDir] = useState('desc')

  const handleSort = (field) => {
    if (sortField === field) {
      setSortDir((d) => (d === 'asc' ? 'desc' : 'asc'))
    } else {
      setSortField(field)
      setSortDir('desc')
    }
  }

  const sorted = [...entries].sort((a, b) => {
    let aVal, bVal
    switch (sortField) {
      case 'entry_date':
        aVal = a.entry_date
        bVal = b.entry_date
        break
      case 'amount':
        aVal = parseFloat(a._type === 'cash' ? a.cash_amount : a.amount) || 0
        bVal = parseFloat(b._type === 'cash' ? b.cash_amount : b.amount) || 0
        break
      default:
        aVal = a[sortField]
        bVal = b[sortField]
    }
    if (aVal < bVal) return sortDir === 'asc' ? -1 : 1
    if (aVal > bVal) return sortDir === 'asc' ? 1 : -1
    return 0
  })

  if (loading) {
    return (
      <div className="space-y-2 p-4">
        {[...Array(6)].map((_, i) => (
          <div key={i} className="skeleton h-12 rounded-lg" />
        ))}
      </div>
    )
  }

  return (
    <>
      {/* Desktop table */}
      <div className="hidden md:block overflow-x-auto">
        <table className="w-full text-sm">
          <thead className="bg-gray-50 dark:bg-white/5">
            <tr>
              {[
                { label: 'Date', field: 'entry_date' },
                { label: 'Type', field: null },
                { label: 'Amount', field: 'amount' },
                { label: 'Bank / Account', field: null },
                { label: 'Notes', field: null },
                { label: 'Status', field: null },
                { label: 'Actions', field: null },
              ].map((col) => (
                <th
                  key={col.label}
                  className={`py-3 px-4 text-left text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide ${
                    col.field ? 'cursor-pointer hover:text-navy dark:hover:text-white select-none' : ''
                  }`}
                  onClick={col.field ? () => handleSort(col.field) : undefined}
                >
                  <div className="flex items-center gap-1">
                    {col.label}
                    {col.field && (
                      <SortIcon field={col.field} sortField={sortField} sortDir={sortDir} />
                    )}
                  </div>
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50 dark:divide-white/5">
            {sorted.map((entry, idx) => {
              const amount = entry._type === 'cash' ? entry.cash_amount : entry.amount
              return (
                <tr
                  key={`${entry._type}-${entry.id}`}
                  className={`table-row-hover ${idx % 2 === 1 ? 'bg-gray-50/50 dark:bg-white/2' : ''}`}
                  onClick={() => setSelected(entry)}
                >
                  <td className="py-3 px-4">
                    <DateDisplay date={entry.entry_date} />
                  </td>
                  <td className="py-3 px-4">
                    <div className="flex flex-wrap gap-1">
                      <StatusBadge status={entry._type} />
                      {entry._type === 'cash' && (
                        <StatusBadge
                          status={entry.cash_account_type}
                          label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
                        />
                      )}
                    </div>
                  </td>
                  <td className="py-3 px-4 font-mono tabular-nums">
                    <AmountDisplay amount={amount} size="sm" />
                  </td>
                  <td className="py-3 px-4 text-sm text-gray-600 dark:text-gray-400">
                    {entry._type === 'card' && entry.card_account
                      ? `${entry.card_account.bank_name} ${maskCard(entry.card_account.last_four)}`
                      : entry._type === 'cash'
                        ? entry.cash_account_type === 'mano'
                          ? "Mano's Account"
                          : 'Main Account'
                        : '—'}
                  </td>
                  <td className="py-3 px-4 text-xs text-gray-500 dark:text-gray-400 max-w-[160px]">
                    {truncate(entry.notes, 45) || '—'}
                  </td>
                  <td className="py-3 px-4">
                    {entry.is_locked ? (
                      <span className="flex items-center gap-1 text-xs text-gray-500 dark:text-gray-400">
                        <MdLock className="w-3.5 h-3.5" /> Locked
                      </span>
                    ) : (
                      <span className="text-xs text-success font-medium">Open</span>
                    )}
                  </td>
                  <td className="py-3 px-4">
                    {!entry.is_locked && (
                      <Link
                        to={`/edit-request/${entry._type}/${entry.id}`}
                        onClick={(e) => e.stopPropagation()}
                        className="text-xs text-teal hover:underline font-medium whitespace-nowrap"
                      >
                        Edit Request
                      </Link>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* Mobile / tablet card view */}
      <div className="md:hidden space-y-3 p-4">
        {sorted.map((entry) => {
          const amount = entry._type === 'cash' ? entry.cash_amount : entry.amount
          return (
            <button
              key={`${entry._type}-${entry.id}`}
              className="w-full text-left card p-4"
              onClick={() => setSelected(entry)}
            >
              <div className="flex items-center justify-between mb-2">
                <div className="flex flex-wrap gap-1.5">
                  <StatusBadge status={entry._type} />
                  {entry._type === 'cash' && (
                    <StatusBadge
                      status={entry.cash_account_type}
                      label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
                    />
                  )}
                </div>
                {entry.is_locked && <MdLock className="w-4 h-4 text-gray-400" />}
              </div>
              <div className="flex items-end justify-between">
                <AmountDisplay amount={amount} size="lg" />
                <DateDisplay date={entry.entry_date} />
              </div>
              {entry.notes && (
                <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
                  {truncate(entry.notes, 80)}
                </p>
              )}
            </button>
          )
        })}
      </div>

      {selected && (
        <EntryDetailModal entry={selected} onClose={() => setSelected(null)} />
      )}
    </>
  )
}
