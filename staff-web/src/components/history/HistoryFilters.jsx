import { useCallback } from 'react'
import { todayString, thisWeekRange, thisMonthRange } from '../../utils/formatters'

const TYPE_TABS = [
  { value: 'all', label: 'All' },
  { value: 'cash', label: 'Cash' },
  { value: 'card', label: 'Card' },
]

const ACCOUNT_TYPE_TABS = [
  { value: 'all', label: 'All' },
  { value: 'main', label: 'Main' },
  { value: 'mano', label: "Mano's" },
]

const DATE_PRESETS = [
  { value: 'today', label: 'Today' },
  { value: 'week', label: 'This Week' },
  { value: 'month', label: 'This Month' },
  { value: 'custom', label: 'Custom' },
]

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

  const tabBtn = (value, current, items, onSelect) =>
    items.map((item) => (
      <button
        key={item.value}
        type="button"
        onClick={() => onSelect(item.value)}
        className={`px-3 py-1.5 rounded-lg text-sm font-medium transition-colors ${
          current === item.value
            ? 'bg-navy text-white dark:bg-teal dark:text-white'
            : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5'
        }`}
      >
        {item.label}
      </button>
    ))

  return (
    <div className="bg-white dark:bg-navy rounded-xl shadow-card p-4 space-y-4">
      {/* Row 1: type + account type filters */}
      <div className="flex flex-wrap gap-4 items-center">
        <div>
          <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mb-1.5">Type</p>
          <div className="flex gap-1 bg-gray-100 dark:bg-white/5 rounded-lg p-1">
            {tabBtn(
              'type',
              filters.type,
              TYPE_TABS,
              (v) => onChange({ ...filters, type: v }),
            )}
          </div>
        </div>

        {filters.type === 'cash' && (
          <div>
            <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mb-1.5">Account</p>
            <div className="flex gap-1 bg-gray-100 dark:bg-white/5 rounded-lg p-1">
              {tabBtn(
                'accountType',
                filters.accountType,
                ACCOUNT_TYPE_TABS,
                (v) => onChange({ ...filters, accountType: v }),
              )}
            </div>
          </div>
        )}

        {/* Search */}
        <div className="flex-1 min-w-[200px]">
          <p className="text-xs text-gray-500 dark:text-gray-400 font-medium mb-1.5">Search</p>
          <input
            type="text"
            placeholder="Search notes…"
            value={filters.search}
            onChange={(e) => onChange({ ...filters, search: e.target.value })}
            className="form-input"
          />
        </div>
      </div>

      {/* Row 2: date presets */}
      <div className="flex flex-wrap gap-2 items-center">
        <p className="text-xs text-gray-500 dark:text-gray-400 font-medium">Date:</p>
        <div className="flex gap-1 bg-gray-100 dark:bg-white/5 rounded-lg p-1">
          {DATE_PRESETS.map((p) => (
            <button
              key={p.value}
              type="button"
              onClick={() => handleDatePreset(p.value)}
              className={`px-3 py-1.5 rounded-md text-sm font-medium transition-colors ${
                filters.datePreset === p.value
                  ? 'bg-navy text-white dark:bg-teal dark:text-white'
                  : 'text-gray-600 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-white/5'
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>

        {/* Custom date range inputs */}
        {filters.datePreset === 'custom' && (
          <div className="flex items-center gap-2 flex-wrap">
            <input
              type="date"
              value={filters.from}
              max={filters.to || todayString()}
              onChange={(e) => onChange({ ...filters, from: e.target.value })}
              className="form-input w-auto"
            />
            <span className="text-gray-500 dark:text-gray-400 text-sm">to</span>
            <input
              type="date"
              value={filters.to}
              min={filters.from}
              max={todayString()}
              onChange={(e) => onChange({ ...filters, to: e.target.value })}
              className="form-input w-auto"
            />
          </div>
        )}
      </div>
    </div>
  )
}
