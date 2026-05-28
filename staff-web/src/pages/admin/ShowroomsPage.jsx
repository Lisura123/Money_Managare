import { useState, useCallback } from 'react'
import { MdAdd, MdEdit, MdDelete, MdExpandMore, MdExpandLess, MdCreditCard, MdStorefront } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import Card from '../../components/common/Card'
import EmptyState from '../../components/common/EmptyState'
import ErrorState from '../../components/common/ErrorState'
import ConfirmDialog from '../../components/common/ConfirmDialog'
import LoadingSpinner from '../../components/common/LoadingSpinner'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { formatCurrency } from '../../utils/formatters'
import api from '../../config/api'

// ─── Modal ────────────────────────────────────────────────────────────────────
function ShowroomModal({ open, onClose, initial, onSaved }) {
  const [name, setName] = useState(initial?.name || '')
  const [address, setAddress] = useState(initial?.address || '')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!name.trim()) return
    setLoading(true)
    try {
      if (initial?.id) {
        await api.put(`/showrooms/${initial.id}`, { name: name.trim(), address: address.trim() })
        toast.success('Showroom updated.')
      } else {
        await api.post('/showrooms', { name: name.trim(), address: address.trim() })
        toast.success('Showroom created.')
      }
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save showroom.')
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
          {initial?.id ? 'Edit Showroom' : 'Add Showroom'}
        </h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Name *</label>
            <input className="form-input" value={name} onChange={e => setName(e.target.value)} placeholder="e.g. Colombo 3" required />
          </div>
          <div>
            <label className="form-label">Address</label>
            <input className="form-input" value={address} onChange={e => setAddress(e.target.value)} placeholder="Optional" />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : (initial?.id ? 'Update' : 'Create')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Card Account Modal ───────────────────────────────────────────────────────
function CardAccountModal({ open, onClose, showroomId, initial, onSaved }) {
  const [bankName, setBankName] = useState(initial?.bank_name || '')
  const [lastFour, setLastFour] = useState(initial?.last_four || '')
  const [label, setLabel] = useState(initial?.label || '')
  const [openingBalance, setOpeningBalance] = useState(initial?.opening_balance || '0')
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e) => {
    e.preventDefault()
    if (!bankName.trim() || !lastFour.trim()) return
    setLoading(true)
    try {
      const payload = { bank_name: bankName.trim(), last_four: lastFour.trim(), label: label.trim(), opening_balance: parseFloat(openingBalance) || 0 }
      if (initial?.id) {
        await api.put(`/showrooms/${showroomId}/card-accounts/${initial.id}`, payload)
        toast.success('Card account updated.')
      } else {
        await api.post(`/showrooms/${showroomId}/card-accounts`, payload)
        toast.success('Card account added.')
      }
      onSaved()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to save card account.')
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
          {initial?.id ? 'Edit Card Account' : 'Add Card Account'}
        </h3>
        <form onSubmit={handleSubmit} className="space-y-3">
          <div>
            <label className="form-label">Bank Name *</label>
            <input className="form-input" value={bankName} onChange={e => setBankName(e.target.value)} placeholder="e.g. Commercial Bank" required />
          </div>
          <div>
            <label className="form-label">Last 4 Digits *</label>
            <input className="form-input" value={lastFour} onChange={e => setLastFour(e.target.value)} maxLength={4} placeholder="4567" required />
          </div>
          <div>
            <label className="form-label">Label</label>
            <input className="form-input" value={label} onChange={e => setLabel(e.target.value)} placeholder="Optional label" />
          </div>
          <div>
            <label className="form-label">Opening Balance</label>
            <input className="form-input" type="number" value={openingBalance} onChange={e => setOpeningBalance(e.target.value)} step="0.01" />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={onClose} className="btn-outline flex-1 justify-center">Cancel</button>
            <button type="submit" disabled={loading} className="btn-primary flex-1 justify-center">
              {loading ? <LoadingSpinner size="sm" /> : (initial?.id ? 'Update' : 'Add')}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

// ─── Showroom Row ─────────────────────────────────────────────────────────────
function ShowroomRow({ showroom, onEdit, onDelete, onRefresh }) {
  const [expanded, setExpanded] = useState(false)
  const [cardModal, setCardModal] = useState(null) // null | 'add' | cardObj
  const [deleteAccount, setDeleteAccount] = useState(null)
  const [deletingAccount, setDeletingAccount] = useState(false)

  const handleDeleteAccount = useCallback(async () => {
    setDeletingAccount(true)
    try {
      await api.delete(`/showrooms/${showroom.id}/card-accounts/${deleteAccount.id}`)
      toast.success('Card account deleted.')
      setDeleteAccount(null)
      onRefresh()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete.')
    } finally {
      setDeletingAccount(false)
    }
  }, [showroom.id, deleteAccount, onRefresh])

  return (
    <>
      <div className="card mb-3">
        <div className="flex items-center justify-between gap-4">
          <div className="flex items-center gap-3 min-w-0">
            <div className="w-10 h-10 rounded-xl bg-teal/10 flex items-center justify-center flex-shrink-0">
              <MdStorefront className="w-5 h-5 text-teal" />
            </div>
            <div className="min-w-0">
              <p className="font-semibold text-navy dark:text-white truncate">{showroom.name}</p>
              {showroom.address && <p className="text-xs text-gray-500 dark:text-gray-400 truncate">{showroom.address}</p>}
              <p className="text-xs text-gray-400 dark:text-gray-500">{showroom.card_accounts?.length || 0} card account(s)</p>
            </div>
          </div>
          <div className="flex items-center gap-1 flex-shrink-0">
            <button onClick={() => onEdit(showroom)} className="p-2 rounded-lg text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors" title="Edit">
              <MdEdit className="w-4 h-4" />
            </button>
            <button onClick={() => onDelete(showroom)} className="p-2 rounded-lg text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors" title="Delete">
              <MdDelete className="w-4 h-4" />
            </button>
            <button onClick={() => setExpanded(v => !v)} className="p-2 rounded-lg text-gray-400 hover:text-navy dark:hover:text-white hover:bg-gray-100 dark:hover:bg-white/10 transition-colors">
              {expanded ? <MdExpandLess className="w-4 h-4" /> : <MdExpandMore className="w-4 h-4" />}
            </button>
          </div>
        </div>

        {expanded && (
          <div className="mt-4 pt-4 border-t border-gray-200 dark:border-white/10">
            <div className="flex items-center justify-between mb-3">
              <p className="text-sm font-medium text-gray-700 dark:text-gray-300">Card Accounts</p>
              <button onClick={() => setCardModal('add')} className="btn-outline py-1 px-2 text-xs flex items-center gap-1">
                <MdAdd className="w-3.5 h-3.5" /> Add
              </button>
            </div>
            {showroom.card_accounts?.length === 0 ? (
              <p className="text-xs text-gray-400 italic">No card accounts yet.</p>
            ) : (
              <div className="space-y-2">
                {showroom.card_accounts?.map((acc) => (
                  <div key={acc.id} className="flex items-center justify-between bg-gray-50 dark:bg-white/5 rounded-lg px-3 py-2">
                    <div className="flex items-center gap-2 min-w-0">
                      <MdCreditCard className="w-4 h-4 text-gray-400 flex-shrink-0" />
                      <div className="min-w-0">
                        <p className="text-sm font-medium text-navy dark:text-white truncate">{acc.bank_name} ···{acc.last_four}</p>
                        {acc.label && <p className="text-xs text-gray-400">{acc.label}</p>}
                        <p className="text-xs text-gray-500">Balance: {formatCurrency(acc.current_balance)}</p>
                      </div>
                    </div>
                    <div className="flex items-center gap-1 flex-shrink-0">
                      <button onClick={() => setCardModal(acc)} className="p-1.5 rounded text-gray-400 hover:text-teal hover:bg-teal/10 transition-colors"><MdEdit className="w-3.5 h-3.5" /></button>
                      <button onClick={() => setDeleteAccount(acc)} className="p-1.5 rounded text-gray-400 hover:text-error hover:bg-red-500/10 transition-colors"><MdDelete className="w-3.5 h-3.5" /></button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        )}
      </div>

      <CardAccountModal
        open={!!cardModal}
        onClose={() => setCardModal(null)}
        showroomId={showroom.id}
        initial={cardModal && cardModal !== 'add' ? cardModal : null}
        onSaved={() => { setCardModal(null); onRefresh() }}
      />
      <ConfirmDialog
        open={!!deleteAccount}
        danger
        title="Delete Card Account"
        message={`Delete ${deleteAccount?.bank_name} ···${deleteAccount?.last_four}? This cannot be undone.`}
        confirmLabel="Delete"
        onConfirm={handleDeleteAccount}
        onCancel={() => setDeleteAccount(null)}
        loading={deletingAccount}
      />
    </>
  )
}

// ─── Page ─────────────────────────────────────────────────────────────────────
export default function ShowroomsPage() {
  const { data, loading, error, refetch } = useFetch(ENDPOINTS.SHOWROOMS)
  const [modal, setModal] = useState(null) // null | 'add' | showroomObj
  const [deleteTarget, setDeleteTarget] = useState(null)
  const [deleting, setDeleting] = useState(false)

  const showrooms = data?.data || []

  const handleDelete = useCallback(async () => {
    setDeleting(true)
    try {
      await api.delete(`/showrooms/${deleteTarget.id}`)
      toast.success('Showroom deleted.')
      setDeleteTarget(null)
      refetch()
    } catch (err) {
      toast.error(err.response?.data?.message || 'Failed to delete showroom.')
    } finally {
      setDeleting(false)
    }
  }, [deleteTarget, refetch])

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader
        title="Showrooms"
        subtitle={`${showrooms.length} showroom${showrooms.length !== 1 ? 's' : ''}`}
        action={
          <button onClick={() => setModal('add')} className="btn-primary flex items-center gap-2">
            <MdAdd className="w-5 h-5" /> Add Showroom
          </button>
        }
      />

      {error && <ErrorState message={error} onRetry={refetch} />}

      {loading && showrooms.length === 0 ? (
        <div className="space-y-3">
          {[1, 2, 3].map(i => <div key={i} className="card animate-pulse h-20 bg-gray-100 dark:bg-white/5" />)}
        </div>
      ) : showrooms.length === 0 ? (
        <EmptyState icon="MdStorefront" title="No showrooms yet" actionLabel="Add Showroom" onAction={() => setModal('add')} />
      ) : (
        showrooms.map(s => (
          <ShowroomRow
            key={s.id}
            showroom={s}
            onEdit={s => setModal(s)}
            onDelete={s => setDeleteTarget(s)}
            onRefresh={refetch}
          />
        ))
      )}

      <ShowroomModal
        open={!!modal}
        onClose={() => setModal(null)}
        initial={modal && modal !== 'add' ? modal : null}
        onSaved={() => { setModal(null); refetch() }}
      />
      <ConfirmDialog
        open={!!deleteTarget}
        danger
        title="Delete Showroom"
        message={`Delete "${deleteTarget?.name}"? All associated data will be removed.`}
        confirmLabel="Delete"
        onConfirm={handleDelete}
        onCancel={() => setDeleteTarget(null)}
        loading={deleting}
      />
    </div>
  )
}
