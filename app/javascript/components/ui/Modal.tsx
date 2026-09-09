import { ReactNode } from 'react'
import { Dialog, DialogBackdrop, DialogPanel, DialogTitle } from '@headlessui/react'
import { X } from 'lucide-react'

type Props = {
  open: boolean
  onClose: () => void
  title: string
  children: ReactNode
}

// Built on Headless UI's Dialog rather than a hand-rolled <div> overlay: focus trap,
// ESC-to-close, aria-modal, and restoring focus on close all come for free. `w-full
// sm:max-w-md` makes the panel near-full-width on mobile per the responsive reference, instead
// of a fixed size that could overflow a small viewport.
export default function Modal({ open, onClose, title, children }: Props) {
  return (
    <Dialog open={open} onClose={onClose} transition className="relative z-50">
      <DialogBackdrop
        transition
        className="fixed inset-0 bg-black/30 duration-200 ease-out data-[closed]:opacity-0"
      />
      <div className="fixed inset-0 flex w-screen items-center justify-center p-4">
        <DialogPanel
          transition
          className="w-full rounded-lg bg-surface p-6 shadow-xl duration-200 ease-out data-[closed]:scale-95 data-[closed]:opacity-0 sm:max-w-md"
        >
          <div className="mb-4 flex items-center justify-between">
            <DialogTitle className="text-h3 font-semibold text-text">{title}</DialogTitle>
            <button
              type="button"
              onClick={onClose}
              className="text-text-muted hover:text-text"
              aria-label="Close"
            >
              <X className="h-5 w-5" />
            </button>
          </div>
          {children}
        </DialogPanel>
      </div>
    </Dialog>
  )
}
