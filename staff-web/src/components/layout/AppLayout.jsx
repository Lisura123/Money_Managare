import { useCallback, useEffect, useRef, useState } from 'react'
import { Outlet } from 'react-router-dom'
import Header from './Header'
import MobileNav from './MobileNav'
import Sidebar from './Sidebar'

export default function AppLayout() {
  const [collapsed, setCollapsed] = useState(false)
  const [mobileOpen, setMobileOpen] = useState(false)
  const overlayRef = useRef(null)

  const openMobileSidebar = useCallback(() => setMobileOpen(true), [])
  const closeMobileSidebar = useCallback(() => setMobileOpen(false), [])
  const toggleCollapse = useCallback(() => setCollapsed((v) => !v), [])

  // Close mobile sidebar on resize to desktop
  useEffect(() => {
    const handler = () => {
      if (window.innerWidth >= 1024) setMobileOpen(false)
    }
    window.addEventListener('resize', handler)
    return () => window.removeEventListener('resize', handler)
  }, [])

  return (
    <div className="flex h-screen bg-background dark:bg-navy-900 overflow-hidden">
      {/* Desktop sidebar */}
      <div className="hidden lg:flex">
        <Sidebar collapsed={collapsed} onToggle={toggleCollapse} />
      </div>

      {/* Mobile sidebar overlay */}
      {mobileOpen && (
        <>
          <div
            ref={overlayRef}
            className="fixed inset-0 z-40 bg-black/50 backdrop-blur-sm lg:hidden"
            onClick={closeMobileSidebar}
            aria-hidden="true"
          />
          <div className="fixed left-0 top-0 bottom-0 z-50 lg:hidden animate-slide-in">
            <Sidebar mobile onClose={closeMobileSidebar} />
          </div>
        </>
      )}

      {/* Main content area */}
      <div className="flex flex-col flex-1 min-w-0 overflow-hidden">
        <Header onMenuClick={openMobileSidebar} />

        <main className="flex-1 overflow-y-auto scrollbar-thin p-4 md:p-6 pb-20 md:pb-6">
          <Outlet />
        </main>
      </div>

      {/* Mobile bottom nav */}
      <MobileNav />
    </div>
  )
}
