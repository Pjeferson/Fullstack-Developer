import { ReactNode, useState } from 'react'
import { Dialog, DialogBackdrop, DialogPanel } from '@headlessui/react'

import Sidebar from '@/components/layout/Sidebar'
import Topbar from '@/components/layout/Topbar'

// Replaces the old top-nav-only AdminLayout: a fixed sidebar from the tablet breakpoint up,
// collapsing to a Headless UI Dialog drawer below it - see design.md's responsive strategy.
export default function AppShell({ children }: { children: ReactNode }) {
  const [ sidebarOpen, setSidebarOpen ] = useState(false)

  return (
    <div className="flex min-h-screen bg-background">
      <div className="hidden md:flex md:w-64 md:flex-shrink-0 md:flex-col">
        <Sidebar />
      </div>

      <Dialog open={sidebarOpen} onClose={setSidebarOpen} transition className="relative z-50 md:hidden">
        <DialogBackdrop
          transition
          className="fixed inset-0 bg-black/30 duration-200 ease-out data-[closed]:opacity-0"
        />
        <div className="fixed inset-0 flex">
          <DialogPanel
            transition
            className="w-64 duration-200 ease-out data-[closed]:-translate-x-full"
          >
            <Sidebar onNavigate={() => setSidebarOpen(false)} />
          </DialogPanel>
        </div>
      </Dialog>

      <div className="flex min-w-0 flex-1 flex-col">
        <Topbar onOpenSidebar={() => setSidebarOpen(true)} />
        <main className="flex-1 p-4 sm:p-6">{children}</main>
      </div>
    </div>
  )
}
