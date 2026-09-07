import { Head, Link, useForm, usePage } from '@inertiajs/react'
import { FormEvent } from 'react'

export default function PasswordsNew() {
  const { flash } = usePage<{ flash?: { alert?: string; notice?: string } }>().props
  const { data, setData, post, processing } = useForm({
    email_address: '',
  })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    post('/passwords')
  }

  return (
    <div className="mx-auto w-full max-w-sm">
      <Head title="Forgot password" />

      <h1 className="text-2xl font-semibold mb-6">Forgot your password?</h1>

      {flash?.notice && <p className="mb-4 text-sm text-green-600">{flash.notice}</p>}
      {flash?.alert && <p className="mb-4 text-sm text-red-600">{flash.alert}</p>}

      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="email_address" className="block text-sm font-medium">
            Email address
          </label>
          <input
            id="email_address"
            type="email"
            autoFocus
            autoComplete="email"
            required
            value={data.email_address}
            onChange={(e) => setData('email_address', e.target.value)}
            className="mt-1 block w-full rounded border-gray-300"
          />
        </div>

        <button type="submit" disabled={processing} className="w-full rounded bg-gray-900 text-white py-2">
          Email reset instructions
        </button>
      </form>

      <p className="mt-4 text-sm">
        <Link href="/session/new">Back to sign in</Link>
      </p>
    </div>
  )
}
