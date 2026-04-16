import { MdLock } from 'react-icons/md'
import { Link } from 'react-router-dom'
import AmountDisplay from '../common/AmountDisplay'
import DateDisplay from '../common/DateDisplay'
import StatusBadge from '../common/StatusBadge'
import { maskCard, truncate } from '../../utils/formatters'

export default function EntryCard({ entry, type, onClick }) {
  const amount = type === 'cash' ? entry.cash_amount : entry.amount

  return (
    <div
      className="card cursor-pointer hover:shadow-card-hover transition-shadow duration-200 flex flex-col gap-3"
      onClick={onClick}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => e.key === 'Enter' && onClick?.()}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="flex flex-wrap gap-1.5">
          <StatusBadge status={type} />
          {type === 'cash' && (
            <StatusBadge
              status={entry.cash_account_type}
              label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
            />
          )}
          {type === 'card' && entry.card_account && (
            <span className="text-xs text-gray-500 dark:text-gray-400 font-mono">
              {entry.card_account.bank_name} {maskCard(entry.card_account.last_four)}
            </span>
          )}
        </div>
        {entry.is_locked && (
          <MdLock className="w-4 h-4 text-gray-400 flex-shrink-0" title="Locked" />
        )}
      </div>

      <div className="flex items-end justify-between gap-4">
        <div>
          <AmountDisplay amount={amount} size="lg" />
          {entry.notes && (
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
              {truncate(entry.notes, 80)}
            </p>
          )}
        </div>
        <div className="flex-shrink-0 text-right">
          <DateDisplay date={entry.entry_date} />
          {!entry.is_locked && (
            <div className="mt-1">
              <Link
                to={`/edit-request/${type}/${entry.id}`}
                onClick={(e) => e.stopPropagation()}
                className="text-xs text-teal hover:underline font-medium"
              >
                Request Edit
              </Link>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
