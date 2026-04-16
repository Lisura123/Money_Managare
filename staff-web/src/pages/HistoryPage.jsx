import { useCallback, useEffect, useMemo, useState } from 'react'
import Card from '../components/common/Card'
import ErrorState from '../components/common/ErrorState'
import HistoryFilters from '../components/history/HistoryFilters'
import HistoryTable from '../components/history/HistoryTable'
import Pagination from '../components/history/Pagination'
import PageHeader from '../components/common/PageHeader'
import { useFetch } from '../hooks/useFetch'
import { ENDPOINTS } from '../utils/constants'
import { formatCurrency, todayString } from '../utils/formatters'

const DEFAULT_FILTERS = {
  type: 'all',
  accountType: 'all',
  datePreset: 'month',
  from: '',
  to: '',
  search: '',
}

export default function HistoryPage() {
  const [filters, setFilters] = useState(DEFAULT_FILTERS)
  const [cashPage, setCashPage] = useState(1)
  const [cardPage, setCardPage] = useState(1)

  // Build cash query params
  const cashParams = useMemo(() => {
    if (filters.type === 'card') return null
    const p = { page: cashPage }
    if (filters.accountType && filters.accountType !== 'all') {
      p.cash_account_type = filters.accountType
    }
    if (filters.from) p.from = filters.from
    if (filters.to) p.to = filters.to
    return p
  }, [filters, cashPage])

  // Build card query params
  const cardParams = useMemo(() => {
    if (filters.type === 'cash') return null
    const p = { page: cardPage }
    if (filters.from) p.from = filters.from
    if (filters.to) p.to = filters.to
    return p
  }, [filters, cardPage])

  const {
    data: cashData,
    loading: cashLoading,
    error: cashError,
    refetch: refetchCash,
  } = useFetch(
    filters.type !== 'card' ? ENDPOINTS.CASH_ENTRIES_HISTORY : null,
    cashParams,
    [JSON.stringify(cashParams)],
  )

  const {
    data: cardData,
    loading: cardLoading,
    error: cardError,
    refetch: refetchCard,
  } = useFetch(
    filters.type !== 'cash' ? ENDPOINTS.CARD_ENTRIES_HISTORY : null,
    cardParams,
    [JSON.stringify(cardParams)],
  )

  // Merge entries for display
  const allEntries = useMemo(() => {
    const cash = (cashData?.data || []).map((e) => ({ ...e, _type: 'cash' }))
    const card = (cardData?.data || []).map((e) => ({ ...e, _type: 'card' }))

    let merged = [...cash, ...card]

    // Client-side search filter on notes
    if (filters.search.trim()) {
      const q = filters.search.toLowerCase()
      merged = merged.filter((e) =>
        e.notes?.toLowerCase().includes(q),
      )
    }

    return merged.sort(
      (a, b) => new Date(b.entry_date) - new Date(a.entry_date),
    )
  }, [cashData, cardData, filters.search])

  // Summary totals
  const totals = useMemo(() => {
    const cashTotal = allEntries
      .filter((e) => e._type === 'cash')
      .reduce((sum, e) => sum + parseFloat(e.cash_amount || 0), 0)
    const cardTotal = allEntries
      .filter((e) => e._type === 'card')
      .reduce((sum, e) => sum + parseFloat(e.amount || 0), 0)
    return { cashTotal, cardTotal, combined: cashTotal + cardTotal }
  }, [allEntries])

  // 30-second silent polling
  useEffect(() => {
    const id = setInterval(() => {
      if (filters.type !== 'card') refetchCash(true)
      if (filters.type !== 'cash') refetchCard(true)
    }, 30000)
    return () => clearInterval(id)
  }, [filters.type, refetchCash, refetchCard])

  const handleFiltersChange = useCallback((newFilters) => {
    setFilters(newFilters)
    setCashPage(1)
    setCardPage(1)
  }, [])

  const loading = cashLoading || cardLoading
  const error = cashError || cardError

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader title="History" subtitle="View and filter all your submitted entries." />

      <HistoryFilters filters={filters} onChange={handleFiltersChange} />

      {/* Summary bar */}
      {!loading && allEntries.length > 0 && (
        <div className="bg-white dark:bg-navy rounded-xl shadow-card px-4 py-3 flex flex-wrap gap-4 text-sm">
          <span className="text-gray-500 dark:text-gray-400">
            <strong className="text-gray-800 dark:text-white">{allEntries.length}</strong> entries
          </span>
          <span className="text-gray-500 dark:text-gray-400">
            Cash:{' '}
            <strong className="text-gray-800 dark:text-white">
              {formatCurrency(totals.cashTotal)}
            </strong>
          </span>
          <span className="text-gray-500 dark:text-gray-400">
            Card:{' '}
            <strong className="text-gray-800 dark:text-white">
              {formatCurrency(totals.cardTotal)}
            </strong>
          </span>
          <span className="text-gray-500 dark:text-gray-400">
            Combined:{' '}
            <strong className="text-teal">{formatCurrency(totals.combined)}</strong>
          </span>
        </div>
      )}

      {error ? (
        <ErrorState message={error} onRetry={() => { refetchCash(); refetchCard() }} />
      ) : (
        <Card padding={false}>
          <HistoryTable entries={allEntries} loading={loading} />

          {/* Pagination — show only for the active type when single type is selected */}
          {!loading && filters.type !== 'card' && cashData?.meta?.last_page > 1 && (
            <div className="border-t border-gray-100 dark:border-white/10">
              <Pagination
                currentPage={cashData.meta.current_page}
                lastPage={cashData.meta.last_page}
                onPageChange={setCashPage}
              />
            </div>
          )}
          {!loading && filters.type !== 'cash' && cardData?.meta?.last_page > 1 && (
            <div className="border-t border-gray-100 dark:border-white/10">
              <Pagination
                currentPage={cardData.meta.current_page}
                lastPage={cardData.meta.last_page}
                onPageChange={setCardPage}
              />
            </div>
          )}
        </Card>
      )}
    </div>
  )
}
