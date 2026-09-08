import { Head, useForm, usePage } from '@inertiajs/react'
import { FormEvent } from 'react'

export default function PasswordsEdit({ token }: { token: string }) {
  const { flash } = usePage<{ flash?: { alert?: string } }>().props
  const { data, setData, put, processing, errors } = useForm({
    password: '',
    password_confirmation: '',
  })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    put(`/passwords/${token}`)
  }

  return (
    <div className="mx-auto w-full max-w-sm">
      <Head title="Reset password" />

      <h1 className="text-2xl font-semibold mb-6">Reset your password</h1>

      {flash?.alert && <p className="mb-4 text-sm text-red-600">{flash.alert}</p>}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="password" className="block text-sm font-medium">
            New password
          </label>
          <input
            id="password"
            type="password"
            autoFocus
            autoComplete="new-password"
            required
            value={data.password}
            onChange={(e) => setData('password', e.target.value)}
            className="mt-1 block w-full rounded border-gray-300"
          />
          {errors.password && <p className="text-sm text-red-600">{errors.password}</p>}
        </div>

        <div>
          <label htmlFor="password_confirmation" className="block text-sm font-medium">
            Confirm new password
          </label>
          <input
            id="password_confirmation"
            type="password"
            autoComplete="new-password"
            required
            value={data.password_confirmation}
            onChange={(e) => setData('password_confirmation', e.target.value)}
            className="mt-1 block w-full rounded border-gray-300"
          />
        </div>

        <button type="submit" disabled={processing} className="w-full rounded bg-gray-900 text-white py-2">
          Reset password
        </button>
      </form>
    </div>
  )
}
