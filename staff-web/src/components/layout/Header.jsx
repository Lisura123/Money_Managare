import { useCallback, useState } from 'react'
import { MdChevronRight, MdLogout, MdMenu, MdPerson, MdVpnKey } from 'react-icons/md'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import ConfirmDialog from '../common/ConfirmDialog'
import { useAuth } from '../../hooks/useAuth'

// Build breadcrumb label from pathname
function useBreadcrumb() {
  const location = useLocation()
  const segments = location.pathname.split('/').filter(Boolean)

  const labels = {
    dashboard: 'Dashboard',
    'cash-entry': 'Cash Entry',
    main: 'Main Account',
    mano: "Mano's Account",
    'card-entry': 'Card Entry',
    history: 'History',
    'edit-requests': 'Edit Requests',
    'my-edit-requests': 'My Edit Requests',
    'edit-request': 'Edit Request',
    profile: 'Profile',
    'change-password': 'Change Password',
  }

  return segments.map((seg, idx) => ({
    label: labels[seg] || seg.replace(/-/g, ' '),
    to: '/' + segments.slice(0, idx + 1).join('/'),
    isLast: idx === segments.length - 1,
  }))
}

export default function Header({ onMenuClick }) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const breadcrumbs = useBreadcrumb()
  const [dropdownOpen, setDropdownOpen] = useState(false)
  const [showLogout, setShowLogout] = useState(false)
  const [loggingOut, setLoggingOut] = useState(false)

  const initials = user?.name
    ? user.name.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase()
    : '?'

  const handleLogout = useCallback(async () => {
    setLoggingOut(true)
    try {
      await logout()
      navigate('/login', { replace: true })
    } catch {
      toast.error('Logout failed.')
    } finally {
      setLoggingOut(false)
      setShowLogout(false)
    }
  }, [logout, navigate])

  return (
    <>
      <header className="h-16 bg-white dark:bg-navy border-b border-gray-200 dark:border-white/10 flex items-center px-4 gap-4 flex-shrink-0 shadow-sm">
        {/* Hamburger (tablet/mobile) */}
        <button
          onClick={onMenuClick}
          className="lg:hidden p-2 rounded-lg text-gray-500 hover:bg-gray-100 dark:hover:bg-white/5 transition-colors"
          aria-label="Open menu"
        >
          <MdMenu className="w-6 h-6" />
        </button>

        {/* Breadcrumb (desktop) */}
        <nav className="hidden lg:flex items-center gap-1 text-sm flex-1" aria-label="Breadcrumb">
          {breadcrumbs.map((crumb, i) => (
            <span key={crumb.to} className="flex items-center gap-1">
              {i > 0 && <MdChevronRight className="w-4 h-4 text-gray-400" />}
              {crumb.isLast ? (
                <span className="font-medium text-gray-800 dark:text-gray-200">{crumb.label}</span>
              ) : (
                <Link
                  to={crumb.to}
                  className="text-gray-500 hover:text-navy dark:text-gray-400 dark:hover:text-white capitalize transition-colors"
                >
                  {crumb.label}
                </Link>
              )}
            </span>
          ))}
        </nav>

        <div className="flex-1 lg:flex-none" />

        {/* User menu */}
        <div className="relative">
          <button
            onClick={() => setDropdownOpen((v) => !v)}
            className="flex items-center gap-2.5 p-1.5 rounded-lg hover:bg-gray-50 dark:hover:bg-white/5 transition-colors"
          >
            <div className="w-8 h-8 rounded-full bg-navy dark:bg-teal flex items-center justify-center">
              <span className="text-white text-xs font-semibold">{initials}</span>
            </div>
            <div className="hidden md:block text-left">
              <p className="text-sm font-medium text-gray-800 dark:text-gray-200 leading-none">
                {user?.name}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400 mt-0.5">
                {user?.showroom?.name || 'Staff'}
              </p>
            </div>
            <MdChevronRight
              className={`hidden md:block w-4 h-4 text-gray-400 transition-transform ${
                dropdownOpen ? 'rotate-90' : ''
              }`}
            />
          </button>

          {dropdownOpen && (
            <>
              <div
                className="fixed inset-0 z-30"
                onClick={() => setDropdownOpen(false)}
                aria-hidden="true"
              />
              <div className="absolute right-0 top-full mt-2 w-48 bg-white dark:bg-navy-light rounded-xl shadow-xl border border-gray-100 dark:border-white/10 z-40 overflow-hidden animate-fade-in">
                <Link
                  to="/profile"
                  onClick={() => setDropdownOpen(false)}
                  className="flex items-center gap-3 px-4 py-3 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors"
                >
                  <MdPerson className="w-4 h-4" />
                  Profile
                </Link>
                <Link
                  to="/change-password"
                  onClick={() => setDropdownOpen(false)}
                  className="flex items-center gap-3 px-4 py-3 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors"
                >
                  <MdVpnKey className="w-4 h-4" />
                  Change Password
                </Link>
                <hr className="border-gray-100 dark:border-white/10" />
                <button
                  onClick={() => {
                    setDropdownOpen(false)
                    setShowLogout(true)
                  }}
                  className="w-full flex items-center gap-3 px-4 py-3 text-sm text-error hover:bg-red-50 dark:hover:bg-red-500/10 transition-colors"
                >
                  <MdLogout className="w-4 h-4" />
                  Sign out
                </button>
              </div>
            </>
          )}
        </div>
      </header>

      <ConfirmDialog
        open={showLogout}
        title="Sign out"
        message="Are you sure you want to sign out?"
        confirmLabel="Sign out"
        cancelLabel="Cancel"
        onConfirm={handleLogout}
        onCancel={() => setShowLogout(false)}
        loading={loggingOut}
        danger
      />
    </>
  )
}
