import { Link, router } from '@inertiajs/react'

import RoleBadge from '@/components/RoleBadge'
import { AdminUserListItem } from '@/types'

function formatDate(value: string) {
  return new Date(value).toLocaleDateString()
}

export default function UserRow({ user }: { user: AdminUserListItem }) {
  function handleDelete() {
    router.delete(`/admin/users/${user.id}`, {
      onBefore: () => confirm(`Delete ${user.email_address}? This cannot be undone.`),
    })
  }

  function handleToggleRole() {
    const nextRole = user.role === 'admin' ? 'default' : 'admin'
    router.patch(`/admin/users/${user.id}/role`, { role: nextRole })
  }

  return (
    <tr className="border-b border-gray-100">
      <td className="py-2 pr-4">{user.full_name}</td>
      <td className="py-2 pr-4">{user.email_address}</td>
      <td className="py-2 pr-4">
        <RoleBadge role={user.role} />
      </td>
      <td className="py-2 pr-4 text-gray-500">
        {user.avatar_processing
          ? 'Processing…'
          : user.avatar_error
            ? 'Failed'
            : user.avatar_url
              ? 'Set'
              : '—'}
      </td>
      <td className="py-2 pr-4 text-gray-500 whitespace-nowrap">{formatDate(user.created_at)}</td>
      <td className="py-2 pr-4 text-gray-500 whitespace-nowrap">{formatDate(user.updated_at)}</td>
      <td className="py-2 text-right whitespace-nowrap">
        <button type="button" onClick={handleToggleRole} className="underline mr-4">
          {user.role === 'admin' ? 'Demote' : 'Promote'}
        </button>
        <Link href={`/admin/users/${user.id}/edit`} className="underline mr-4">
          Edit
        </Link>
        <button type="button" onClick={handleDelete} className="underline text-red-600">
          Delete
        </button>
      </td>
    </tr>
  )
}
