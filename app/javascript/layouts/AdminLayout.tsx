import { Link, router, usePage } from '@inertiajs/react'
import { ReactNode } from 'react'

export default function AdminLayout({ children }: { children: ReactNode }) {
  const { current_user } = usePage().props

  function handleSignOut() {
    router.delete('/session')
  }

  return (
    <div className="w-full">
      <nav className="flex items-center justify-between border-b border-gray-200 pb-4 mb-8">
        <Link href="/admin/users" className="font-semibold">
          Admin
        </Link>

        <div className="flex items-center gap-4 text-sm text-gray-600">
          {current_user && <span>{current_user.email_address}</span>}
          <button type="button" onClick={handleSignOut} className="underline">
            Sign out
          </button>
        </div>
      </nav>

      {children}
    </div>
  )
}
