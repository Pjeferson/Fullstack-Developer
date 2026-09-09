import { router } from '@inertiajs/react'

import Avatar from '@/components/ui/Avatar'
import RoleBadge from '@/components/users/RoleBadge'
import { AdminUserListItem } from '@/types'

type Props = {
  user: AdminUserListItem
  onEdit: (user: AdminUserListItem) => void
  onDelete: (user: AdminUserListItem) => void
}

// Mobile stacked card (below md) - same data and callbacks as UserRow, laid out for a narrow
// viewport instead of a table row.
export default function UserCard({ user, onEdit, onDelete }: Props) {
  function handleToggleRole() {
    const nextRole = user.role === 'admin' ? 'default' : 'admin'
    router.patch(`/admin/users/${user.id}/role`, { role: nextRole })
  }

  return (
    <div className="flex items-start justify-between gap-3 border-b border-border py-3">
      <div className="flex min-w-0 items-center gap-3">
        <Avatar src={user.avatar_url} name={user.full_name} />
        <div className="min-w-0">
          <p className="truncate font-medium text-text">{user.full_name}</p>
          <p className="truncate text-sm text-text-muted">{user.email_address}</p>
          <div className="mt-1">
            <RoleBadge role={user.role} />
          </div>
        </div>
      </div>
      <div className="flex flex-shrink-0 flex-col items-end gap-1 text-sm">
        <button type="button" onClick={handleToggleRole} className="underline">
          {user.role === 'admin' ? 'Demote' : 'Promote'}
        </button>
        <button type="button" onClick={() => onEdit(user)} className="underline">
          Edit
        </button>
        <button type="button" onClick={() => onDelete(user)} className="text-danger underline">
          Delete
        </button>
      </div>
    </div>
  )
}
