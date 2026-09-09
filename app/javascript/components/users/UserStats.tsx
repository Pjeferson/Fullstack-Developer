import Card from '@/components/ui/Card'
import { DashboardStats as DashboardStatsData } from '@/types'

const ROLE_LABELS = { default: 'Members', admin: 'Admins' } as const

// Stacks to one column on mobile, three across from the tablet breakpoint up - see design.md's
// responsive strategy.
export default function UserStats({ stats }: { stats: DashboardStatsData }) {
  return (
    <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-3">
      <Card>
        <p className="text-xs text-text-muted">Total users</p>
        <p className="text-2xl font-semibold text-text">{stats.total}</p>
      </Card>
      {Object.entries(ROLE_LABELS).map(([ role, label ]) => (
        <Card key={role}>
          <p className="text-xs text-text-muted">{label}</p>
          <p className="text-2xl font-semibold text-text">{stats.by_role[role as keyof typeof ROLE_LABELS]}</p>
        </Card>
      ))}
    </div>
  )
}
