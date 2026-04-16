import { useCallback, useEffect, useRef, useState } from 'react'
import api from '../config/api'

/**
 * Generic data fetching hook.
 *
 * @param {string|null} url - The API endpoint. Pass null to skip fetching.
 * @param {object} params - Query params to append.
 * @param {Array} deps - Extra dependencies that trigger a refetch.
 *
 * Returns { data, loading, error, refetch }
 */
export function useFetch(url, params = {}, deps = []) {
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState(null)
  const abortRef = useRef(null)

  const fetch = useCallback(async (silent = false) => {
    if (!url) return

    // Abort any in-flight request
    if (abortRef.current) abortRef.current.abort()
    const controller = new AbortController()
    abortRef.current = controller

    if (!silent) setLoading(true)
    setError(null)

    try {
      const response = await api.get(url, {
        params,
        signal: controller.signal,
      })
      setData(response.data)
    } catch (err) {
      if (err.name === 'CanceledError' || err.name === 'AbortError') return
      setError(err.response?.data?.message || 'Failed to load data.')
    } finally {
      if (!controller.signal.aborted) setLoading(false)
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [url, JSON.stringify(params)])

  useEffect(() => {
    fetch()
    return () => abortRef.current?.abort()
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [fetch, ...deps])

  const refetch = useCallback((silent = false) => fetch(silent), [fetch])

  return { data, loading, error, refetch }
}
