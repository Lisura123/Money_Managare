import { MdBarChart, MdCreditCard, MdDashboard, MdEditNote, MdHistory, MdMoreHoriz, MdPerson, MdSettings, MdStorefront, MdSwapHoriz } from 'react-icons/md'
import { NavLink, useLocation } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import { ROLES } from '../../utils/constants'

const STAFF_TABS = [
  { to: '/dashboard',        icon: MdDashboard,  label: 'Dashboard' },
  { to: '/history',          icon: MdHistory,    label: 'History' },
  { to: '/card-entry',       icon: MdCreditCard, label: 'Bank' },
  { to: '/edit-requests',    icon: MdEditNote,   label: 'Requests' },
  { to: '/profile',          icon: MdPerson,     label: 'Profile' },
]

// iOS-matching: Dashboard | Entries | Transfers | Showrooms | More
const ADMIN_TABS = [
  { to: '/admin/dashboard',  icon: MdDashboard,  label: 'Dashboard' },
  { to: '/admin/entries',    icon: MdCreditCard, label: 'Entries',   matchPaths: ['/admin/entries', '/admin/cash-entries', '/admin/card-entries', '/admin/cash-adjustments', '/admin/card-adjustments'] },
  { to: '/admin/transfers',  icon: MdSwapHoriz,  label: 'Transfers', matchPaths: ['/admin/transfers', '/admin/self-transactions'] },
  { to: '/admin/showrooms',  icon: MdStorefront, label: 'Showrooms' },
  { to: '/admin/more',       icon: MdMoreHoriz,  label: 'More',      matchPaths: ['/admin/more', '/admin/records', '/admin/staff', '/admin/edit-requests', '/admin/settings', '/admin/reports', '/admin/audit-logs', '/change-password'] },
]

export default function MobileNav() {
  const { user } = useAuth()
  const location = useLocation()
  const TABS = user?.role === ROLES.ADMIN ? ADMIN_TABS : STAFF_TABS

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-30 bg-white dark:bg-navy border-t border-gray-200 dark:border-white/10 flex items-stretch safe-area-inset-bottom">
      {TABS.map((tab) => {
        const isActive = tab.matchPaths
          ? tab.matchPaths.some((p) => location.pathname.startsWith(p))
          : location.pathname === tab.to || location.pathname.startsWith(tab.to + '/')
        return (
          <NavLink
            key={tab.to}
            to={tab.to}
            className={`flex-1 flex flex-col items-center justify-center gap-0.5 py-2 text-xs font-medium transition-colors ${
              isActive ? 'text-teal' : 'text-gray-500 dark:text-gray-400 hover:text-navy dark:hover:text-white'
            }`}
          >
            <tab.icon className={`w-5 h-5 ${isActive ? 'text-teal' : ''}`} />
            <span>{tab.label}</span>
          </NavLink>
        )
      })}
    </nav>
  )
}
