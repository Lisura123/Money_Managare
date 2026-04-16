import { Link } from 'react-router-dom'
import { MdChevronRight } from 'react-icons/md'
import PageHeader from '../components/common/PageHeader'
import Card from '../components/common/Card'
import StatusBadge from '../components/common/StatusBadge'
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
    <div className="max-w-md mx-auto space-y-6 animate-fade-in">
      <PageHeader title="My Profile" />

      {/* Avatar + identity card */}
      <Card>
        <div className="flex flex-col items-center text-center py-4">
          <div className="w-20 h-20 rounded-full bg-navy dark:bg-teal flex items-center justify-center mb-4 shadow-card">
            <span className="text-2xl font-bold text-white dark:text-navy">{initials}</span>
          </div>
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white mb-1">
            {user.name}
          </h2>
          <p className="text-sm text-gray-500 dark:text-gray-400 mb-3">{user.email}</p>
          <StatusBadge status="staff" label="Staff" />
        </div>

        <div className="border-t border-gray-100 dark:border-white/10 mt-4 pt-4 space-y-3">
          <ProfileRow label="Showroom" value={showroomName} />
          <ProfileRow label="Account status" value={user.is_active ? 'Active' : 'Inactive'} />
        </div>
      </Card>

      {/* Actions */}
      <Card>
        <div className="divide-y divide-gray-100 dark:divide-white/10">
          <Link
            to="/change-password"
            className="flex items-center justify-between py-3 px-1 text-sm text-gray-700 dark:text-gray-200 hover:text-navy dark:hover:text-teal transition-colors group"
          >
            <span className="font-medium">Change Password</span>
            <MdChevronRight className="w-5 h-5 opacity-50 group-hover:opacity-100 transition-opacity" />
          </Link>
        </div>
      </Card>

      {/* Logout */}
      <Card>
        <button
          onClick={() => setShowLogoutDialog(true)}
          className="btn-danger w-full"
        >
          Log Out
        </button>
      </Card>

      {/* App version */}
      <p className="text-center text-xs text-gray-400 dark:text-gray-600">
        {APP_NAME} v{APP_VERSION}
      </p>

      <ConfirmDialog
        open={showLogoutDialog}
        title="Log Out"
        message="Are you sure you want to log out?"
        confirmLabel="Log Out"
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

function ProfileRow({ label, value }) {
  return (
    <div className="flex items-center justify-between text-sm">
      <span className="text-gray-500 dark:text-gray-400">{label}</span>
      <span className="font-medium text-gray-900 dark:text-white">{value}</span>
    </div>
  )
}
