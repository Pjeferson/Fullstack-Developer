import { ReactNode } from 'react'
import { Link } from '@inertiajs/react'
import { LayoutDashboard } from 'lucide-react'

import Card from '@/components/ui/Card'

// Shared by every unauthenticated page (sign in, forgot/reset password, register) - the same
// brand mark Sidebar uses for the authenticated shell, so the app reads as one product on
// either side of signing in. Replaces each page's own copy-pasted centering wrapper.
export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div className="flex min-h-screen flex-col items-center justify-center bg-background px-4 py-12">
      <Link href="/" className="mb-6 flex items-center gap-2">
        <LayoutDashboard className="h-6 w-6 text-primary" />
        <span className="text-lg font-semibold tracking-tight text-text">Umanni</span>
      </Link>
      <Card className="w-full max-w-sm">{children}</Card>
    </div>
  )
}
