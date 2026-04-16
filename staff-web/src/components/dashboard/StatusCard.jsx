import { MdCheckCircle, MdSchedule } from 'react-icons/md'
import { Link } from 'react-router-dom'
import { formatCurrency } from '../../utils/formatters'

export default function StatusCard({ label, submitted, amount, count, accent = 'teal', actionTo }) {
  const isSubmitted = submitted

  const colors = {
    teal: {
      submitted: 'bg-teal/10 border-teal/30 dark:bg-teal/10 dark:border-teal/20',
      pending: 'bg-amber-50 border-amber-200 dark:bg-amber-500/10 dark:border-amber-500/30',
    },
    purple: {
      submitted: 'bg-purple-50 border-purple-200 dark:bg-purple-500/10 dark:border-purple-500/20',
      pending: 'bg-amber-50 border-amber-200 dark:bg-amber-500/10 dark:border-amber-500/30',
    },
    navy: {
      submitted: 'bg-navy/5 border-navy/20 dark:bg-white/5 dark:border-white/20',
      pending: 'bg-amber-50 border-amber-200 dark:bg-amber-500/10 dark:border-amber-500/30',
    },
  }

  const colorSet = colors[accent] || colors.teal
  const cardClass = isSubmitted ? colorSet.submitted : colorSet.pending

  return (
    <div
      className={`rounded-xl border-2 p-4 flex flex-col gap-2 ${cardClass} ${
        !isSubmitted ? 'animate-pulse-border' : ''
      }`}
    >
      <div className="flex items-center justify-between">
        <span className="text-xs font-semibold text-gray-600 dark:text-gray-400 uppercase tracking-wide">
          {label}
        </span>
        {isSubmitted ? (
          <MdCheckCircle className="w-5 h-5 text-success" />
        ) : (
          <MdSchedule className="w-5 h-5 text-amber-500" />
        )}
      </div>

      {isSubmitted ? (
        <div>
          {amount !== undefined && amount !== null && (
            <p className="text-lg font-heading font-bold text-gray-900 dark:text-white">
              {formatCurrency(amount)}
            </p>
          )}
          {count !== undefined && (
            <p className="text-sm text-gray-600 dark:text-gray-400">
              {count} {count === 1 ? 'entry' : 'entries'}
              {amount ? ` — ${formatCurrency(amount)}` : ''}
            </p>
          )}
          <p className="text-xs text-success font-medium mt-0.5">✓ Submitted</p>
        </div>
      ) : (
        <div>
          <p className="text-sm text-amber-700 dark:text-amber-400 font-medium">Not submitted yet</p>
          {actionTo && (
            <Link
              to={actionTo}
              className="text-xs text-teal hover:underline font-medium mt-1 inline-block"
            >
              Submit now →
            </Link>
          )}
        </div>
      )}
    </div>
  )
}
