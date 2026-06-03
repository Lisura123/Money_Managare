import { MdAccessTime, MdLock, MdLockOpen } from 'react-icons/md'
import PageHeader from '../components/common/PageHeader'
import Card from '../components/common/Card'
import LoadingSpinner from '../components/common/LoadingSpinner'
import { useEditWindow } from '../hooks/useEditWindow'
import { formatTime12h } from '../utils/formatters'

export default function EditWindowPage() {
  const { isOpen, windowStart, windowEnd, loading } = useEditWindow()

  return (
    <div className="max-w-md mx-auto space-y-4 animate-fade-in">
      <PageHeader title="Edit Window" subtitle="Entry submission window status." />

      {loading ? (
        <div className="flex justify-center py-12"><LoadingSpinner /></div>
      ) : (
        <Card>
          <div className="flex flex-col items-center py-6 text-center gap-4">
            <div className={`w-16 h-16 rounded-full flex items-center justify-center ${
              isOpen
                ? 'bg-green-100 dark:bg-green-500/20'
                : 'bg-red-100 dark:bg-red-500/20'
            }`}>
              {isOpen
                ? <MdLockOpen className="w-8 h-8 text-green-600 dark:text-green-400" />
                : <MdLock className="w-8 h-8 text-red-500 dark:text-red-400" />
              }
            </div>

            <div>
              <p className={`text-xl font-bold ${isOpen ? 'text-green-600 dark:text-green-400' : 'text-red-500 dark:text-red-400'}`}>
                {isOpen ? 'Open' : 'Closed'}
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-1">
                Entries can be submitted between
              </p>
            </div>

            {windowStart && windowEnd && (
              <div className="bg-gray-50 dark:bg-white/5 rounded-xl px-6 py-4 w-full">
                <div className="flex items-center justify-center gap-4">
                  <div className="text-center">
                    <p className="text-xs text-gray-400 mb-1">Opens</p>
                    <p className="text-base font-bold text-navy dark:text-white">{formatTime12h(windowStart)}</p>
                  </div>
                  <MdAccessTime className="w-5 h-5 text-gray-300 dark:text-gray-600" />
                  <div className="text-center">
                    <p className="text-xs text-gray-400 mb-1">Closes</p>
                    <p className="text-base font-bold text-navy dark:text-white">{formatTime12h(windowEnd)}</p>
                  </div>
                </div>
              </div>
            )}
          </div>
        </Card>
      )}
    </div>
  )
}
