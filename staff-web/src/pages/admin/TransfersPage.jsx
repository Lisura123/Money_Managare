import { MdSwapHoriz } from 'react-icons/md'
import { Link } from 'react-router-dom'

function TransferItem({ to, icon: Icon, iconBg, iconColor, label, description }) {
  return (
    <Link
      to={to}
      className="flex items-center gap-4 px-4 py-4 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group"
    >
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${iconBg}`}>
        <Icon className={`w-5 h-5 ${iconColor}`} />
      </div>
      <div className="flex-1 min-w-0">
        <p className="font-medium text-navy dark:text-white text-sm">{label}</p>
        <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{description}</p>
      </div>
      <svg className="w-4 h-4 text-gray-300 dark:text-gray-600 group-hover:text-teal transition-colors flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
      </svg>
    </Link>
  )
}

export default function TransfersPage() {
  return (
    <div className="max-w-lg mx-auto space-y-6">
      <h1 className="text-2xl font-heading font-bold text-navy dark:text-white">Transfers</h1>

      <div className="card divide-y divide-gray-100 dark:divide-white/5 p-0 overflow-hidden">
        <TransferItem
          to="/admin/self-transactions"
          icon={MdSwapHoriz}
          iconBg="bg-teal/10"
          iconColor="text-teal"
          label="Self Transfers"
          description="Transfers between accounts within the system"
        />
        <TransferItem
          to="/admin/cash-transactions"
          icon={MdSwapHoriz}
          iconBg="bg-indigo-50 dark:bg-indigo-900/30"
          iconColor="text-indigo-500"
          label="Cash Transfers"
          description="Admin-level cash account transfers"
        />
      </div>
    </div>
  )
}
