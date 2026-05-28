import { useState, useCallback } from 'react'
import { MdAdd, MdEdit, MdDelete, MdEmail, MdPerson, MdToggleOn, MdToggleOff } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import ErrorState from '../../components/common/ErrorState'
import EmptyState from '../../components/common/EmptyState'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import StatusBadge from '../../components/common/StatusBadge'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import api from '../../config/api'

// ─── Staff Modal ──────────────────────────────────────────────────────────────
function StaffModal({ open, onClose, initial, showrooms, onSaved }) {
  const isEdit = !!initial?.id
  const [name, setName] = useState(initial?.name || '')
  const [email, setEmail] = useState(initial?.email || '')
  const [password, setPassword] = useState('')
  const [showroomId, setShowroomId] = useState(initial?.showroom_id || initial?.showroom?.id || '')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim() || !email.trim()) return
    if (!isEdit && !password) return
    setLoading(true)
    try {
      const payload = { name: name.trim(), email: email.trim(), showroom_id: showroomId || null }
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
            <input className="form-input" type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••" required={!isEdit} />
          </div>
          <div>
            <label className="form-label">Showroom</label>
            <select className="form-input" value={showroomId} onChange={e => setShowroomId(e.target.value)}>
              <option value="">— None —</option>
              {showrooms.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
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
  const { data, loading, error, refetch } = useFetch(ENDPOINTS.STAFF)
  const { data: showroomsData } = useFetch(ENDPOINTS.SHOWROOMS)
  const [modal, setModal] = useState(null)
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)
  const [toggling, setToggling] = useState(null)

  const staff = data?.data || []
  const showrooms = showroomsData?.data || []

  const handleDelete = useCallback(async () => {
    setDeleting(true)
    try {
      await api.delete(`/staff/${deleteTarget.id}`)
      toast.success('Staff member deleted.')
      setDeleteTarget(null)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeleting(false)
    }
  }, [deleteTarget, refetch])

  const handleToggleActive = useCallback(async (member) => {
    setToggling(member.id)
    try {
      await api.put(`/staff/${member.id}`, { is_active: !member.is_active })
      toast.success(member.is_active ? 'Staff member deactivated.' : 'Staff member activated.')
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to update.')
    } finally {
      setToggling(null)
    }
  }, [refetch])

  const handleSendReset = useCallback(async (member) => {
    try {
      await api.post(`/staff/${member.id}/send-reset-email`)
      toast.success('Password reset email sent.')
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to send email.')
    }
  }, [])

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Staff"
        subtitle={`${staff.length} member${staff.length !== 1 ? 's' : ''}`}
        action={
          <button onClick={() => setModal('add')} className="btn-primary flex items-center gap-2">
            <MdAdd className="w-5 h-5" /> Add Staff
          </button>
        }
      />

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && staff.length === 0 ? (
        <div className="space-y-3">
          {[1, 2, 3].map(i => <div key={i} className="card animate-pulse h-20 bg-gray-100 dark:bg-white/5" />)}
        </div>
      ) : staff.length === 0 ? (
        <EmptyState icon="MdPerson" title="No staff members yet" actionLabel="Add Staff" onAction={() => setModal('add')} />
      ) : (
        <div className="space-y-2">
          {staff.map(member => (
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
                    <p className="text-xs text-gray-400">{member.showroom?.name || '— No showroom —'}</p>
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
          ))}
        </div>
      )}

      <StaffModal
        open={!!modal}
        onClose={() => setModal(null)}
        initial={modal && modal !== 'add' ? modal : null}
        showrooms={showrooms}
        onSaved={() => { setModal(null); refetch() }}
      />
      <ConfirmDialog
        open={!!deleteTarget}
        danger
        title="Delete Staff Member"
        message={`Delete "${deleteTarget?.name}"? This cannot be undone.`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}
