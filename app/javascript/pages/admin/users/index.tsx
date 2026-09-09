import { Head, InfiniteScroll } from '@inertiajs/react'
import { ReactNode, useEffect, useState } from 'react'

import AppShell from '@/components/layout/AppShell'
import Button from '@/components/ui/Button'
import DeleteUserDialog from '@/components/users/DeleteUserDialog'
import UserModal from '@/components/users/UserModal'
import UserStats from '@/components/users/UserStats'
import UserTable from '@/components/users/UserTable'
import { useDashboardStats } from '@/hooks/useDashboardStats'
import { AdminUserListItem, DashboardStats as DashboardStatsData } from '@/types'

export default function AdminUsersIndex({
  users,
  stats: initialStats,
}: {
  users: AdminUserListItem[]
  stats: DashboardStatsData
}) {
  const [ stats, setStats ] = useState(initialStats)
  const [ userModalOpen, setUserModalOpen ] = useState(false)
  const [ editingUser, setEditingUser ] = useState<AdminUserListItem | null>(null) // null = create mode
  const [ deletingUser, setDeletingUser ] = useState<AdminUserListItem | null>(null)

  // Keeps a full Inertia reload's fresh `stats` prop in sync with state — live updates below
  // never go through this path.
  useEffect(() => {
    setStats(initialStats)
  }, [ initialStats ])

  useDashboardStats(setStats)

  function openCreateModal() {
    setEditingUser(null)
    setUserModalOpen(true)
  }

  function openEditModal(user: AdminUserListItem) {
    setEditingUser(user)
    setUserModalOpen(true)
  }

  return (
    <>
      <Head title="Users" />

      <div className="mb-6 flex items-center justify-between">
        <h1 className="text-h1 font-bold text-text">Users</h1>
        <Button onClick={openCreateModal}>New user</Button>
      </div>

      <UserStats stats={stats} />

      <InfiniteScroll data="users" onlyNext>
        <UserTable users={users} onEdit={openEditModal} onDelete={setDeletingUser} />
      </InfiniteScroll>

      <UserModal open={userModalOpen} onClose={() => setUserModalOpen(false)} user={editingUser} />
      <DeleteUserDialog user={deletingUser} onClose={() => setDeletingUser(null)} />
    </>
  )
}

AdminUsersIndex.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
