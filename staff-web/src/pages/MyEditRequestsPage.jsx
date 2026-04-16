import { useEffect, useState } from 'react'
import { MdInbox } from 'react-icons/md'
import PageHeader from '../components/common/PageHeader'
import LoadingSpinner from '../components/common/LoadingSpinner'
import ErrorState from '../components/common/ErrorState'
import EmptyState from '../components/common/EmptyState'
import EditRequestCard from '../components/editRequests/EditRequestCard'
import EditRequestTimeline from '../components/editRequests/EditRequestTimeline'
import { useFetch } from '../hooks/useFetch'
import { ENDPOINTS } from '../utils/constants'

const STATUS_TABS = [
  { value: '', label: 'All' },
  { value: 'pending', label: 'Pending' },
  { value: 'approved', label: 'Approved' },
  { value: 'rejected', label: 'Rejected' },
]

export default function MyEditRequestsPage() {
  const [activeTab, setActiveTab] = useState('')

  const { data, loading, error, refetch } = useFetch(ENDPOINTS.MY_EDIT_REQUESTS)

  // 30-second silent polling
  useEffect(() => {
    const id = setInterval(() => refetch(true), 30000)
    return () => clearInterval(id)
  }, [refetch])

  const allRequests = data?.data || data || []
  const filtered =
    activeTab === ''
      ? allRequests
      : allRequests.filter((r) => r.status === activeTab)

  return (
    <div className="space-y-6 animate-fade-in">
      <PageHeader
        title="My Edit Requests"
        subtitle="Track all correction requests you've submitted."
      />

      {/* Status tabs */}
      <div className="flex gap-2 flex-wrap">
        {STATUS_TABS.map((tab) => {
          const count =
            tab.value === ''
              ? allRequests.length
              : allRequests.filter((r) => r.status === tab.value).length
          return (
            <button
              key={tab.value}
              onClick={() => setActiveTab(tab.value)}
              className={`px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${
                activeTab === tab.value
                  ? 'bg-navy text-white dark:bg-teal dark:text-navy'
                  : 'bg-gray-100 dark:bg-white/10 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-white/20'
              }`}
            >
              {tab.label}
              <span className="ml-1.5 text-xs opacity-75">({count})</span>
            </button>
          )
        })}
      </div>

      {/* Content */}
      {loading ? (
        <div className="flex justify-center py-16">
          <LoadingSpinner size="lg" />
        </div>
      ) : error ? (
        <ErrorState message={error} onRetry={refetch} />
      ) : filtered.length === 0 ? (
        <EmptyState
          icon={MdInbox}
          title="No edit requests found"
          message={
            activeTab
              ? `You have no ${activeTab} requests.`
              : "You haven't submitted any edit requests yet."
          }
        />
      ) : (
        <>
          {/* Desktop: card list */}
          <div className="hidden lg:block space-y-4">
            {filtered.map((request) => (
              <EditRequestCard
                key={request.id}
                request={request}
                onCancelled={refetch}
              />
            ))}
          </div>

          {/* Mobile: timeline */}
          <div className="lg:hidden">
            <EditRequestTimeline requests={filtered} onCancelled={refetch} />
          </div>
        </>
      )}
    </div>
  )
}
