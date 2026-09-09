import { Head, Link, useForm } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'

// Full name, email, and password only - no confirmation field, no avatar picker. A Visitor
// registering this way always becomes a `default` User (role is structurally absent from
// RegistrationsController's permitted params); an avatar can be added later from the profile
// page, the same as any other User.
export default function RegistrationsNew() {
  const { data, setData, post, processing, errors } = useForm({
    full_name: '',
    email_address: '',
    password: '',
  })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    post('/registration')
  }

  return (
    <>
      <Head title="Sign up" />

      <h1 className="text-h2 mb-6 font-bold text-text">Create your account</h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          id="full_name"
          label="Full name"
          type="text"
          autoFocus
          autoComplete="name"
          required
          value={data.full_name}
          onChange={(e) => setData('full_name', e.target.value)}
          error={errors.full_name}
        />

        <Input
          id="email_address"
          label="Email address"
          type="email"
          autoComplete="email"
          required
          value={data.email_address}
          onChange={(e) => setData('email_address', e.target.value)}
          error={errors.email_address}
        />

        <Input
          id="password"
          label="Password"
          type="password"
          autoComplete="new-password"
          required
          value={data.password}
          onChange={(e) => setData('password', e.target.value)}
          error={errors.password}
        />

        <Button type="submit" disabled={processing} className="w-full">
          Sign up
        </Button>
      </form>

      <p className="mt-4 text-sm text-text-muted">
        Already have an account?{' '}
        <Link href="/session/new" className="text-primary underline">
          Sign in
        </Link>
      </p>
    </>
  )
}

RegistrationsNew.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>
