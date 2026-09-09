import { ReactNode, useState } from 'react'
import { Dialog, DialogBackdrop, DialogPanel } from '@headlessui/react'

import Sidebar from '@/components/layout/Sidebar'
import Topbar from '@/components/layout/Topbar'

// Replaces the old top-nav-only AdminLayout: a fixed sidebar from the tablet breakpoint up,
// collapsing to a Headless UI Dialog drawer below it - see design.md's responsive strategy.
//
// The outer container is `h-screen overflow-hidden`, not `min-h-screen` - only <main> scrolls
// (`overflow-y-auto`). With `min-h-screen`, the whole page grew to match content height, and a
// flex row's items stretch to the tallest sibling by default, so the sidebar grew right along
// with it - on a long infinite-scrolled list, its bottom (My profile/Sign out) ended up far
// below the viewport, effectively unreachable. Pinning the shell to the viewport and scrolling
// only the content region is the standard app-shell layout for exactly this reason.
export default function AppShell({ children }: { children: ReactNode }) {
  const [ sidebarOpen, setSidebarOpen ] = useState(false)

  return (
    <div className="flex h-screen overflow-hidden bg-background">
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

      <div className="flex min-w-0 flex-1 flex-col overflow-hidden">
        <Topbar onOpenSidebar={() => setSidebarOpen(true)} />
        <main className="flex-1 overflow-y-auto p-4 sm:p-6">{children}</main>
      </div>
    </div>
  )
}
