import { Head, router, useForm } from '@inertiajs/react'
import { FormEvent, ReactNode, useState } from 'react'

import AvatarField from '@/components/AvatarField'
import AppShell from '@/components/layout/AppShell'
import Avatar from '@/components/ui/Avatar'
import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'
import ConfirmDialog from '@/components/ui/ConfirmDialog'
import Input from '@/components/ui/Input'
import RoleBadge from '@/components/users/RoleBadge'
import { UserProfile } from '@/types'

export default function ProfilesShow({ user }: { user: UserProfile }) {
  const { data, setData, put, processing, errors } = useForm<{
    full_name: string
    email_address: string
    avatar_image: File | null
    avatar_image_url: string
  }>({
    full_name: user.full_name,
    email_address: user.email_address,
    avatar_image: null,
    avatar_image_url: '',
  })
  const [ confirmingDelete, setConfirmingDelete ] = useState(false)

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
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
        <form onSubmit={handleSubmit} className="space-y-4">
          <Input
            id="full_name"
            label="Full name"
            type="text"
            required
            value={data.full_name}
            onChange={(e) => setData('full_name', e.target.value)}
            error={errors.full_name}
          />

          <Input
            id="email_address"
            label="Email address"
            type="email"
            required
            value={data.email_address}
            onChange={(e) => setData('email_address', e.target.value)}
            error={errors.email_address}
          />

          <AvatarField
            currentAvatarUrl={user.avatar_url}
            file={data.avatar_image}
            url={data.avatar_image_url}
            onFileChange={(file) => setData('avatar_image', file)}
            onUrlChange={(url) => setData('avatar_image_url', url)}
            errors={errors.avatar_image}
          />
          {user.avatar_processing && <p className="text-sm text-text-muted">Avatar is still processing…</p>}
          {user.avatar_error && <p className="text-sm text-danger">{user.avatar_error}</p>}

          <Button type="submit" disabled={processing} className="w-full">
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
