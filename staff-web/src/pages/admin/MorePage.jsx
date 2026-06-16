import { MdEditNote, MdKey, MdListAlt, MdLogout, MdPeople, MdSettings } from 'react-icons/md'
import { Link, useNavigate } from 'react-router-dom'
import { useState } from 'react'
import toast from 'react-hot-toast'
import { useAuth } from '../../hooks/useAuth'
import ConfirmDialog from '../../components/common/ConfirmDialog'

function MenuItem({ to, icon: Icon, iconBg, iconColor, label }) {
  return (
    <Link
      to={to}
      className="flex items-center gap-4 px-4 py-4 hover:bg-gray-50 dark:hover:bg-white/5 transition-colors group"
    >
      <div className={`w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 ${iconBg}`}>
        <Icon className={`w-5 h-5 ${iconColor}`} />
      </div>
      <p className="flex-1 font-medium text-navy dark:text-white text-sm">{label}</p>
      <svg className="w-4 h-4 text-gray-300 dark:text-gray-600 group-hover:text-teal transition-colors flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
      </svg>
    </Link>
  )
}

function MenuGroup({ title, children }) {
  return (
    <div>
      <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2 px-1">
        {title}
      </p>
      <div className="card divide-y divide-gray-100 dark:divide-white/5 p-0 overflow-hidden">
        {children}
      </div>
    </div>
  )
}

export default function MorePage() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const [showLogout, setShowLogout] = useState(false)
  const [loggingOut, setLoggingOut] = useState(false)

  const initials = user?.name
    ? user.name.split(' ').map((n) => n[0]).slice(0, 2).join('').toUpperCase()
    : '?'

  const handleLogout = async () => {
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
  }

  return (
    <div className="max-w-lg mx-auto space-y-6">
      <h1 className="text-2xl font-heading font-bold text-navy dark:text-white">More</h1>

      <MenuGroup title="Reports & Logs">
        <MenuItem to="/admin/records"    icon={MdListAlt}  iconBg="bg-teal/10"                       iconColor="text-teal"       label="Records" />
      </MenuGroup>

      <MenuGroup title="Management">
        <MenuItem to="/admin/staff"         icon={MdPeople}   iconBg="bg-purple-50 dark:bg-purple-900/30" iconColor="text-purple-500" label="User Management" />
        <MenuItem to="/admin/edit-requests" icon={MdEditNote} iconBg="bg-rose-50 dark:bg-rose-900/30"     iconColor="text-rose-500"   label="Edit Requests" />
        <MenuItem to="/admin/settings"      icon={MdSettings} iconBg="bg-gray-100 dark:bg-white/10"       iconColor="text-gray-500"   label="Settings" />
      </MenuGroup>

      {/* Account card — mirrors iOS "Account" section */}
      <div>
        <p className="text-xs font-semibold uppercase tracking-wider text-gray-400 dark:text-gray-500 mb-2 px-1">
          Account
        </p>
        <div className="card divide-y divide-gray-100 dark:divide-white/5 p-0 overflow-hidden">
          {/* User info row */}
          <div className="flex items-center gap-4 px-4 py-4">
            <div className="w-10 h-10 rounded-full bg-teal flex items-center justify-center flex-shrink-0">
              <span className="text-white text-sm font-semibold">{initials}</span>
            </div>
            <div className="flex-1 min-w-0">
              <p className="font-semibold text-navy dark:text-white text-sm truncate">{user?.name}</p>
              <p className="text-xs text-gray-400 dark:text-gray-500 truncate">{user?.email}</p>
            </div>
          </div>

          <MenuItem to="/change-password" icon={MdKey} iconBg="bg-gray-100 dark:bg-white/10" iconColor="text-gray-500" label="Change Password" />

          {/* Sign out row */}
          <button
            onClick={() => setShowLogout(true)}
            className="w-full flex items-center gap-4 px-4 py-4 hover:bg-red-50 dark:hover:bg-red-900/10 transition-colors group"
          >
            <div className="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0 bg-red-50 dark:bg-red-900/20">
              <MdLogout className="w-5 h-5 text-error" />
            </div>
            <p className="flex-1 font-medium text-error text-sm text-left">Sign Out</p>
          </button>
        </div>
      </div>

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
    </div>
  )
}
