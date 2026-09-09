import { router } from '@inertiajs/react'

import RoleBadge from '@/components/users/RoleBadge'
import { AdminUserListItem } from '@/types'

function formatDate(value: string) {
  return new Date(value).toLocaleDateString()
}

type Props = {
  user: AdminUserListItem
  onEdit: (user: AdminUserListItem) => void
  onDelete: (user: AdminUserListItem) => void
}

// Desktop table row (md and up) - UserCard is the same data as a mobile card. Edit/delete open
// modals owned by the page, not routes - onEdit/onDelete are callbacks, not links. Role toggle
// is unchanged: a direct PATCH, no modal, since it's not part of this branch's create/edit/
// delete-to-modal scope.
export default function UserRow({ user, onEdit, onDelete }: Props) {
  function handleToggleRole() {
    const nextRole = user.role === 'admin' ? 'default' : 'admin'
    router.patch(`/admin/users/${user.id}/role`, { role: nextRole })
  }

  return (
    <tr className="border-b border-border">
      <td className="py-2 pr-4">{user.full_name}</td>
      <td className="py-2 pr-4">{user.email_address}</td>
      <td className="py-2 pr-4">
        <RoleBadge role={user.role} />
      </td>
      <td className="py-2 pr-4 text-text-muted">
        {user.avatar_processing
          ? 'Processing…'
          : user.avatar_error
            ? 'Failed'
            : user.avatar_url
              ? 'Set'
              : '—'}
      </td>
      <td className="whitespace-nowrap py-2 pr-4 text-text-muted">{formatDate(user.created_at)}</td>
      <td className="whitespace-nowrap py-2 pr-4 text-text-muted">{formatDate(user.updated_at)}</td>
      <td className="whitespace-nowrap py-2 text-right">
        <button type="button" onClick={handleToggleRole} className="mr-4 underline">
          {user.role === 'admin' ? 'Demote' : 'Promote'}
        </button>
        <button type="button" onClick={() => onEdit(user)} className="mr-4 underline">
          Edit
        </button>
        <button type="button" onClick={() => onDelete(user)} className="text-danger underline">
          Delete
        </button>
      </td>
    </tr>
  )
}
