import { useCallback, useEffect, useState } from 'react'
import {
  MdBarChart,
  MdChevronLeft,
  MdChevronRight,
  MdCreditCard,
  MdDashboard,
  MdEditNote,
  MdHistory,
  MdListAlt,
  MdLogout,
  MdPeople,
  MdPerson,
  MdReceipt,
  MdSettings,
  MdStorefront,
  MdSwapHoriz,
  MdTune,
  MdWallet,
} from 'react-icons/md'
import { NavLink, useNavigate } from 'react-router-dom'
import toast from 'react-hot-toast'
import ConfirmDialog from '../common/ConfirmDialog'
import { useAuth } from '../../hooks/useAuth'
import { APP_NAME, ROLES } from '../../utils/constants'

const STAFF_NAV = [
  { to: '/dashboard', icon: MdDashboard, label: 'Dashboard' },
  {
    icon: MdWallet,
    label: 'Cash Entry',
    children: [
      { to: '/cash-entry/main', label: 'Main Account' },
    ],
  },
  { to: '/card-entry', icon: MdCreditCard, label: 'Bank Entry' },
  { to: '/history', icon: MdHistory, label: 'History' },
  { to: '/edit-requests', icon: MdEditNote, label: 'Edit Requests' },
  { to: '/profile', icon: MdPerson, label: 'Profile' },
]

const ADMIN_NAV = [
  { to: '/admin/dashboard', icon: MdDashboard, label: 'Dashboard' },
  { to: '/admin/showrooms', icon: MdStorefront, label: 'Showrooms' },
  { to: '/admin/staff', icon: MdPeople, label: 'Staff' },
  { to: '/admin/cash-entries', icon: MdWallet, label: 'Cash Entries' },
  { to: '/admin/card-entries', icon: MdCreditCard, label: 'Bank Entries' },
  { to: '/admin/edit-requests', icon: MdEditNote, label: 'Edit Requests', badge: true },
  { to: '/admin/self-transactions', icon: MdSwapHoriz, label: 'Self Transactions' },
  { to: '/admin/cash-transactions', icon: MdSwapHoriz, label: 'Cash Transfers' },
  { to: '/admin/cash-adjustments', icon: MdTune, label: 'Cash Adjustments' },
  { to: '/admin/card-adjustments', icon: MdTune, label: 'Bank Adjustments' },
  { to: '/admin/reports', icon: MdBarChart, label: 'Reports' },
  { to: '/admin/audit-logs', icon: MdListAlt, label: 'Audit Logs' },
  { to: '/admin/settings', icon: MdSettings, label: 'Settings' },
  { to: '/change-password', icon: MdReceipt, label: 'Change Password' },
]

export default function Sidebar({ collapsed, onToggle, mobile = false, onClose }) {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [cashOpen, setCashOpen] = useState(false)
  const [pendingCount, setPendingCount] = useState(0)
  const [showLogout, setShowLogout] = useState(false)
  const [loggingOut, setLoggingOut] = useState(false)
  const isAdmin = user?.role === ROLES.ADMIN
  const NAV_ITEMS = isAdmin ? ADMIN_NAV : STAFF_NAV

  // Poll pending edit request count for admin
  useEffect(() => {
    if (!isAdmin) return
    const fetchCount = async () => {
      try {
        const { default: api } = await import('../../config/api')
        const res = await api.get('/edit-requests/pending-count')
        setPendingCount(res.data?.count ?? 0)
      } catch { /* ignore */ }
    }
    fetchCount()
    const t = setInterval(fetchCount, 60_000)
    return () => clearInterval(t)
  }, [isAdmin])

  const handleLogout = useCallback(async () => {
    setLoggingOut(true)
    try {
      await logout()
      navigate('/login', { replace: true })
    } catch {
      toast.error('Logout failed. Please try again.')
    } finally {
      setLoggingOut(false)
      setShowLogout(false)
    }
  }, [logout, navigate])

  // Close cash submenu when sidebar collapses
  useEffect(() => {
    if (collapsed) setCashOpen(false)
  }, [collapsed])

  const initials = user?.name
    ? user.name.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase()
    : '?'

  const sidebarWidth = mobile ? 'w-64' : collapsed ? 'w-[60px]' : 'w-60'

  return (
    <>
      <aside
        className={`${sidebarWidth} flex flex-col h-full bg-navy dark:bg-navy-dark transition-all duration-300 overflow-hidden shadow-sidebar flex-shrink-0`}
      >
        {/* Top — Logo + Collapse toggle */}
        <div className="flex items-center justify-between px-4 py-5 border-b border-white/10">
          {!collapsed && (
            <div className="flex items-center gap-2 min-w-0">
              <div className="w-8 h-8 rounded-lg bg-teal flex items-center justify-center flex-shrink-0">
                <span className="text-white font-heading font-bold text-sm">M</span>
              </div>
              <span className="font-heading font-semibold text-white text-sm truncate">
                {APP_NAME}
              </span>
            </div>
          )}
          {collapsed && (
            <div className="w-8 h-8 rounded-lg bg-teal flex items-center justify-center mx-auto">
              <span className="text-white font-heading font-bold text-sm">M</span>
            </div>
          )}
          {!mobile && (
            <button
              onClick={onToggle}
              className="flex-shrink-0 p-1 rounded text-slate-400 hover:text-white hover:bg-white/10 transition-colors ml-1"
              aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            >
              {collapsed ? (
                <MdChevronRight className="w-5 h-5" />
              ) : (
                <MdChevronLeft className="w-5 h-5" />
              )}
            </button>
          )}
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-2 py-4 space-y-1 overflow-y-auto scrollbar-thin">
          {NAV_ITEMS.map((item) => {
            if (item.children) {
              // Cash Entry expandable item
              return (
                <div key={item.label}>
                  <button
                    onClick={() => {
                      if (collapsed) {
                        onToggle?.()
                      } else {
                        setCashOpen((v) => !v)
                      }
                    }}
                    className={`sidebar-nav-item w-full justify-between ${
                      collapsed ? 'justify-center px-2' : ''
                    }`}
                  >
                    <div className="flex items-center gap-3">
                      <item.icon className="w-5 h-5 flex-shrink-0" />
                      {!collapsed && <span>{item.label}</span>}
                    </div>
                    {!collapsed && (
                      <MdChevronRight
                        className={`w-4 h-4 flex-shrink-0 transition-transform ${
                          cashOpen ? 'rotate-90' : ''
                        }`}
                      />
                    )}
                  </button>
                  {cashOpen && !collapsed && (
                    <div className="mt-1 ml-5 space-y-1 pl-3 border-l-2 border-white/10">
                      {item.children.map((child) => (
                        <NavLink
                          key={child.to}
                          to={child.to}
                          onClick={mobile ? onClose : undefined}
                          className={({ isActive }) =>
                            `block py-2 px-3 rounded-lg text-xs font-medium transition-all duration-200 ${
                              isActive
                                ? 'text-teal bg-teal/10'
                                : 'text-slate-300 hover:text-white hover:bg-white/5'
                            }`
                          }
                        >
                          {child.label}
                        </NavLink>
                      ))}
                    </div>
                  )}
                </div>
              )
            }

            return (
              <NavLink
                key={item.to}
                to={item.to}
                onClick={mobile ? onClose : undefined}
                title={collapsed ? item.label : undefined}
                className={({ isActive }) =>
                  `sidebar-nav-item ${
                    isActive ? 'active' : ''
                  } ${collapsed ? 'justify-center px-2' : ''}`
                }
              >
                <item.icon className="w-5 h-5 flex-shrink-0" />
                {!collapsed && <span className="flex-1">{item.label}</span>}
                {!collapsed && item.badge && pendingCount > 0 && (
                  <span className="ml-auto bg-red-500 text-white text-[10px] font-bold rounded-full min-w-[18px] h-[18px] flex items-center justify-center px-1">
                    {pendingCount > 99 ? '99+' : pendingCount}
                  </span>
                )}
                {collapsed && item.badge && pendingCount > 0 && (
                  <span className="absolute top-1 right-1 bg-red-500 text-white text-[8px] font-bold rounded-full w-3 h-3 flex items-center justify-center">
                    !
                  </span>
                )}
              </NavLink>
            )
          })}
        </nav>

        {/* Bottom — User info + logout */}
        <div className="border-t border-white/10 px-3 py-4">
          <div className={`flex items-center ${collapsed ? 'justify-center' : 'gap-3'}`}>
            <div className="w-8 h-8 rounded-full bg-teal flex items-center justify-center flex-shrink-0">
              <span className="text-white text-xs font-semibold">{initials}</span>
            </div>
            {!collapsed && (
              <div className="flex-1 min-w-0">
                <p className="text-white text-xs font-medium truncate">{user?.name}</p>
                <p className="text-slate-400 text-xs truncate">{isAdmin ? 'Admin' : (user?.showroom?.name || 'Staff')}</p>
              </div>
            )}
            {!collapsed && (
              <button
                onClick={() => setShowLogout(true)}
                className="flex-shrink-0 p-1.5 rounded text-slate-400 hover:text-error hover:bg-red-500/10 transition-colors"
                title="Logout"
                aria-label="Logout"
              >
                <MdLogout className="w-4 h-4" />
              </button>
            )}
          </div>
          {collapsed && (
            <button
              onClick={() => setShowLogout(true)}
              className="mt-3 w-full flex justify-center p-1.5 rounded text-slate-400 hover:text-error hover:bg-red-500/10 transition-colors"
              title="Logout"
              aria-label="Logout"
            >
              <MdLogout className="w-4 h-4" />
            </button>
          )}
        </div>
      </aside>

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
