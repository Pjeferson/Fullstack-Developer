import { Head, Link, InfiniteScroll } from '@inertiajs/react'
import { ReactNode, useEffect, useState } from 'react'

import AppShell from '@/components/layout/AppShell'
import DashboardStats from '@/components/admin/DashboardStats'
import UsersTable from '@/components/admin/UsersTable'
import { useDashboardStats } from '@/hooks/useDashboardStats'
import { AdminUserListItem, DashboardStats as DashboardStatsData } from '@/types'

export default function AdminUsersIndex({ users, stats: initialStats }: { users: AdminUserListItem[]; stats: DashboardStatsData }) {
  const [ stats, setStats ] = useState(initialStats)

  // Keeps a full Inertia reload's fresh `stats` prop in sync with state — live updates below
  // never go through this path.
  useEffect(() => {
    setStats(initialStats)
  }, [ initialStats ])

  useDashboardStats(setStats)

  return (
    <>
      <Head title="Users" />

      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-semibold">Users</h1>
        <Link href="/admin/users/new" className="rounded bg-gray-900 text-white px-4 py-2 text-sm">
          New user
        </Link>
      </div>

      <DashboardStats stats={stats} />

      <InfiniteScroll data="users" onlyNext>
        <UsersTable users={users} />
      </InfiniteScroll>
    </>
  )
}

AdminUsersIndex.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
