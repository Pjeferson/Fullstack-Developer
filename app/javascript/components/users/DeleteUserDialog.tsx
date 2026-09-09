import { router } from '@inertiajs/react'

import Button from '@/components/ui/Button'
import Modal from '@/components/ui/Modal'
import { AdminUserListItem } from '@/types'

type Props = {
  user: AdminUserListItem | null // null = closed
  onClose: () => void
}

// Replaces the native confirm() the old UserRow used - a real dialog instead, consistent with
// the rest of this page now being modal-driven (see design-system's "destructive actions
// require confirmation" requirement).
export default function DeleteUserDialog({ user, onClose }: Props) {
  function handleConfirm() {
    if (!user) return
    router.delete(`/admin/users/${user.id}`, { onSuccess: onClose })
  }

  return (
    <Modal open={user !== null} onClose={onClose} title="Delete user">
      <p className="text-sm text-text-muted">
        Delete <span className="font-medium text-text">{user?.email_address}</span>? This cannot be undone.
      </p>
      <div className="mt-6 flex justify-end gap-3">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="button" variant="danger" onClick={handleConfirm}>
          Delete
        </Button>
      </div>
    </Modal>
  )
}
