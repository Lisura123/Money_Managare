import { MdBarChart, MdCreditCard, MdDashboard, MdEditNote, MdHistory, MdPerson, MdSettings, MdStorefront } from 'react-icons/md'
import { NavLink } from 'react-router-dom'
import { useAuth } from '../../hooks/useAuth'
import { ROLES } from '../../utils/constants'

const STAFF_TABS = [
  { to: '/dashboard', icon: MdDashboard, label: 'Home' },
  { to: '/history', icon: MdHistory, label: 'History' },
  { to: '/card-entry', icon: MdCreditCard, label: 'Card' },
  { to: '/edit-requests', icon: MdEditNote, label: 'Requests' },
  { to: '/profile', icon: MdPerson, label: 'Profile' },
]

const ADMIN_TABS = [
  { to: '/admin/dashboard', icon: MdDashboard, label: 'Home' },
  { to: '/admin/showrooms', icon: MdStorefront, label: 'Showrooms' },
  { to: '/admin/cash-entries', icon: MdCreditCard, label: 'Entries' },
  { to: '/admin/edit-requests', icon: MdEditNote, label: 'Requests' },
  { to: '/admin/reports', icon: MdBarChart, label: 'Reports' },
]

export default function MobileNav() {
  const { user } = useAuth()
  const TABS = user?.role === ROLES.ADMIN ? ADMIN_TABS : STAFF_TABS
  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-30 bg-white dark:bg-navy border-t border-gray-200 dark:border-white/10 flex items-stretch safe-area-inset-bottom">
      {TABS.map((tab) => (
        <NavLink
          key={tab.to}
          to={tab.to}
          className={({ isActive }) =>
            `flex-1 flex flex-col items-center justify-center gap-0.5 py-2 text-xs font-medium transition-colors ${
              isActive
                ? 'text-teal'
                : 'text-gray-500 dark:text-gray-400 hover:text-navy dark:hover:text-white'
            }`
          }
        >
          {({ isActive }) => (
            <>
              <tab.icon className={`w-5 h-5 ${isActive ? 'text-teal' : ''}`} />
              <span>{tab.label}</span>
            </>
          )}
        </NavLink>
      ))}
    </nav>
  )
}
