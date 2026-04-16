import { formatDateShort } from '../../utils/formatters'

export default function DateDisplay({ date, className = '' }) {
  return (
    <span className={`text-sm text-gray-600 dark:text-gray-400 ${className}`}>
      {formatDateShort(date)}
    </span>
  )
}
