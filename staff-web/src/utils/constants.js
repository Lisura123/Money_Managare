// API endpoint constants
export const ENDPOINTS = {
  // Auth
  LOGIN: '/login',
  LOGOUT: '/logout',
  FORGOT_PASSWORD: '/forgot-password',
  RESET_PASSWORD: '/reset-password',
  CHANGE_PASSWORD: '/change-password',

  // Staff
  TODAY_STATUS: '/today-status',
  EDIT_WINDOW: '/edit-window',
  CASH_ENTRIES: '/cash-entries',
  CASH_ENTRIES_HISTORY: '/cash-entries/my-history',
  CARD_ENTRIES: '/card-entries',
  CARD_ENTRIES_HISTORY: '/card-entries/my-history',
  MY_CARD_ACCOUNTS: '/my-card-accounts',
  EDIT_REQUESTS: '/edit-requests',
  MY_EDIT_REQUESTS: '/edit-requests/my-requests',
}

export const ROLES = {
  STAFF: 'staff',
  ADMIN: 'admin',
}

export const ENTRY_TYPES = {
  CASH: 'cash',
  CARD: 'card',
}

export const ACCOUNT_TYPES = {
  MAIN: 'main',
  MANO: 'mano',
}

export const ACCOUNT_TYPE_LABELS = {
  main: 'Main Account',
  mano: "Mano's Account",
}

export const STATUS_LABELS = {
  pending: 'Pending',
  approved: 'Approved',
  rejected: 'Rejected',
}

export const EDIT_REQUEST_REASONS = [
  'Wrong amount entered',
  'Forgot to include a sale',
  'Duplicate correction',
  'Other',
]

export const QUICK_AMOUNTS = [10000, 25000, 50000, 100000]

export const DATE_FILTER_OPTIONS = [
  { label: 'Today', value: 'today' },
  { label: 'This Week', value: 'week' },
  { label: 'This Month', value: 'month' },
  { label: 'Custom Range', value: 'custom' },
]

export const APP_VERSION = import.meta.env.VITE_APP_VERSION || '1.0.0'
export const APP_NAME = import.meta.env.VITE_APP_NAME || 'Money Manager'
