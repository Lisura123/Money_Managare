import { Link } from 'react-router-dom'
import { MdChevronRight, MdKey, MdAccessTime, MdEditNote } from 'react-icons/md'
import PageHeader from '../components/common/PageHeader'
import Card from '../components/common/Card'
import ConfirmDialog from '../components/common/ConfirmDialog'
import { useAuth } from '../hooks/useAuth'
import { APP_VERSION, APP_NAME } from '../utils/constants'
import { useState } from 'react'

export default function ProfilePage() {
  const { user, logout } = useAuth()
  const [showLogoutDialog, setShowLogoutDialog] = useState(false)

  if (!user) return null

  const initials = user.name
    .split(' ')
    .slice(0, 2)
    .map((n) => n[0])
    .join('')
    .toUpperCase()

  const showroomName = user.showroom?.name || '—'

  return (
    <div className="max-w-md mx-auto space-y-4 animate-fade-in">
      <PageHeader title="My Profile" />

      {/* User Info */}
      <Card>
        <div className="flex items-center gap-4">
          <div className="w-16 h-16 rounded-full bg-navy dark:bg-teal flex items-center justify-center flex-shrink-0 shadow-card">
            <span className="text-xl font-bold text-white dark:text-navy">{initials}</span>
          </div>
          <div className="min-w-0">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{user.name}</h2>
            <p className="text-sm text-gray-500 dark:text-gray-400">{user.email}</p>
            <p className="text-xs text-gray-400 dark:text-gray-500 mt-0.5">{showroomName}</p>
          </div>
        </div>
      </Card>

      {/* Account */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2 px-1">Account</p>
        <Card>
          <div className="divide-y divide-gray-100 dark:divide-white/10">
            <NavRow icon={MdKey} label="Change Password" to="/change-password" />
          </div>
        </Card>
      </div>

      {/* Edit Requests */}
      <div>
        <p className="text-xs font-semibold text-gray-500 dark:text-gray-400 uppercase tracking-wide mb-2 px-1">Edit Requests</p>
        <Card>
          <div className="divide-y divide-gray-100 dark:divide-white/10">
            <NavRow icon={MdEditNote} label="My Edit Requests" to="/edit-requests" />
            <NavRow icon={MdAccessTime} label="Edit Window" to="/edit-window" />
          </div>
        </Card>
      </div>

      {/* Sign Out */}
      <Card>
        <button
          onClick={() => setShowLogoutDialog(true)}
          className="btn-danger w-full"
        >
          Sign Out
        </button>
      </Card>

      {/* App version */}
      <p className="text-center text-xs text-gray-400 dark:text-gray-600">
        {APP_NAME} v{APP_VERSION}
      </p>

      <ConfirmDialog
        open={showLogoutDialog}
        title="Sign Out"
        message="Are you sure you want to sign out?"
        confirmLabel="Sign Out"
        onConfirm={() => {
          setShowLogoutDialog(false)
          logout()
        }}
        onCancel={() => setShowLogoutDialog(false)}
        danger
      />
    </div>
  )
}

function NavRow({ icon: Icon, label, to }) {
  return (
    <Link
      to={to}
      className="flex items-center justify-between py-3 px-1 text-sm text-gray-700 dark:text-gray-200 hover:text-navy dark:hover:text-teal transition-colors group"
    >
      <div className="flex items-center gap-2.5">
        <Icon className="w-4 h-4 text-gray-400 group-hover:text-teal transition-colors" />
        <span className="font-medium">{label}</span>
      </div>
      <MdChevronRight className="w-5 h-5 opacity-40 group-hover:opacity-100 transition-opacity" />
    </Link>
  )
}
