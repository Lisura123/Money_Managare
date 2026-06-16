import { useState, useEffect, useMemo } from 'react'
import { MdRefresh, MdSchedule, MdAccessTime, MdInfoOutline, MdSave, MdAttachMoney, MdCreditCard } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ErrorState from '../../components/common/ErrorState'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import api from '../../config/api'

// "03:00" (24h) -> "03:00 AM"
function to12h(value) {
  if (!value || !value.includes(':')) return value || '—'
  const [h, m] = value.split(':').map((n) => parseInt(n, 10))
  if (isNaN(h) || isNaN(m)) return value
  const period = h >= 12 ? 'PM' : 'AM'
  const hour12 = h % 12 === 0 ? 12 : h % 12
  return `${String(hour12).padStart(2, '0')}:${String(m).padStart(2, '0')} ${period}`
}

// Toggle switch matching iOS UISwitch look
function Toggle({ checked, onChange, disabled }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      disabled={disabled}
      onClick={() => onChange(!checked)}
      className={`relative inline-flex h-6 w-11 flex-shrink-0 items-center rounded-full transition-colors disabled:opacity-50 ${
        checked ? 'bg-teal' : 'bg-gray-300 dark:bg-white/20'
      }`}
    >
      <span
        className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform ${
          checked ? 'translate-x-5' : 'translate-x-0.5'
        }`}
      />
    </button>
  )
}

export default function SettingsAdminPage() {
  const { data, loading, error, refetch } = useFetch(ENDPOINTS.SETTINGS)
  const settings = useMemo(() => (Array.isArray(data) ? data : (data?.data || [])), [data])

  const getValue = (key, fallback = '') =>
    settings.find((s) => s.key === key)?.value ?? fallback

  // Edit window state
  const [start, setStart] = useState('00:00')
  const [end, setEnd] = useState('23:59')
  const [savingWindow, setSavingWindow] = useState(false)

  // Entry access toggles
  const [cashEnabled, setCashEnabled] = useState(true)
  const [bankEnabled, setBankEnabled] = useState(true)
  const [togglingKey, setTogglingKey] = useState(null)

  useEffect(() => {
    if (settings.length === 0) return
    setStart(getValue('edit_window_start', '00:00'))
    setEnd(getValue('edit_window_end', '23:59'))
    setCashEnabled(getValue('cash_entries_enabled', '1') !== '0')
    setBankEnabled(getValue('bank_entries_enabled', '1') !== '0')
  }, [settings]) // eslint-disable-line react-hooks/exhaustive-deps

  const windowDirty =
    start !== getValue('edit_window_start', '00:00') ||
    end !== getValue('edit_window_end', '23:59')

  const saveSetting = async (key, value) => {
    await api.put(`${ENDPOINTS.SETTINGS}/${key}`, { value })
  }

  const handleSaveWindow = async () => {
    setSavingWindow(true)
    try {
      await Promise.all([
        saveSetting('edit_window_start', start),
        saveSetting('edit_window_end', end),
      ])
      toast.success('Edit window updated.')
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save window.')
    } finally {
      setSavingWindow(false)
    }
  }

  const handleToggle = async (key, next, setter) => {
    setter(next)
    setTogglingKey(key)
    try {
      await saveSetting(key, next ? '1' : '0')
      toast.success('Setting updated.')
      refetch()
    } catch (err) {
      setter(!next) // revert
      toast.error(err.response?.data?.message || 'Failed to update setting.')
    } finally {
      setTogglingKey(null)
    }
  }

  return (
    <div className="max-w-2xl space-y-6 animate-fade-in">
      <PageHeader
        title="Settings"
        action={<button onClick={refetch} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>}
      />

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && settings.length === 0 ? (
        <div className="space-y-4">
          {[1, 2].map((i) => <div key={i} className="card animate-pulse h-40 bg-gray-100 dark:bg-white/5" />)}
        </div>
      ) : (
        <>
          {/* Edit Window — matches iOS EditWindowSettingsView */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2 px-1">
              Edit Window
            </p>
            <div className="card space-y-4">
              <div className="flex items-center gap-3">
                <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center">
                  <MdSchedule className="w-5 h-5 text-teal" />
                </div>
                <div>
                  <p className="text-sm font-semibold text-navy dark:text-white">Set Window Hours</p>
                  <p className="text-xs text-gray-400 dark:text-gray-500">
                    Currently {to12h(getValue('edit_window_start'))} – {to12h(getValue('edit_window_end'))}
                  </p>
                </div>
              </div>

              <div className="flex items-end gap-3">
                <div className="flex-1">
                  <label className="text-[11px] text-gray-400 dark:text-gray-500 block mb-1">Opens at</label>
                  <input
                    type="time"
                    value={start}
                    onChange={(e) => setStart(e.target.value)}
                    className="form-input w-full"
                  />
                </div>
                <MdAccessTime className="w-5 h-5 text-gray-300 dark:text-gray-600 mb-2.5" />
                <div className="flex-1">
                  <label className="text-[11px] text-gray-400 dark:text-gray-500 block mb-1">Closes at</label>
                  <input
                    type="time"
                    value={end}
                    onChange={(e) => setEnd(e.target.value)}
                    className="form-input w-full"
                  />
                </div>
              </div>

              <div className="flex items-start gap-2 text-xs text-gray-400 dark:text-gray-500">
                <MdInfoOutline className="w-4 h-4 flex-shrink-0 mt-0.5" />
                <span>Staff can only submit and edit entries during this daily window.</span>
              </div>

              <button
                onClick={handleSaveWindow}
                disabled={!windowDirty || savingWindow}
                className="btn-primary w-full gap-1.5 disabled:opacity-40"
              >
                {savingWindow ? <LoadingSpinner size="sm" /> : <MdSave className="w-4 h-4" />}
                Save Window
              </button>
            </div>
          </div>

          {/* Staff Entry Access — matches iOS toggles */}
          <div>
            <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2 px-1">
              Staff Entry Access
            </p>
            <div className="card divide-y divide-gray-100 dark:divide-white/5 !p-0 overflow-hidden">
              <div className="flex items-center gap-3 px-4 py-4">
                <div className="w-9 h-9 rounded-lg bg-teal/10 flex items-center justify-center flex-shrink-0">
                  <MdAttachMoney className="w-5 h-5 text-teal" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-navy dark:text-white">Cash Entries</p>
                  <p className="text-xs text-gray-400 dark:text-gray-500">Allow staff to submit cash entries</p>
                </div>
                <Toggle
                  checked={cashEnabled}
                  disabled={togglingKey === 'cash_entries_enabled'}
                  onChange={(v) => handleToggle('cash_entries_enabled', v, setCashEnabled)}
                />
              </div>

              <div className="flex items-center gap-3 px-4 py-4">
                <div className="w-9 h-9 rounded-lg bg-[#6366F1]/10 flex items-center justify-center flex-shrink-0">
                  <MdCreditCard className="w-5 h-5 text-[#6366F1]" />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-navy dark:text-white">Bank Entries</p>
                  <p className="text-xs text-gray-400 dark:text-gray-500">Allow staff to submit bank entries</p>
                </div>
                <Toggle
                  checked={bankEnabled}
                  disabled={togglingKey === 'bank_entries_enabled'}
                  onChange={(v) => handleToggle('bank_entries_enabled', v, setBankEnabled)}
                />
              </div>
            </div>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-2 px-1">
              When disabled, staff cannot submit new cash or bank entries. Admins are always able to add entries.
            </p>
          </div>
        </>
      )}
    </div>
  )
}
