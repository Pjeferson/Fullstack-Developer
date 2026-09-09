import { Head, router, useForm } from '@inertiajs/react'
import { FormEvent } from 'react'

import AvatarField from '@/components/AvatarField'
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

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    put('/profile')
  }

  function handleSignOut() {
    router.delete('/session')
  }

  function handleDelete() {
    router.delete('/profile', {
      onBefore: () => confirm('Delete your account? This cannot be undone.'),
    })
  }

  return (
    <div className="mx-auto mt-28 w-full max-w-sm px-5">
      <Head title="My profile" />

      <div className="flex items-center justify-between mb-6 text-sm text-gray-600">
        <span>{user.email_address}</span>
        <button type="button" onClick={handleSignOut} className="underline">
          Sign out
        </button>
      </div>

      <h1 className="text-2xl font-semibold mb-1">My profile</h1>
      <div className="mb-6">
        <RoleBadge role={user.role} />
      </div>

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="full_name" className="block text-sm font-medium">
            Full name
          </label>
          <input
            id="full_name"
            type="text"
            required
            value={data.full_name}
            onChange={(e) => setData('full_name', e.target.value)}
            className="mt-1 block w-full rounded border-gray-300"
          />
          {errors.full_name && <p className="text-sm text-red-600">{errors.full_name}</p>}
        </div>

        <div>
          <label htmlFor="email_address" className="block text-sm font-medium">
            Email address
          </label>
          <input
            id="email_address"
            type="email"
            required
            value={data.email_address}
            onChange={(e) => setData('email_address', e.target.value)}
            className="mt-1 block w-full rounded border-gray-300"
          />
          {errors.email_address && <p className="text-sm text-red-600">{errors.email_address}</p>}
        </div>

        <AvatarField
          currentAvatarUrl={user.avatar_url}
          file={data.avatar_image}
          url={data.avatar_image_url}
          onFileChange={(file) => setData('avatar_image', file)}
          onUrlChange={(url) => setData('avatar_image_url', url)}
          errors={errors.avatar_image}
        />
        {user.avatar_processing && <p className="text-sm text-gray-500">Avatar is still processing…</p>}
        {user.avatar_error && <p className="text-sm text-red-600">{user.avatar_error}</p>}

        <button type="submit" disabled={processing} className="w-full rounded bg-gray-900 text-white py-2">
          Save
        </button>
      </form>

      <button type="button" onClick={handleDelete} className="mt-6 text-sm text-red-600 underline">
        Delete my account
      </button>
    </div>
  )
}
