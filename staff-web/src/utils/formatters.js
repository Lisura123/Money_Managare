import { format, parseISO, isValid, startOfWeek, endOfWeek, startOfMonth, endOfMonth } from 'date-fns'

/**
 * Format a number as Sri Lankan Rupee currency.
 * e.g. 50000 → "Rs. 50,000"
 */
export function formatCurrency(amount) {
  if (amount === null || amount === undefined) return 'Rs. —'
  const num = typeof amount === 'string' ? parseFloat(amount) : amount
  if (isNaN(num)) return 'Rs. —'
  const formatted = new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(num)
  return `Rs. ${formatted}`
}

/**
 * Format a number with thousand separators only (no prefix).
 * e.g. 50000 → "50,000"
 */
export function formatNumber(amount) {
  if (amount === null || amount === undefined) return '—'
  const num = typeof amount === 'string' ? parseFloat(amount) : amount
  if (isNaN(num)) return '—'
  return new Intl.NumberFormat('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(num)
}

/**
 * Parse a formatted number string back to a number.
 * e.g. "50,000" → 50000
 */
export function parseFormattedNumber(str) {
  if (!str) return ''
  return str.replace(/,/g, '')
}

/**
 * Format a date string (YYYY-MM-DD or ISO) to a human-readable date.
 * e.g. "2026-04-13" → "April 13, 2026"
 */
export function formatDate(dateStr) {
  if (!dateStr) return '—'
  try {
    const date = typeof dateStr === 'string' && dateStr.includes('T')
      ? parseISO(dateStr)
      : new Date(dateStr + 'T00:00:00')
    if (!isValid(date)) return dateStr
    return format(date, 'MMMM d, yyyy')
  } catch {
    return dateStr
  }
}

/**
 * Format a date string to short form.
 * e.g. "2026-04-13" → "Apr 13, 2026"
 */
export function formatDateShort(dateStr) {
  if (!dateStr) return '—'
  try {
    const date = typeof dateStr === 'string' && dateStr.includes('T')
      ? parseISO(dateStr)
      : new Date(dateStr + 'T00:00:00')
    if (!isValid(date)) return dateStr
    return format(date, 'MMM d, yyyy')
  } catch {
    return dateStr
  }
}

/**
 * Format an ISO datetime string to "April 13, 2026 at 3:45 PM".
 */
export function formatDateTime(isoStr) {
  if (!isoStr) return '—'
  try {
    const date = parseISO(isoStr)
    if (!isValid(date)) return isoStr
    return format(date, "MMMM d, yyyy 'at' h:mm a")
  } catch {
    return isoStr
  }
}

/**
 * Format an ISO datetime string to "Apr 13 · 3:45 PM".
 */
export function formatDateTimeShort(isoStr) {
  if (!isoStr) return '—'
  try {
    const date = parseISO(isoStr)
    if (!isValid(date)) return isoStr
    return format(date, "MMM d · h:mm a")
  } catch {
    return isoStr
  }
}

/**
 * Get the day name for a date string.
 * e.g. "2026-04-13" → "Monday"
 */
export function getDayName(dateStr) {
  if (!dateStr) return ''
  try {
    const date = new Date(dateStr + 'T00:00:00')
    return format(date, 'EEEE')
  } catch {
    return ''
  }
}

/**
 * Get today's date string in YYYY-MM-DD format.
 */
export function todayString() {
  return format(new Date(), 'yyyy-MM-dd')
}

/**
 * Get week date range (mon–sun containing today).
 */
export function thisWeekRange() {
  const now = new Date()
  return {
    from: format(startOfWeek(now, { weekStartsOn: 1 }), 'yyyy-MM-dd'),
    to: format(endOfWeek(now, { weekStartsOn: 1 }), 'yyyy-MM-dd'),
  }
}

/**
 * Get month date range for current month.
 */
export function thisMonthRange() {
  const now = new Date()
  return {
    from: format(startOfMonth(now), 'yyyy-MM-dd'),
    to: format(endOfMonth(now), 'yyyy-MM-dd'),
  }
}

/**
 * Mask a card number to show only last 4 digits.
 * e.g. "1234" → "•••• 1234"
 */
export function maskCard(lastFour) {
  if (!lastFour) return '—'
  return `•••• ${lastFour}`
}

/**
 * Greet the user based on current hour.
 */
export function getGreeting() {
  const hour = new Date().getHours()
  if (hour < 12) return 'Good morning'
  if (hour < 17) return 'Good afternoon'
  return 'Good evening'
}

/**
 * Get a full formatted date for the dashboard header.
 * e.g. "Monday, April 13, 2026"
 */
export function getTodayLabel() {
  return format(new Date(), 'EEEE, MMMM d, yyyy')
}

/**
 * Truncate text to a maximum length with ellipsis.
 */
export function truncate(text, maxLength = 60) {
  if (!text) return ''
  if (text.length <= maxLength) return text
  return text.slice(0, maxLength) + '…'
}

/**
 * Calculate the difference between two amounts for the edit request diff display.
 */
export function calcDiff(original, requested) {
  const orig = parseFloat(original) || 0
  const req = parseFloat(requested) || 0
  const diff = req - orig
  return {
    positive: diff > 0,
    negative: diff < 0,
    same: diff === 0,
    value: Math.abs(diff),
    formatted: diff > 0
      ? `+${formatCurrency(diff)}`
      : diff < 0
        ? `-${formatCurrency(Math.abs(diff))}`
        : 'No change',
  }
}

/**
 * Convert "HH:MM" (24-hour) to "h:mm AM/PM" display.
 */
export function formatTime12h(time24) {
  if (!time24) return ''
  const [h, m] = time24.split(':').map(Number)
  const period = h >= 12 ? 'PM' : 'AM'
  const hour12 = h % 12 || 12
  return `${hour12}:${String(m).padStart(2, '0')} ${period}`
}
