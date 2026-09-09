import UserRow from '@/components/admin/UserRow'
import { AdminUserListItem } from '@/types'

export default function UsersTable({ users }: { users: AdminUserListItem[] }) {
  return (
    <table className="w-full text-left text-sm">
      <thead>
        <tr className="border-b border-gray-200 text-gray-500">
          <th className="py-2 pr-4">User</th>
          <th className="py-2 pr-4">Email</th>
          <th className="py-2 pr-4">Role</th>
          <th className="py-2 pr-4">Avatar</th>
          <th className="py-2 pr-4">Created</th>
          <th className="py-2 pr-4">Updated</th>
          <th className="py-2" />
        </tr>
      </thead>
      <tbody>
        {users.map((user) => (
          <UserRow key={user.id} user={user} />
        ))}
      </tbody>
    </table>
  )
}
