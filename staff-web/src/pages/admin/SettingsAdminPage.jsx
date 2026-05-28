import { useState, useEffect } from 'react'
import { MdSave, MdRefresh } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import api from '../../config/api'

function SettingRow({ setting, onSaved }) {
  const [value, setValue] = useState(setting.value ?? '')
  const [saving, setSaving] = useState(false)
  const dirty = value !== (setting.value ?? '')

  const handleSave = async () => {
    setSaving(true)
    try {
      await api.put(`${ENDPOINTS.SETTINGS}/${setting.id}`, { value })
      toast.success(`"${setting.label || setting.key}" updated.`)
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save.')
    } finally {
      setSaving(false)
    }
  }

  // Sync if parent data refreshes
  useEffect(() => { setValue(setting.value ?? '') }, [setting.value])

  const isTime = setting.key?.includes('time') || setting.key?.includes('window')
  const isNumber = setting.key?.includes('amount') || setting.key?.includes('limit') || setting.key?.includes('count')

  return (
    <div className="card">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <p className="text-sm font-medium text-navy dark:text-white">
            {setting.label || setting.key?.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
          </p>
          <p className="text-[11px] text-gray-400 font-mono mt-0.5">{setting.key}</p>
        </div>
      </div>
      <div className="flex items-center gap-3 mt-3">
        <input
          type={isTime ? 'time' : isNumber ? 'number' : 'text'}
          className="form-input flex-1"
          value={value}
          onChange={e => setValue(e.target.value)}
        />
        <button
          onClick={handleSave}
          disabled={!dirty || saving}
          className="btn-primary gap-1.5 disabled:opacity-40"
        >
          {saving ? <LoadingSpinner size="sm" /> : <MdSave className="w-4 h-4" />}
          Save
        </button>
      </div>
    </div>
  )
}

export default function SettingsAdminPage() {
  const { data, loading, error, refetch } = useFetch(ENDPOINTS.SETTINGS)
  const settings = Array.isArray(data) ? data : (data?.data || [])

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Settings"
        action={<button onClick={refetch} className="btn-outline p-2"><MdRefresh className="w-5 h-5" /></button>}
      />

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && settings.length === 0 ? (
        <div className="space-y-3">{[1,2,3].map(i => <div key={i} className="card animate-pulse h-24 bg-gray-100 dark:bg-white/5" />)}</div>
      ) : settings.length === 0 && !loading ? (
        <EmptyState title="No settings found" />
      ) : (
        <div className="space-y-3">
          {settings.map(s => (
            <SettingRow key={s.id} setting={s} onSaved={refetch} />
          ))}
        </div>
      )}
    </div>
  )
}
