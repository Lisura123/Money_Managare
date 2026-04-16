import { MdCheckCircle, MdLock } from 'react-icons/md'
import { useNavigate } from 'react-router-dom'

export default function QuickActionCard({ icon: Icon, label, gradient, to, done = false, disabled = false }) {
  const navigate = useNavigate()

  return (
    <button
      onClick={() => !disabled && navigate(to)}
      disabled={disabled}
      className={`quick-action-card ${disabled ? 'bg-gray-300 dark:bg-gray-700 cursor-not-allowed opacity-60' : gradient} w-full text-left`}
    >
      {/* Background decoration */}
      <div className="absolute top-0 right-0 w-24 h-24 rounded-full bg-white/5 -translate-y-8 translate-x-8" />
      <div className="absolute bottom-0 left-0 w-16 h-16 rounded-full bg-black/10 translate-y-6 -translate-x-4" />

      <div className="relative flex items-start gap-4">
        <div className="w-11 h-11 rounded-xl bg-white/20 flex items-center justify-center flex-shrink-0">
          {disabled ? (
            <MdLock className="w-6 h-6 text-white" />
          ) : (
            <Icon className="w-6 h-6 text-white" />
          )}
        </div>
        <div className="flex-1 min-w-0">
          <p className="font-heading font-semibold text-base text-white leading-tight">{label}</p>
          <p className="text-xs text-white/70 mt-1">
            {disabled ? 'Closed' : done ? 'View / Edit entry' : 'Submit entry'}
          </p>
        </div>
        {done && !disabled && (
          <div className="flex-shrink-0">
            <MdCheckCircle className="w-5 h-5 text-white/90" />
          </div>
        )}
      </div>
    </button>
  )
}
