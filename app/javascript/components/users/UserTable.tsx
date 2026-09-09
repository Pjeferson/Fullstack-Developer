import Table from '@/components/ui/Table'
import UserCard from '@/components/users/UserCard'
import UserRow from '@/components/users/UserRow'
import { AdminUserListItem } from '@/types'

const COLUMNS = [
  { key: 'user', label: 'User' },
  { key: 'email', label: 'Email' },
  { key: 'role', label: 'Role' },
  { key: 'avatar', label: 'Avatar' },
  { key: 'created', label: 'Created' },
  { key: 'updated', label: 'Updated' },
  { key: 'actions', label: '' },
]

type Props = {
  users: AdminUserListItem[]
  onEdit: (user: AdminUserListItem) => void
  onDelete: (user: AdminUserListItem) => void
}

// Two renders of the same rows: a table from md up, a stacked card list below it - a CSS-only
// toggle (hidden md:table / md:hidden), not JS breakpoint detection, so there's no
// server/client hydration mismatch risk. See design.md.
export default function UserTable({ users, onEdit, onDelete }: Props) {
  return (
    <>
      <Table columns={COLUMNS} className="hidden md:table">
        {users.map((user) => (
          <UserRow key={user.id} user={user} onEdit={onEdit} onDelete={onDelete} />
        ))}
      </Table>

      <div className="md:hidden">
        {users.map((user) => (
          <UserCard key={user.id} user={user} onEdit={onEdit} onDelete={onDelete} />
        ))}
      </div>
    </>
  )
}
