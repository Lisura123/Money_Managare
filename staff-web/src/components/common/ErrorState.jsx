import { MdErrorOutline } from 'react-icons/md'

export default function ErrorState({ message = 'Something went wrong.', onRetry }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 px-6 text-center">
      <div className="w-16 h-16 rounded-full bg-red-50 dark:bg-red-500/10 flex items-center justify-center mb-4">
        <MdErrorOutline className="w-8 h-8 text-error" />
      </div>
      <p className="font-heading font-semibold text-gray-700 dark:text-gray-200 text-base mb-1">
        Failed to load
      </p>
      <p className="text-sm text-gray-500 dark:text-gray-400 max-w-xs mb-5">{message}</p>
      {onRetry && (
        <button onClick={onRetry} className="btn-danger">
          Try again
        </button>
      )}
    </div>
  )
}
