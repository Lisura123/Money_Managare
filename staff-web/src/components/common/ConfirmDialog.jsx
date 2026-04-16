import { useEffect, useRef } from 'react'
import { createPortal } from 'react-dom'
import { MdWarning } from 'react-icons/md'
import LoadingSpinner from './LoadingSpinner'

export default function ConfirmDialog({
  open,
  title = 'Are you sure?',
  message,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  onConfirm,
  onCancel,
  loading = false,
  danger = false,
}) {
  const cancelRef = useRef(null)

  useEffect(() => {
    if (open) {
      cancelRef.current?.focus()
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => { document.body.style.overflow = '' }
  }, [open])

  useEffect(() => {
    const handler = (e) => {
      if (e.key === 'Escape' && open) onCancel?.()
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [open, onCancel])

  if (!open) return null

  return createPortal(
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onCancel}
        aria-hidden="true"
      />

      {/* Dialog */}
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <div className="flex items-start gap-4">
          {danger && (
            <div className="flex-shrink-0 w-10 h-10 rounded-full bg-red-100 dark:bg-red-500/20 flex items-center justify-center">
              <MdWarning className="w-5 h-5 text-error" />
            </div>
          )}
          <div className="flex-1">
            <h3 className="font-heading font-semibold text-gray-900 dark:text-white text-base mb-1">
              {title}
            </h3>
            {message && (
              <p className="text-sm text-gray-600 dark:text-gray-400">{message}</p>
            )}
          </div>
        </div>

        <div className="flex gap-3 mt-6 justify-end">
          <button
            ref={cancelRef}
            onClick={onCancel}
            disabled={loading}
            className="btn-outline"
          >
            {cancelLabel}
          </button>
          <button
            onClick={onConfirm}
            disabled={loading}
            className={danger ? 'btn-danger' : 'btn-primary'}
          >
            {loading ? <LoadingSpinner size="sm" /> : confirmLabel}
          </button>
        </div>
      </div>
    </div>,
    document.body,
  )
}
