import { ReactNode } from 'react'

import Button from '@/components/ui/Button'
import Modal from '@/components/ui/Modal'

type Props = {
  open: boolean
  onClose: () => void
  onConfirm: () => void
  title: string
  children: ReactNode
  confirmLabel?: string
}

// The generic confirmation dialog for a destructive action - see design-system's "Destructive
// actions require confirmation" requirement. DeleteUserDialog predates this and is User-specific;
// this is for every other one-off case (starting with self-service account deletion).
export default function ConfirmDialog({ open, onClose, onConfirm, title, children, confirmLabel = 'Confirm' }: Props) {
  return (
    <Modal open={open} onClose={onClose} title={title}>
      <div className="text-sm text-text-muted">{children}</div>
      <div className="mt-6 flex justify-end gap-3">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="button" variant="danger" onClick={onConfirm}>
          {confirmLabel}
        </Button>
      </div>
    </Modal>
  )
}
