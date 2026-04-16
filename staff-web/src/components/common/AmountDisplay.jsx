import { formatCurrency } from '../../utils/formatters'

export default function AmountDisplay({ amount, className = '', size = 'md', colored = false }) {
  const sizeClasses = {
    sm: 'text-sm',
    md: 'text-base',
    lg: 'text-lg font-semibold',
    xl: 'text-2xl font-bold',
  }

  const colorClass = colored
    ? parseFloat(amount) >= 0
      ? 'text-success'
      : 'text-error'
    : ''

  return (
    <span className={`font-mono tabular-nums ${sizeClasses[size]} ${colorClass} ${className}`}>
      {formatCurrency(amount)}
    </span>
  )
}
