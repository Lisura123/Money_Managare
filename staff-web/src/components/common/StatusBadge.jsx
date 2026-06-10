const STATUS_CONFIG = {
  pending: {
    label: 'Pending',
    classes: 'bg-amber-100 text-amber-800 dark:bg-amber-500/20 dark:text-amber-300',
  },
  approved: {
    label: 'Approved',
    classes: 'bg-green-100 text-green-800 dark:bg-green-500/20 dark:text-green-300',
  },
  rejected: {
    label: 'Rejected',
    classes: 'bg-red-100 text-red-800 dark:bg-red-500/20 dark:text-red-300',
  },
  cash: {
    label: 'Cash',
    classes: 'bg-blue-100 text-blue-800 dark:bg-blue-500/20 dark:text-blue-300',
  },
  card: {
    label: 'Bank',
    classes: 'bg-purple-100 text-purple-800 dark:bg-purple-500/20 dark:text-purple-300',
  },
  main: {
    label: 'Main',
    classes: 'bg-teal-100 text-teal-800 dark:bg-teal/20 dark:text-teal',
  },
  mano: {
    label: "Mano's",
    classes: 'bg-purple-100 text-purple-800 dark:bg-purple-500/20 dark:text-purple-300',
  },
  locked: {
    label: 'Locked',
    classes: 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
  },
}

export default function StatusBadge({ status, label, size = 'sm' }) {
  const config = STATUS_CONFIG[status] || {
    label: label || status,
    classes: 'bg-gray-100 text-gray-600 dark:bg-gray-700 dark:text-gray-400',
  }

  const sizeClasses = size === 'xs'
    ? 'px-1.5 py-0.5 text-xs'
    : size === 'sm'
      ? 'px-2.5 py-0.5 text-xs font-medium'
      : 'px-3 py-1 text-sm font-medium'

  return (
    <span className={`status-badge ${config.classes} ${sizeClasses}`}>
      {label || config.label}
    </span>
  )
}
