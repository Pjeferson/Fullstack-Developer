import { useChannel } from '@/hooks/useChannel'
import { DashboardStats } from '@/types'

// Names the channel + payload for the admin dashboard's live stats — a single global stream,
// not scoped to any one record, so it takes no params.
export function useDashboardStats(onUpdate: (data: DashboardStats) => void) {
  useChannel<DashboardStats>('DashboardChannel', {}, onUpdate)
}
