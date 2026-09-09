import { Head, Link, useForm, usePage } from '@inertiajs/react'
import { FormEvent } from 'react'

export default function SessionsNew() {
  const { flash } = usePage<{ flash?: { alert?: string; notice?: string } }>().props
  const { data, setData, post, processing, errors } = useForm({
    email_address: '',
    password: '',
  })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    post('/session')
  }

  return (
    <div className="mx-auto mt-28 w-full max-w-sm px-5">
      <Head title="Sign in" />

      <h1 className="text-2xl font-semibold mb-6">Sign in</h1>

      {flash?.alert && <p className="mb-4 text-sm text-red-600">{flash.alert}</p>}
      {flash?.notice && <p className="mb-4 text-sm text-green-600">{flash.notice}</p>}

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
          {errors.email_address && <p className="text-sm text-red-600">{errors.email_address}</p>}
        </div>

        <div>
          <label htmlFor="password" className="block text-sm font-medium">
            Password
          </label>
          <input
            id="password"
            type="password"
            autoComplete="current-password"
            required
            value={data.password}
            onChange={(e) => setData('password', e.target.value)}
            className="mt-1 block w-full rounded border-gray-300"
          />
          {errors.password && <p className="text-sm text-red-600">{errors.password}</p>}
        </div>

        <button type="submit" disabled={processing} className="w-full rounded bg-gray-900 text-white py-2">
          Sign in
        </button>
      </form>

      <p className="mt-4 text-sm">
        <Link href="/passwords/new">Forgot your password?</Link>
      </p>
    </div>
  )
}
