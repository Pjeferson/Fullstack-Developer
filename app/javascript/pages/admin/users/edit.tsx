import { Head, useForm } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AppShell from '@/components/layout/AppShell'
import AvatarField from '@/components/AvatarField'
import { UserProfile } from '@/types'

export default function AdminUsersEdit({ user }: { user: UserProfile }) {
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
    put(`/admin/users/${user.id}`)
  }

  return (
    <>
      <Head title={`Edit ${user.full_name}`} />

      <h1 className="text-2xl font-semibold mb-6">Edit user</h1>

      <form onSubmit={handleSubmit} className="max-w-sm space-y-4">
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
    </>
  )
}

AdminUsersEdit.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
