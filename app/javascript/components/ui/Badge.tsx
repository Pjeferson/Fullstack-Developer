import { ReactNode } from 'react'

export type BadgeVariant = 'default' | 'success' | 'warning' | 'danger' | 'purple'

const VARIANT_STYLES: Record<BadgeVariant, string> = {
  default: 'bg-slate-100 text-slate-700',
  success: 'bg-emerald-100 text-emerald-800',
  warning: 'bg-amber-100 text-amber-800',
  danger: 'bg-red-100 text-red-800',
  purple: 'bg-purple-100 text-purple-800',
}

type Props = {
  variant?: BadgeVariant
  children: ReactNode
}

// The one place badge color/shape logic lives - domain badges (RoleBadge, ImportStatusBadge)
// map their own values to a variant here instead of each owning its own color map.
export default function Badge({ variant = 'default', children }: Props) {
  return (
    <span className={`inline-block rounded px-2 py-0.5 text-xs font-medium ${VARIANT_STYLES[variant]}`}>
      {children}
    </span>
  )
}
