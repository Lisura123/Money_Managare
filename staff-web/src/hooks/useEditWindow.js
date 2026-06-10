import { useFetch } from './useFetch'
import { ENDPOINTS } from '../utils/constants'

/**
 * Hook that returns the edit window status from the server.
 *
 * Returns { isOpen, windowStart, windowEnd, loading }
 *  - isOpen: true when staff can submit/edit entries right now
 */
export function useEditWindow() {
  const { data, loading } = useFetch(ENDPOINTS.EDIT_WINDOW)

  return {
    isOpen: data?.is_within_window ?? false,
    windowStart: data?.edit_window_start ?? null,
    windowEnd: data?.edit_window_end ?? null,
    cashEntriesEnabled: data?.cash_entries_enabled ?? true,
    bankEntriesEnabled: data?.bank_entries_enabled ?? true,
    loading,
  }
}
