import { MdCreditCard, MdTune, MdWallet } from 'react-icons/md'
import { Link } from 'react-router-dom'

function EntryGroup({ title, items }) {
  return (
    <div>
      <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2 px-1">
        {title}
      </p>
      <div className="card divide-y divide-gray-100 dark:divide-white/5 p-0 overflow-hidden">
        {items.map((item) => (
          <Link
            key={item.to}
            to={item.to}
            className="flex items-center gap-4 px-4 py-4 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group"
          >
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${item.iconBg}`}>
              <item.icon className={`w-5 h-5 ${item.iconColor}`} />
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-medium text-navy dark:text-white text-sm">{item.label}</p>
              <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{item.description}</p>
            </div>
            <svg className="w-4 h-4 text-gray-300 dark:text-gray-600 group-hover:text-teal transition-colors flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </Link>
        ))}
      </div>
    </div>
  )
}

export default function EntriesPage() {
  return (
    <div className="max-w-lg mx-auto space-y-6">
      <h1 className="text-2xl font-heading font-bold text-navy dark:text-white">Entries</h1>

      <EntryGroup
        title="Daily Entries"
        items={[
          {
            to: '/admin/cash-entries',
            icon: MdWallet,
            iconBg: 'bg-teal/10',
            iconColor: 'text-teal',
            label: 'Cash Entries',
            description: 'View and manage daily cash submissions',
          },
          {
            to: '/admin/card-entries',
            icon: MdCreditCard,
            iconBg: 'bg-indigo-50 dark:bg-indigo-900/30',
            iconColor: 'text-indigo-500',
            label: 'Bank Entries',
            description: 'View and manage daily bank card entries',
          },
        ]}
      />

      <EntryGroup
        title="Adjustments"
        items={[
          {
            to: '/admin/cash-adjustments',
            icon: MdTune,
            iconBg: 'bg-amber-50 dark:bg-amber-900/30',
            iconColor: 'text-amber-500',
            label: 'Cash Adjustments',
            description: 'Admin corrections to cash balances',
          },
          {
            to: '/admin/card-adjustments',
            icon: MdTune,
            iconBg: 'bg-purple-50 dark:bg-purple-900/30',
            iconColor: 'text-purple-500',
            label: 'Bank Adjustments',
            description: 'Admin corrections to bank balances',
          },
        ]}
      />
    </div>
  )
}
