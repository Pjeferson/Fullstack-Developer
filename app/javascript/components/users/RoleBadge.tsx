import Badge, { BadgeVariant } from '@/components/ui/Badge'
import { Role } from '@/types'

const LABELS: Record<Role, string> = {
  admin: 'Admin',
  default: 'Member',
}

const VARIANTS: Record<Role, BadgeVariant> = {
  admin: 'purple',
  default: 'default',
}

export default function RoleBadge({ role }: { role: Role }) {
  return <Badge variant={VARIANTS[role]}>{LABELS[role]}</Badge>
}
