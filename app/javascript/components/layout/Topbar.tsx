import { usePage } from '@inertiajs/react'
import { Menu } from 'lucide-react'

import Avatar from '@/components/ui/Avatar'
import { SharedProps } from '@/types'

type Props = {
  onOpenSidebar: () => void
}

// current_user only carries email_address (see InertiaController#inertia_share) - Avatar falls
// back to initials derived from it when there's no full name to work with.
export default function Topbar({ onOpenSidebar }: Props) {
  const { current_user } = usePage<SharedProps>().props

  return (
    <header className="flex items-center justify-between border-b border-border bg-surface px-4 py-3 md:justify-end">
      <button
        type="button"
        onClick={onOpenSidebar}
        className="text-text-muted hover:text-text md:hidden"
        aria-label="Open menu"
      >
        <Menu className="h-6 w-6" />
      </button>

      {current_user && (
        <div className="flex items-center gap-3">
          <span className="hidden text-sm text-text-muted sm:inline">{current_user.email_address}</span>
          <Avatar name={current_user.email_address} size="sm" />
        </div>
      )}
    </header>
  )
}
