export default function Card({ children, className = '', padding = true }) {
  return (
    <div className={`card ${padding ? '' : '!p-0'} ${className}`}>
      {children}
    </div>
  )
}
