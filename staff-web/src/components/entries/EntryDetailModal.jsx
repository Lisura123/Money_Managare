import { useEffect } from 'react'
import { createPortal } from 'react-dom'
import { MdClose, MdLock } from 'react-icons/md'
import { Link } from 'react-router-dom'
import AmountDisplay from '../common/AmountDisplay'
import StatusBadge from '../common/StatusBadge'
import { formatDate, formatDateTime, maskCard } from '../../utils/formatters'

export default function EntryDetailModal({ entry, onClose }) {
  const type = entry._type || (entry.cash_amount !== undefined ? 'cash' : 'card')
  const amount = type === 'cash' ? entry.cash_amount : entry.amount

  useEffect(() => {
    document.body.style.overflow = 'hidden'
    const handler = (e) => { if (e.key === 'Escape') onClose() }
    window.addEventListener('keydown', handler)
    return () => {
      document.body.style.overflow = ''
      window.removeEventListener('keydown', handler)
    }
  }, [onClose])

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl w-full max-w-md animate-fade-in overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-5 py-4 border-b border-gray-100 dark:border-white/10">
          <div className="flex items-center gap-2">
            <h2 className="font-heading font-semibold text-gray-900 dark:text-white text-base">
              Entry Detail
            </h2>
            {entry.is_locked && (
              <MdLock className="w-4 h-4 text-gray-400" title="Locked" />
            )}
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 hover:bg-gray-100 dark:hover:bg-white/5 transition-colors"
          >
            <MdClose className="w-5 h-5" />
          </button>
        </div>

        {/* Body */}
        <div className="px-5 py-4 space-y-4">
          <div className="flex flex-wrap gap-2">
            <StatusBadge status={type} />
            {type === 'cash' && (
              <StatusBadge
                status={entry.cash_account_type}
                label={entry.cash_account_type === 'mano' ? "Mano's" : 'Main'}
              />
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium uppercase tracking-wide mb-1">
                Amount
              </p>
              <AmountDisplay amount={amount} size="lg" />
            </div>
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium uppercase tracking-wide mb-1">
                Date
              </p>
              <p className="font-medium text-gray-800 dark:text-gray-200 text-sm">
                {formatDate(entry.entry_date)}
              </p>
            </div>
          </div>

          {type === 'card' && entry.card_account && (
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium uppercase tracking-wide mb-1">
                Card Account
              </p>
              <p className="text-sm font-medium text-gray-800 dark:text-gray-200">
                {entry.card_account.bank_name}{' '}
                <span className="font-mono">{maskCard(entry.card_account.last_four)}</span>
              </p>
            </div>
          )}

          {entry.notes && (
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 font-medium uppercase tracking-wide mb-1">
                Notes
              </p>
              <p className="text-sm text-gray-700 dark:text-gray-300 bg-gray-50 dark:bg-white/5 rounded-lg p-3">
                {entry.notes}
              </p>
            </div>
          )}

          <div className="grid grid-cols-2 gap-4 pt-2 border-t border-gray-100 dark:border-white/10">
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">Status</p>
              <p className="text-sm text-gray-700 dark:text-gray-300">
                {entry.is_locked ? '🔒 Locked' : '🟢 Open'}
              </p>
            </div>
            <div>
              <p className="text-xs text-gray-500 dark:text-gray-400 mb-0.5">Submitted</p>
              <p className="text-sm text-gray-700 dark:text-gray-300">
                {formatDateTime(entry.created_at)}
              </p>
            </div>
          </div>
        </div>

        {/* Footer */}
        {!entry.is_locked && (
          <div className="px-5 py-4 border-t border-gray-100 dark:border-white/10 bg-gray-50 dark:bg-white/3">
            <Link
              to={`/edit-request/${type}/${entry.id}`}
              onClick={onClose}
              className="btn-outline w-full justify-center"
            >
              Request Edit
            </Link>
          </div>
        )}
      </div>
    </div>,
    document.body,
  )
}
