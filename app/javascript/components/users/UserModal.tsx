import { FormEvent, useEffect } from 'react'
import { useForm } from '@inertiajs/react'

import Button from '@/components/ui/Button'
import Modal from '@/components/ui/Modal'
import UserForm, { UserFormData } from '@/components/users/UserForm'
import { AdminUserListItem } from '@/types'

const BLANK_DATA: UserFormData = {
  full_name: '',
  email_address: '',
  avatar_image: null,
  avatar_image_url: '',
}

type Props = {
  open: boolean
  onClose: () => void
  user: AdminUserListItem | null // null = create mode, otherwise editing this User
}

// Handles both create and edit - one useForm() call, submitting to POST /admin/users or PUT
// /admin/users/:id depending on `user`. Edit mode seeds straight from the row data the page
// already has (profile_json, loaded with the list) - no separate fetch to open the modal.
//
// The modal closes only from useForm's onSuccess callback, not a server-side redirect target:
// both create and update now always redirect_to admin_users_path (success or failure - there's
// no separate new/edit page left to redirect back to on error), so a failed submission re-renders
// this same route with `errors` populated. onSuccess simply never fires in that case, and since
// the modal's open/closed state is local React state, not URL-driven, it just stays open with
// the errors shown - simpler than the page-based redirect-with-errors this replaces.
export default function UserModal({ open, onClose, user }: Props) {
  const { data, setData, post, put, processing, errors, reset, clearErrors } = useForm<UserFormData>(BLANK_DATA)

  // Reseeds whenever the modal opens (for a fresh create, or to edit a possibly different User)
  // so switching targets never leaks stale data or errors from a previous open.
  useEffect(() => {
    if (!open) return

    clearErrors()
    if (user) {
      setData({
        full_name: user.full_name,
        email_address: user.email_address,
        avatar_image: null,
        avatar_image_url: '',
      })
    } else {
      reset()
    }
    // Reruns only when the modal opens or the target User changes - not on every render, since
    // clearErrors/setData/reset are fresh references each render.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [ open, user?.id ])

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    const onSuccess = () => onClose()

    if (user) {
      put(`/admin/users/${user.id}`, { onSuccess })
    } else {
      post('/admin/users', { onSuccess })
    }
  }

  return (
    <Modal open={open} onClose={onClose} title={user ? 'Edit user' : 'Invite a user'}>
      <form onSubmit={handleSubmit}>
        <UserForm data={data} setData={setData} errors={errors} currentAvatarUrl={user?.avatar_url} />

        <div className="mt-6 flex justify-end gap-3">
          <Button type="button" variant="secondary" onClick={onClose}>
            Cancel
          </Button>
          <Button type="submit" disabled={processing}>
            {user ? 'Save' : 'Send invite'}
          </Button>
        </div>
      </form>
    </Modal>
  )
}
