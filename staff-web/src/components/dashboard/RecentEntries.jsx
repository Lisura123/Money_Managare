import { useState } from 'react'
import { MdLock } from 'react-icons/md'
import { BsInboxFill } from 'react-icons/bs'
import AmountDisplay from '../common/AmountDisplay'
import DateDisplay from '../common/DateDisplay'
import StatusBadge from '../common/StatusBadge'
import { truncate } from '../../utils/formatters'
import EntryDetailModal from '../entries/EntryDetailModal'

export default function RecentEntries({ cashEntries = [], cardEntries = [], loading = false }) {
  const [selected, setSelected] = useState(null)

  // Merge and sort by created_at desc, take top 10
  const combined = [
    ...cashEntries.map((e) => ({ ...e, _type: 'cash' })),
    ...cardEntries.map((e) => ({ ...e, _type: 'card' })),
  ]
    .sort((a, b) => new Date(b.created_at) - new Date(a.created_at))
    .slice(0, 10)

  if (loading) {
    return (
      <div className="space-y-2">
        {[...Array(4)].map((_, i) => (
          <div key={i} className="skeleton h-12 rounded-lg" />
        ))}
      </div>
    )
  }

  if (combined.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-10 gap-2">
        <BsInboxFill className="w-8 h-8 text-gray-300 dark:text-gray-600" />
        <p className="text-sm text-gray-500 dark:text-gray-400">No entries yet today</p>
      </div>
    )
  }

  return (
    <>
      {/* Desktop table */}
      <div className="hidden md:block overflow-x-auto">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b border-gray-100 dark:border-white/10">
              <th className="text-left py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide w-36">
                Type
              </th>
              <th className="text-left py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide w-28">
                Date
              </th>
              <th className="text-right py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide w-36">
                Amount
              </th>
              <th className="text-left py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide hidden lg:table-cell">
                Notes
              </th>
              <th className="text-center py-2 px-3 text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide w-20">
                Status
              </th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-50 dark:divide-white/5">
            {combined.map((entry) => {
              const amount = entry._type === 'cash' ? entry.cash_amount : entry.amount
              const cardLabel = entry._type === 'card' && entry.card_account
                ? `${entry.card_account.bank_name} ···· ${entry.card_account.last_four}`
                : null
              return (
                <tr
                  key={`${entry._type}-${entry.id}`}
                  className="table-row-hover"
                  onClick={() => setSelected(entry)}
                >
                  <td className="py-3 px-3 w-36">
                    <div className="flex gap-1.5 flex-wrap">
                      <StatusBadge status={entry._type} />
                      {entry._type === 'cash' && (
                        <StatusBadge
                          status={entry.cash_account_type}
                          label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
                        />
                      )}
                    </div>
                    {cardLabel && (
                      <p className="text-xs text-gray-400 dark:text-gray-500 mt-1 truncate max-w-[130px]">
                        {cardLabel}
                      </p>
                    )}
                  </td>
                  <td className="py-3 px-3 w-28">
                    <DateDisplay date={entry.entry_date} />
                  </td>
                  <td className="py-3 px-3 text-right w-36">
                    <AmountDisplay amount={amount} size="sm" />
                  </td>
                  <td className="py-3 px-3 hidden lg:table-cell">
                    <span className="text-gray-500 dark:text-gray-400 text-xs">
                      {truncate(entry.notes, 45) || '—'}
                    </span>
                  </td>
                  <td className="py-3 px-3 text-center w-20">
                    {entry.is_locked ? (
                      <MdLock className="w-4 h-4 text-gray-400 mx-auto" title="Locked" />
                    ) : (
                      <span className="text-xs text-success">Open</span>
                    )}
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>

      {/* Mobile cards */}
      <div className="md:hidden space-y-2">
        {combined.map((entry) => {
          const amount = entry._type === 'cash' ? entry.cash_amount : entry.amount
          return (
            <button
              key={`${entry._type}-${entry.id}`}
              className="w-full text-left bg-gray-50 dark:bg-white/5 rounded-lg p-3 flex items-center gap-3"
              onClick={() => setSelected(entry)}
            >
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5 mb-1">
                  <StatusBadge status={entry._type} />
                  {entry._type === 'cash' && (
                    <StatusBadge
                      status={entry.cash_account_type}
                      label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
                    />
                  )}
                </div>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  <DateDisplay date={entry.entry_date} />
                </p>
              </div>
              <div className="text-right flex-shrink-0">
                <AmountDisplay amount={amount} size="sm" />
                {entry.is_locked && (
                  <MdLock className="w-3.5 h-3.5 text-gray-400 ml-auto mt-0.5" />
                )}
              </div>
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
