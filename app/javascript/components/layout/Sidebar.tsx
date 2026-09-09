import { Link, router, usePage } from '@inertiajs/react'
import { LayoutDashboard, LogOut, Upload, User, Users } from 'lucide-react'

type NavItem = {
  href: string
  label: string
  icon: typeof Users
}

// No separate "Dashboard" nav item - /admin/users already is the dashboard (stats on top,
// list below), so a distinct Dashboard page would just be a second link to the same place.
const NAV_ITEMS: NavItem[] = [
  { href: '/admin/users', label: 'Users', icon: Users },
  { href: '/admin/spreadsheet_imports', label: 'Imports', icon: Upload },
]

type Props = {
  onNavigate?: () => void
}

// The sidebar's nav content, breakpoint-agnostic on purpose - AppShell decides whether this
// renders in a fixed desktop rail or inside a mobile drawer; `onNavigate` lets the drawer close
// itself when a link is clicked, without this component knowing it's in a drawer at all.
export default function Sidebar({ onNavigate }: Props) {
  const { url } = usePage()

  function handleSignOut() {
    router.delete('/session')
  }

  return (
    <div className="flex h-full flex-col bg-slate-900 text-white">
      <div className="flex items-center gap-2 px-4 py-5">
        <LayoutDashboard className="h-6 w-6 text-primary" />
        <span className="text-lg font-semibold tracking-tight">Umanni</span>
      </div>

      <nav className="flex-1 space-y-1 px-2">
        {NAV_ITEMS.map((item) => {
          const active = url.startsWith(item.href)
          const Icon = item.icon

          return (
            <Link
              key={item.href}
              href={item.href}
              onClick={onNavigate}
              className={`flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium ${
                active ? 'bg-primary text-white' : 'text-slate-300 hover:bg-slate-800 hover:text-white'
              }`}
            >
              <Icon className="h-4 w-4" />
              {item.label}
            </Link>
          )
        })}
      </nav>

      <div className="space-y-1 border-t border-slate-800 px-2 py-4">
        <Link
          href="/profile"
          onClick={onNavigate}
          className="flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white"
        >
          <User className="h-4 w-4" />
          My profile
        </Link>
        <button
          type="button"
          onClick={handleSignOut}
          className="flex w-full items-center gap-3 rounded-md px-3 py-2 text-left text-sm font-medium text-slate-300 hover:bg-slate-800 hover:text-white"
        >
          <LogOut className="h-4 w-4" />
          Sign out
        </button>
      </div>
    </div>
  )
}
