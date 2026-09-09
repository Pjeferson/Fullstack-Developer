import { DashboardStats as DashboardStatsData } from '@/types'

const ROLE_LABELS = { default: 'Members', admin: 'Admins' } as const

export default function DashboardStats({ stats }: { stats: DashboardStatsData }) {
  return (
    <dl className="flex gap-6 mb-6">
      <div className="rounded border border-gray-200 px-4 py-3">
        <dt className="text-xs text-gray-500">Total users</dt>
        <dd className="text-2xl font-semibold">{stats.total}</dd>
      </div>
      {Object.entries(ROLE_LABELS).map(([ role, label ]) => (
        <div key={role} className="rounded border border-gray-200 px-4 py-3">
          <dt className="text-xs text-gray-500">{label}</dt>
          <dd className="text-2xl font-semibold">{stats.by_role[role as keyof typeof ROLE_LABELS]}</dd>
        </div>
      ))}
    </dl>
  )
}
