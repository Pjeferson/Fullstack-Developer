import { Head, Link, router } from '@inertiajs/react'
import { ReactNode } from 'react'

import AdminLayout from '@/layouts/AdminLayout'
import RoleBadge from '@/components/RoleBadge'
import { AdminUser } from '@/types'

export default function AdminUsersIndex({ users }: { users: AdminUser[] }) {
  function handleDelete(user: AdminUser) {
    router.delete(`/admin/users/${user.id}`, {
      onBefore: () => confirm(`Delete ${user.email_address}? This cannot be undone.`),
    })
  }

  function handleToggleRole(user: AdminUser) {
    const nextRole = user.role === 'admin' ? 'default' : 'admin'
    router.patch(`/admin/users/${user.id}/role`, { role: nextRole })
  }

  return (
    <>
      <Head title="Users" />

      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold">Users</h1>
        <Link href="/admin/users/new" className="rounded bg-gray-900 text-white px-4 py-2 text-sm">
          New user
        </Link>
      </div>

      <table className="w-full text-left text-sm">
        <thead>
          <tr className="border-b border-gray-200 text-gray-500">
            <th className="py-2 pr-4">User</th>
            <th className="py-2 pr-4">Email</th>
            <th className="py-2 pr-4">Role</th>
            <th className="py-2 pr-4">Avatar</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.id} className="border-b border-gray-100">
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
              <td className="py-2 text-right whitespace-nowrap">
                <button type="button" onClick={() => handleToggleRole(user)} className="underline mr-4">
                  {user.role === 'admin' ? 'Demote' : 'Promote'}
                </button>
                <Link href={`/admin/users/${user.id}/edit`} className="underline mr-4">
                  Edit
                </Link>
                <button type="button" onClick={() => handleDelete(user)} className="underline text-red-600">
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </>
  )
}

AdminUsersIndex.layout = (page: ReactNode) => <AdminLayout>{page}</AdminLayout>
