import { Head, router, useForm } from '@inertiajs/react'
import { FormEvent, ReactNode, useState } from 'react'

import AppShell from '@/components/layout/AppShell'
import Avatar from '@/components/ui/Avatar'
import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'
import ConfirmDialog from '@/components/ui/ConfirmDialog'
import RoleBadge from '@/components/users/RoleBadge'
import UserForm, { UserFormData } from '@/components/users/UserForm'
import { useValidation } from '@/hooks/useValidation'
import { userFormSchema } from '@/schemas'
import { UserProfile } from '@/types'

export default function ProfilesShow({ user }: { user: UserProfile }) {
  const { data, setData, put, processing, errors } = useForm<UserFormData>({
    full_name: user.full_name,
    email_address: user.email_address,
    avatar_image: null,
    avatar_image_url: '',
  })
  const {
    errors: clientErrors,
    touch,
    touchAll,
    isValid,
  } = useValidation(userFormSchema, { full_name: data.full_name, email_address: data.email_address })
  const [ confirmingDelete, setConfirmingDelete ] = useState(false)

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!isValid) {
      touchAll()
      return
    }
    put('/profile')
  }

  function handleDelete() {
    router.delete('/profile')
  }

  return (
    <div className="mx-auto max-w-lg">
      <Head title="My profile" />

      <div className="mb-6 flex items-center gap-4">
        <Avatar src={user.avatar_url} name={user.full_name} size="lg" />
        <div>
          <h1 className="text-h1 font-bold text-text">{user.full_name}</h1>
          <div className="mt-1">
            <RoleBadge role={user.role} />
          </div>
        </div>
      </div>

      <Card>
        <form onSubmit={handleSubmit}>
          <UserForm
            data={data}
            setData={setData}
            errors={{
              full_name: clientErrors.full_name ?? errors.full_name,
              email_address: clientErrors.email_address ?? errors.email_address,
              avatar_image: errors.avatar_image,
            }}
            touch={touch}
            currentAvatarUrl={user.avatar_url}
          />
          {user.avatar_processing && <p className="mt-4 text-sm text-text-muted">Avatar is still processing…</p>}
          {user.avatar_error && <p className="mt-4 text-sm text-danger">{user.avatar_error}</p>}

          <Button type="submit" disabled={processing} className="mt-4 w-full">
            Save
          </Button>
        </form>
      </Card>

      <button type="button" onClick={() => setConfirmingDelete(true)} className="mt-6 text-sm text-danger underline">
        Delete my account
      </button>

      <ConfirmDialog
        open={confirmingDelete}
        onClose={() => setConfirmingDelete(false)}
        onConfirm={handleDelete}
        title="Delete your account"
        confirmLabel="Delete"
      >
        Delete your account? This cannot be undone.
      </ConfirmDialog>
    </div>
  )
}

ProfilesShow.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
