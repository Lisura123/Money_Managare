import { useState } from 'react'
import { MdDownload, MdPictureAsPdf } from 'react-icons/md'
import toast from 'react-hot-toast'
import PageHeader from '../../components/common/PageHeader'
import { useFetch } from '../../hooks/useFetch'
import { ENDPOINTS } from '../../utils/constants'
import { prioritizeShowrooms, showroomOptionLabel } from '../../utils/showroomPriority'
import api from '../../config/api'

async function downloadPdf(url, filename) {
  try {
    const res = await api.get(url, { responseType: 'blob' })
    const blob = new Blob([res.data], { type: 'application/pdf' })
    const objUrl = URL.createObjectURL(blob)
    const win = window.open(objUrl, '_blank')
    if (!win) {
      // fallback: trigger download
      const a = document.createElement('a')
      a.href = objUrl
      a.download = filename || 'report.pdf'
      a.click()
    }
    setTimeout(() => URL.revokeObjectURL(objUrl), 30000)
  } catch (err) {
    toast.error(err.response?.data?.message || 'Failed to generate report.')
  }
}

function ReportCard({ title, description, children, onGenerate, loading }) {
  return (
    <div className="card space-y-3">
      <div className="flex items-start gap-3">
        <div className="w-10 h-10 rounded-xl bg-gold/10 flex items-center justify-center flex-shrink-0">
          <MdPictureAsPdf className="w-5 h-5 text-gold" />
        </div>
        <div className="flex-1 min-w-0">
          <h3 className="font-semibold text-navy dark:text-white text-sm">{title}</h3>
          <p className="text-xs text-gray-500 dark:text-gray-400">{description}</p>
        </div>
      </div>
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">{children}</div>
      <button
        onClick={onGenerate}
        disabled={loading}
        className="btn-primary w-full justify-center gap-2"
      >
        <MdDownload className="w-4 h-4" />
        {loading ? 'Generating…' : 'Generate PDF'}
      </button>
    </div>
  )
}

export default function ReportsPage() {
  const today = new Date().toISOString().slice(0, 10)

  const { data: showroomsData } = useFetch(ENDPOINTS.SHOWROOMS)
  const showrooms = Array.isArray(showroomsData) ? showroomsData : (showroomsData?.data || [])
  // Card accounts are embedded in each showroom's card_accounts array
  const cardAccounts = showrooms.flatMap(s => (s.card_accounts || []).map(c => ({ ...c, showroomName: s.name })))

  // Daily Summary
  const [dailyFrom, setDailyFrom] = useState(today)
  const [dailyTo, setDailyTo] = useState(today)
  const [dailyLoading, setDailyLoading] = useState(false)

  // Showroom Report
  const [srShowroom, setSrShowroom] = useState('')
  const [srFrom, setSrFrom] = useState(today)
  const [srTo, setSrTo] = useState(today)
  const [srLoading, setSrLoading] = useState(false)

  // Card Statement
  const [csCard, setCsCard] = useState('')
  const [csFrom, setCsFrom] = useState(today)
  const [csTo, setCsTo] = useState(today)
  const [csLoading, setCsLoading] = useState(false)

  // Self Transactions
  const [stFrom, setStFrom] = useState(today)
  const [stTo, setStTo] = useState(today)
  const [stLoading, setStLoading] = useState(false)

  // Adjustments
  const [adjFrom, setAdjFrom] = useState(today)
  const [adjTo, setAdjTo] = useState(today)
  const [adjLoading, setAdjLoading] = useState(false)

  const buildParams = (obj) => '?' + Object.entries(obj).filter(([,v]) => v).map(([k,v]) => `${k}=${encodeURIComponent(v)}`).join('&')

  const handleDaily = async () => {
    setDailyLoading(true)
    await downloadPdf(`/reports/pdf/daily-summary${buildParams({ from: dailyFrom, to: dailyTo })}`, `daily-summary-${dailyFrom}.pdf`)
    setDailyLoading(false)
  }

  const handleShowroom = async () => {
    if (!srShowroom) { toast.error('Select a showroom.'); return }
    setSrLoading(true)
    await downloadPdf(`/reports/pdf/showroom${buildParams({ showroom_id: srShowroom, from: srFrom, to: srTo })}`, `showroom-report.pdf`)
    setSrLoading(false)
  }

  const handleCard = async () => {
    if (!csCard) { toast.error('Select a card account.'); return }
    setCsLoading(true)
    await downloadPdf(`/reports/pdf/card-statement${buildParams({ card_account_id: csCard, from: csFrom, to: csTo })}`, `card-statement.pdf`)
    setCsLoading(false)
  }

  const handleSelfTx = async () => {
    setStLoading(true)
    await downloadPdf(`/reports/pdf/self-transactions${buildParams({ from: stFrom, to: stTo })}`, `self-transactions.pdf`)
    setStLoading(false)
  }

  const handleAdj = async () => {
    setAdjLoading(true)
    await downloadPdf(`/reports/pdf/adjustments${buildParams({ from: adjFrom, to: adjTo })}`, `adjustments.pdf`)
    setAdjLoading(false)
  }

  const inputClass = 'form-input text-sm'
  const labelClass = 'form-label text-xs'

  return (
    <div className="space-y-4 animate-fade-in">
      <PageHeader title="Reports" />

      {/* Daily Summary */}
      <ReportCard
        title="Daily Summary"
        description="Full daily summary of all showrooms for a date range."
        onGenerate={handleDaily}
        loading={dailyLoading}
      >
        <div>
          <label className={labelClass}>From</label>
          <input type="date" className={inputClass} value={dailyFrom} onChange={e => setDailyFrom(e.target.value)} />
        </div>
        <div>
          <label className={labelClass}>To</label>
          <input type="date" className={inputClass} value={dailyTo} onChange={e => setDailyTo(e.target.value)} />
        </div>
      </ReportCard>

      {/* Showroom Report */}
      <ReportCard
        title="Showroom Report"
        description="Cash and card entries for a specific showroom."
        onGenerate={handleShowroom}
        loading={srLoading}
      >
        <div className="col-span-2 sm:col-span-3">
          <label className={labelClass}>Showroom</label>
          <select className={inputClass} value={srShowroom} onChange={e => setSrShowroom(e.target.value)}>
            <option value="">Select showroom</option>
            {prioritizeShowrooms(showrooms).map(s => <option key={s.id} value={s.id}>{showroomOptionLabel(s.name)}</option>)}
          </select>
        </div>
        <div>
          <label className={labelClass}>From</label>
          <input type="date" className={inputClass} value={srFrom} onChange={e => setSrFrom(e.target.value)} />
        </div>
        <div>
          <label className={labelClass}>To</label>
          <input type="date" className={inputClass} value={srTo} onChange={e => setSrTo(e.target.value)} />
        </div>
      </ReportCard>

      {/* Card Statement */}
      <ReportCard
        title="Bank Statement"
        description="Bank transactions for a specific bank account."
        onGenerate={handleCard}
        loading={csLoading}
      >
        <div className="col-span-2 sm:col-span-3">
          <label className={labelClass}>Bank Account</label>
          <select className={inputClass} value={csCard} onChange={e => setCsCard(e.target.value)}>
            <option value="">Select card account</option>
            {cardAccounts.map(c => <option key={c.id} value={c.id}>{c.bank_name} ···{c.last_four}{c.label ? ` (${c.label})` : ''}{c.showroomName ? ` — ${c.showroomName}` : ''}</option>)}
          </select>
        </div>
        <div>
          <label className={labelClass}>From</label>
          <input type="date" className={inputClass} value={csFrom} onChange={e => setCsFrom(e.target.value)} />
        </div>
        <div>
          <label className={labelClass}>To</label>
          <input type="date" className={inputClass} value={csTo} onChange={e => setCsTo(e.target.value)} />
        </div>
      </ReportCard>

      {/* Self Transactions */}
      <ReportCard
        title="Self Transactions"
        description="Report of all self transactions (cash in/out by admin)."
        onGenerate={handleSelfTx}
        loading={stLoading}
      >
        <div>
          <label className={labelClass}>From</label>
          <input type="date" className={inputClass} value={stFrom} onChange={e => setStFrom(e.target.value)} />
        </div>
        <div>
          <label className={labelClass}>To</label>
          <input type="date" className={inputClass} value={stTo} onChange={e => setStTo(e.target.value)} />
        </div>
      </ReportCard>

      {/* Adjustments */}
      <ReportCard
        title="Adjustments"
        description="Report of all manual adjustments made to entries."
        onGenerate={handleAdj}
        loading={adjLoading}
      >
        <div>
          <label className={labelClass}>From</label>
          <input type="date" className={inputClass} value={adjFrom} onChange={e => setAdjFrom(e.target.value)} />
        </div>
        <div>
          <label className={labelClass}>To</label>
          <input type="date" className={inputClass} value={adjTo} onChange={e => setAdjTo(e.target.value)} />
        </div>
      </ReportCard>
    </div>
  )
}
