import { Role } from '@/types'

const LABELS: Record<Role, string> = {
  admin: 'Admin',
  default: 'Member',
}

const STYLES: Record<Role, string> = {
  admin: 'bg-purple-100 text-purple-800',
  default: 'bg-gray-100 text-gray-700',
}

export default function RoleBadge({ role }: { role: Role }) {
  return (
    <span className={`inline-block rounded px-2 py-0.5 text-xs font-medium ${STYLES[role]}`}>
      {LABELS[role]}
    </span>
  )
}
