import { useState, useCallback, useEffect } from 'react'
import { MdAdd, MdEdit, MdDelete, MdEmail, MdPerson, MdToggleOn, MdToggleOff, MdVisibility, MdVisibilityOff } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { useAuth } from '../../hooks/useAuth'
import { ENDPOINTS } from '../../utils/constants'
import { prioritizeShowrooms, showroomOptionLabel } from '../../utils/showroomPriority'
import api from '../../config/api'

// ─── Staff Modal ──────────────────────────────────────────────────────────────
function StaffModal({ open, onClose, initial, showrooms, onSaved }) {
  const isEdit = !!initial?.id
  const [name, setName] = useState(initial?.name || '')
  const [email, setEmail] = useState(initial?.email || '')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [showroomIds, setShowroomIds] = useState([])
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open) {
      setName(initial?.name || '')
      setEmail(initial?.email || '')
      setPassword('')
      setShowPassword(false)
      const ids = initial?.showroom_ids?.length
        ? initial.showroom_ids.map(Number)
        : initial?.showroom_id ? [Number(initial.showroom_id)] : []
      setShowroomIds(ids)
    }
  }, [open, initial])

  const toggleShowroom = (id) => {
    setShowroomIds(prev =>
      prev.includes(id) ? prev.filter(x => x !== id) : [...prev, id]
    )
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim() || !email.trim()) return
    if (!isEdit && !password) return
    setLoading(true)
    try {
      const payload = {
        name: name.trim(),
        email: email.trim(),
        showroom_ids: showroomIds,
      }
      if (password) payload.password = password
      if (isEdit) {
        await api.put(`/staff/${initial.id}`, payload)
        toast.success('Staff member updated.')
      } else {
        await api.post('/staff', payload)
        toast.success('Staff member created. Welcome email sent.')
      }
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save staff member.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">
          {isEdit ? 'Edit Staff Member' : 'Add Staff Member'}
        </h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Full Name *</label>
            <input className="form-input" value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Kasun Perera" required />
          </div>
          <div>
            <label className="form-label">Email *</label>
            <input className="form-input" type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="kasun@example.com" required />
          </div>
          <div>
            <label className="form-label">{isEdit ? 'New Password (leave blank to keep)' : 'Password *'}</label>
            <div className="relative">
              <input
                className="form-input pr-10"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required={!isEdit}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                {showPassword ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
              </button>
            </div>
          </div>
          <div>
            <label className="form-label">Showrooms</label>
            <div className="max-h-44 overflow-y-auto space-y-1 border border-gray-200 dark:border-white/10 rounded-lg p-2">
              {prioritizeShowrooms(showrooms).map(s => (
                <label key={s.id} className="flex items-center gap-2.5 cursor-pointer hover:bg-gray-50 dark:hover:bg-white/5 rounded px-2 py-1.5 transition-colors">
                  <input
                    type="checkbox"
                    checked={showroomIds.includes(Number(s.id))}
                    onChange={() => toggleShowroom(Number(s.id))}
                    className="w-4 h-4 rounded accent-teal flex-shrink-0"
                  />
                  <span className="text-sm text-navy dark:text-white leading-tight">{showroomOptionLabel(s.name)}</span>
                </label>
              ))}
              {showrooms.length === 0 && (
                <p className="text-xs text-gray-400 px-2 py-1">No showrooms available</p>
              )}
            </div>
            {showroomIds.length === 0 && (
              <p className="text-xs text-amber-500 mt-1">No showroom selected — staff won't be assigned anywhere.</p>
            )}
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : (isEdit ? 'Update' : 'Create')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Admin Modal ─────────────────────────────────────────────────────────────
function AdminModal({ open, onClose, initial, onSaved }) {
  const isEdit = !!initial?.id
  const [name, setName] = useState(initial?.name || '')
  const [email, setEmail] = useState(initial?.email || '')
  const [password, setPassword] = useState('')
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    if (open) {
      setName(initial?.name || '')
      setEmail(initial?.email || '')
      setPassword('')
      setShowPassword(false)
    }
  }, [open, initial])

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim() || !email.trim()) return
    if (!isEdit && !password) return
    setLoading(true)
    try {
      const payload = {
        name: name.trim(),
        email: email.trim(),
      }
      if (password) payload.password = password
      if (isEdit) {
        await api.put(`/admins/${initial.id}`, payload)
        toast.success('Admin updated.')
      } else {
        await api.post('/admins', payload)
        toast.success('Admin created.')
      }
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save admin.')
    } finally {
      setLoading(false)
    }
  }

  if (!open) return null
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" onClick={onClose} />
      <div className="relative bg-white dark:bg-navy rounded-xl shadow-2xl p-6 w-full max-w-sm animate-fade-in">
        <h3 className="font-heading font-semibold text-navy dark:text-white text-base mb-4">
          {isEdit ? 'Edit Admin' : 'Add Admin'}
        </h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Full Name *</label>
            <input className="form-input" value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Pasidu Perera" required />
          </div>
          <div>
            <label className="form-label">Email *</label>
            <input className="form-input" type="email" value={email} onChange={e => setEmail(e.target.value)} placeholder="pasidu@example.com" required />
          </div>
          <div>
            <label className="form-label">{isEdit ? 'New Password (leave blank to keep)' : 'Password *'}</label>
            <div className="relative">
              <input
                className="form-input pr-10"
                type={showPassword ? 'text' : 'password'}
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                required={!isEdit}
              />
              <button
                type="button"
                onClick={() => setShowPassword(!showPassword)}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
              >
                {showPassword ? <MdVisibilityOff className="w-5 h-5" /> : <MdVisibility className="w-5 h-5" />}
              </button>
            </div>
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : (isEdit ? 'Update' : 'Create')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function StaffPage() {
  const { user: currentUser } = useAuth()
  const [tab, setTab] = useState('staff') // 'staff' or 'admins'

  const { data: staffData, loading: staffLoading, error: staffError, refetch: refetchStaff } = useFetch(ENDPOINTS.STAFF)
  const { data: adminsData, loading: adminsLoading, error: adminsError, refetch: refetchAdmins } = useFetch(ENDPOINTS.ADMINS || '/admins')
  const { data: showroomsData } = useFetch(ENDPOINTS.SHOWROOMS)

  const [modal, setModal] = useState(null)
  const [adminModal, setAdminModal] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)
  const [toggling, setToggling] = useState(null)

  const staff = Array.isArray(staffData) ? staffData : (staffData?.data || [])
  const admins = Array.isArray(adminsData) ? adminsData : (adminsData?.data || [])
  const showrooms = Array.isArray(showroomsData) ? showroomsData : (showroomsData?.data || [])

  const handleDelete = useCallback(async () => {
    if (!deleteTarget) return
    setDeleting(true)
    try {
      if (deleteTarget.role === 'admin') {
        await api.delete(`/admins/${deleteTarget.id}`)
        toast.success('Admin deleted.')
        refetchAdmins()
      } else {
        await api.delete(`/staff/${deleteTarget.id}`)
        toast.success('Staff member deleted.')
        refetchStaff()
      }
      setDeleteTarget(null)
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeleting(false)
    }
  }, [deleteTarget, refetchStaff, refetchAdmins])

  const handleToggleActive = useCallback(async (member) => {
    setToggling(member.id)
    try {
      if (member.role === 'admin') {
        await api.patch(`/admins/${member.id}/toggle-active`)
        toast.success(member.is_active ? 'Admin deactivated.' : 'Admin activated.')
        refetchAdmins()
      } else {
        await api.put(`/staff/${member.id}`, { is_active: !member.is_active })
        toast.success(member.is_active ? 'Staff member deactivated.' : 'Staff member activated.')
        refetchStaff()
      }
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to update.')
    } finally {
      setToggling(null)
    }
  }, [refetchStaff, refetchAdmins])

  const handleSendReset = useCallback(async (member) => {
    try {
      await api.post(`/staff/${member.id}/send-reset-email`)
      toast.success('Password reset email sent.')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to send email.')
    }
  }, [])

  const activeError = tab === 'staff' ? staffError : adminsError
  const activeLoading = tab === 'staff' ? staffLoading : adminsLoading
  const activeList = tab === 'staff' ? staff : admins

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="User Management"
        subtitle={tab === 'staff' ? `${staff.length} staff member${staff.length !== 1 ? 's' : ''}` : `${admins.length} admin${admins.length !== 1 ? 's' : ''}`}
        action={
          tab === 'staff' ? (
            <button onClick={() => setModal('add')} className="btn-primary flex items-center gap-2">
              <MdAdd className="w-5 h-5" /> Add Staff
            </button>
          ) : (
            <button onClick={() => setAdminModal('add')} className="btn-primary flex items-center gap-2">
              <MdAdd className="w-5 h-5" /> Add Admin
            </button>
          )
        }
      />

      <div className="flex border-b border-gray-200 dark:border-white/10 mb-4">
        <button
          onClick={() => setTab('staff')}
          className={`py-2 px-4 text-sm font-semibold border-b-2 transition-colors ${
            tab === 'staff'
              ? 'border-teal text-teal'
              : 'border-transparent text-gray-500 hover:text-navy dark:hover:text-white'
          }`}
        >
          Staff ({staff.length})
        </button>
        <button
          onClick={() => setTab('admins')}
          className={`py-2 px-4 text-sm font-semibold border-b-2 transition-colors ${
            tab === 'admins'
              ? 'border-teal text-teal'
              : 'border-transparent text-gray-500 hover:text-navy dark:hover:text-white'
          }`}
        >
          Admins ({admins.length})
        </button>
      </div>

      {activeError && <ErrorState message={activeError} onRetry={tab === 'staff' ? refetchStaff : refetchAdmins} />}

      {activeLoading && activeList.length === 0 ? (
        <div className="space-y-3">
          {[1, 2, 3].map(i => <div key={i} className="card animate-pulse h-20 bg-gray-100 dark:bg-white/5" />)}
        </div>
      ) : activeList.length === 0 ? (
        <EmptyState
          icon="MdPerson"
          title={tab === 'staff' ? "No staff members yet" : "No admin accounts yet"}
          actionLabel={tab === 'staff' ? "Add Staff" : "Add Admin"}
          onAction={() => tab === 'staff' ? setModal('add') : setAdminModal('add')}
        />
      ) : (
        <div className="space-y-2">
          {tab === 'staff' ? (
            staff.map(member => (
              <div key={member.id} className="card">
                <div className="flex items-center justify-between gap-4">
                  <div className="flex items-center gap-3 min-w-0">
                    <div className="w-10 h-10 rounded-full bg-teal/10 flex items-center justify-center flex-shrink-0">
                      <span className="text-teal font-semibold text-sm">
                        {member.name?.split(' ').map(n => n[0]).slice(0, 2).join('').toUpperCase()}
                      </span>
                    </div>
                    <div className="min-w-0">
                      <div className="flex items-center gap-2 flex-wrap">
                        <p className="font-semibold text-navy dark:text-white truncate">{member.name}</p>
                        <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full ${member.is_active ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-gray-100 text-gray-500 dark:bg-white/10 dark:text-gray-400'}`}>
                          {member.is_active ? 'Active' : 'Inactive'}
                        </span>
                      </div>
                      <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{member.email}</p>
                      {member.showrooms?.length > 0 ? (
                        <div className="flex flex-wrap gap-1 mt-0.5">
                          {member.showrooms.map(s => (
                            <span key={s.id} className="text-[10px] bg-teal/10 text-teal px-1.5 py-0.5 rounded-full">{s.name}</span>
                          ))}
                        </div>
                      ) : (
                        <p className="text-xs text-gray-400">— No showroom —</p>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center gap-1 flex-shrink-0">
                    <button onClick={() => handleToggleActive(member)} disabled={toggling === member.id} className="p-2 rounded-lg text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors" title={member.is_active ? 'Deactivate' : 'Activate'}>
                      {toggling === member.id ? <LoadingSpinner size="xs" /> : member.is_active ? <MdToggleOn className="w-5 h-5 text-teal" /> : <MdToggleOff className="w-5 h-5" />}
                    </button>
                    <button onClick={() => handleSendReset(member)} className="p-2 rounded-lg text-gray-400 hover:text-blue-500 hover:bg-blue-500/10 transition-colors" title="Send password reset email">
                      <MdEmail className="w-4 h-4" />
                    </button>
                    <button onClick={() => setModal(member)} className="p-2 rounded-lg text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors" title="Edit">
                      <MdEdit className="w-4 h-4" />
                    </button>
                    <button onClick={() => setDeleteTarget(member)} className="p-2 rounded-lg text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors" title="Delete">
                      <MdDelete className="w-4 h-4" />
                    </button>
                  </div>
                </div>
              </div>
            ))
          ) : (
            admins.map(member => {
              const isCurrentUser = member.id === currentUser?.id
              return (
                <div key={member.id} className="card">
                  <div className="flex items-center justify-between gap-4">
                    <div className="flex items-center gap-3 min-w-0">
                      <div className={`w-10 h-10 rounded-full bg-teal/10 flex items-center justify-center flex-shrink-0 ${
                        isCurrentUser ? 'ring-2 ring-teal' : ''
                      }`}>
                        <span className="text-teal font-semibold text-sm">
                          {member.name?.split(' ').map(n => n[0]).slice(0, 2).join('').toUpperCase()}
                        </span>
                      </div>
                      <div className="min-w-0">
                        <div className="flex items-center gap-2 flex-wrap">
                          <p className="font-semibold text-navy dark:text-white truncate">
                            {member.name} {isCurrentUser && <span className="text-teal text-[10px] font-medium px-1.5 py-0.5 rounded-full bg-teal/10 ml-1">You</span>}
                          </p>
                          <span className={`text-[10px] font-bold px-1.5 py-0.5 rounded-full ${member.is_active ? 'bg-green-100 text-green-700 dark:bg-green-500/20 dark:text-green-400' : 'bg-gray-100 text-gray-500 dark:bg-white/10 dark:text-gray-400'}`}>
                            {member.is_active ? 'Active' : 'Inactive'}
                          </span>
                        </div>
                        <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{member.email}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button
                        onClick={() => handleToggleActive(member)}
                        disabled={toggling === member.id || isCurrentUser}
                        className="p-2 rounded-lg text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                        title={isCurrentUser ? 'Cannot deactivate yourself' : (member.is_active ? 'Deactivate' : 'Activate')}
                      >
                        {toggling === member.id ? <LoadingSpinner size="xs" /> : member.is_active ? <MdToggleOn className="w-5 h-5 text-teal" /> : <MdToggleOff className="w-5 h-5" />}
                      </button>
                      <button
                        onClick={() => setAdminModal(member)}
                        className="p-2 rounded-lg text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors"
                        title="Edit"
                      >
                        <MdEdit className="w-4 h-4" />
                      </button>
                      <button
                        onClick={() => setDeleteTarget(member)}
                        disabled={isCurrentUser}
                        className="p-2 rounded-lg text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors disabled:opacity-30 disabled:cursor-not-allowed"
                        title={isCurrentUser ? 'Cannot delete yourself' : 'Delete'}
                      >
                        <MdDelete className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                </div>
              )
            })
          )}
        </div>
      )}

      <StaffModal
        open={!!modal}
        onClose={() => setModal(null)}
        initial={modal && modal !== 'add' ? modal : null}
        showrooms={showrooms}
        onSaved={() => { setModal(null); refetchStaff() }}
      />
      <AdminModal
        open={!!adminModal}
        onClose={() => setAdminModal(null)}
        initial={adminModal && adminModal !== 'add' ? adminModal : null}
        onSaved={() => { setAdminModal(null); refetchAdmins() }}
      />
      <ConfirmDialog
        open={!!deleteTarget}
        danger
        title={deleteTarget?.role === 'admin' ? "Delete Admin User" : "Delete Staff Member"}
        message={`Delete "${deleteTarget?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}
