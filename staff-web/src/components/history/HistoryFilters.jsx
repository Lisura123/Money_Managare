import { useCallback } from 'react'
import { MdSearch, MdClose } from 'react-icons/md'
import { todayString, thisWeekRange, thisMonthRange } from '../../utils/formatters'

const TYPE_CHIPS = [
  { value: 'all', label: 'All' },
  { value: 'cash', label: 'Cash' },
  { value: 'card', label: 'Bank' },
]

const ACCOUNT_CHIPS = [
  { value: 'all', label: 'All' },
  { value: 'main', label: 'Main' },
  { value: 'mano', label: "Mano's" },
]

const DATE_CHIPS = [
  { value: 'today', label: 'Today' },
  { value: 'week', label: 'This Week' },
  { value: 'month', label: 'This Month' },
  { value: 'custom', label: 'Custom' },
]

function Chip({ label, active, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`px-3 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-colors flex-shrink-0 ${
        active
          ? 'bg-teal text-white'
          : 'bg-gray-100 dark:bg-white/10 text-gray-600 dark:text-gray-300 hover:bg-gray-200 dark:hover:bg-white/20'
      }`}
    >
      {label}
    </button>
  )
}

export default function HistoryFilters({ filters, onChange }) {
  const handleDatePreset = useCallback(
    (preset) => {
      let from = ''
      let to = ''
      const today = todayString()

      if (preset === 'today') {
        from = today
        to = today
      } else if (preset === 'week') {
        const range = thisWeekRange()
        from = range.from
        to = range.to
      } else if (preset === 'month') {
        const range = thisMonthRange()
        from = range.from
        to = range.to
      }
      onChange({ ...filters, datePreset: preset, from, to })
    },
    [filters, onChange],
  )

  const isFiltered =
    filters.type !== 'all' ||
    (filters.type === 'cash' && filters.accountType !== 'all') ||
    filters.datePreset !== 'month' ||
    filters.search.trim()

  const handleClear = () => {
    onChange({ type: 'all', accountType: 'all', datePreset: 'month', from: '', to: '', search: '' })
  }

  return (
    <div className="space-y-2">
      {/* Type chips */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 hide-scrollbar">
        {TYPE_CHIPS.map(c => (
          <Chip key={c.value} label={c.label} active={filters.type === c.value}
            onClick={() => onChange({ ...filters, type: c.value, accountType: 'all' })} />
        ))}

        {/* Account type chips — only when Cash is selected */}
        {filters.type === 'cash' && (
          <>
            <div className="w-px h-4 bg-gray-300 dark:bg-white/20 flex-shrink-0" />
            {ACCOUNT_CHIPS.map(c => (
              <Chip key={c.value} label={c.label} active={filters.accountType === c.value}
                onClick={() => onChange({ ...filters, accountType: c.value })} />
            ))}
          </>
        )}
      </div>

      {/* Date chips */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 hide-scrollbar">
        {DATE_CHIPS.map(c => (
          <Chip key={c.value} label={c.label} active={filters.datePreset === c.value}
            onClick={() => handleDatePreset(c.value)} />
        ))}
        {isFiltered && (
          <button
            type="button"
            onClick={handleClear}
            className="px-2 py-1 rounded-full text-xs font-medium text-gray-400 hover:text-red-500 transition-colors flex items-center gap-0.5 flex-shrink-0"
          >
            <MdClose className="w-3.5 h-3.5" /> Clear
          </button>
        )}
      </div>

      {/* Custom date pickers */}
      {filters.datePreset === 'custom' && (
        <div className="flex items-center gap-2 flex-wrap">
          <input
            type="date"
            value={filters.from}
            max={filters.to || todayString()}
            onChange={e => onChange({ ...filters, from: e.target.value })}
            className="form-input w-auto text-sm"
          />
          <span className="text-gray-400 text-sm">to</span>
          <input
            type="date"
            value={filters.to}
            min={filters.from}
            max={todayString()}
            onChange={e => onChange({ ...filters, to: e.target.value })}
            className="form-input w-auto text-sm"
          />
        </div>
      )}

      {/* Search */}
      <div className="relative">
        <MdSearch className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
        <input
          type="text"
          placeholder="Search notes…"
          value={filters.search}
          onChange={e => onChange({ ...filters, search: e.target.value })}
          className="form-input pl-9 pr-8"
        />
        {filters.search && (
          <button
            type="button"
            onClick={() => onChange({ ...filters, search: '' })}
            className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
          >
            <MdClose className="w-4 h-4" />
          </button>
        )}
      </div>
    </div>
  )
}
