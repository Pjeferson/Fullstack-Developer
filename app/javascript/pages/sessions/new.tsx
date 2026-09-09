import { Head, Link, useForm, usePage } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import { useValidation } from '@/hooks/useValidation'
import { sessionSchema } from '@/schemas'
import { FlashData } from '@/types'

export default function SessionsNew() {
  const { flash } = usePage<{ flash?: FlashData }>().props
  const { data, setData, post, processing, errors } = useForm({
    email_address: '',
    password: '',
  })
  const { errors: clientErrors, touch, touchAll, isValid } = useValidation(sessionSchema, data)

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!isValid) {
      touchAll()
      return
    }
    post('/session')
  }

  return (
    <>
      <Head title="Sign in" />

      <h1 className="text-h2 mb-6 font-bold text-text">Sign in</h1>

      {flash?.alert && <p className="mb-4 text-sm text-danger">{flash.alert}</p>}
      {flash?.notice && <p className="mb-4 text-sm text-success">{flash.notice}</p>}

      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          id="email_address"
          label="Email address"
          type="email"
          autoFocus
          autoComplete="email"
          required
          value={data.email_address}
          onChange={(e) => setData('email_address', e.target.value)}
          onBlur={() => touch('email_address')}
          error={clientErrors.email_address ?? errors.email_address}
        />

        <Input
          id="password"
          label="Password"
          type="password"
          autoComplete="current-password"
          required
          value={data.password}
          onChange={(e) => setData('password', e.target.value)}
          onBlur={() => touch('password')}
          error={clientErrors.password ?? errors.password}
        />

        <Button type="submit" disabled={processing} className="w-full">
          Sign in
        </Button>
      </form>

      <p className="mt-4 text-sm text-text-muted">
        <Link href="/passwords/new" className="text-primary underline">
          Forgot your password?
        </Link>
      </p>
      <p className="mt-2 text-sm text-text-muted">
        Don&apos;t have an account?{' '}
        <Link href="/registration/new" className="text-primary underline">
          Sign up
        </Link>
      </p>
    </>
  )
}

SessionsNew.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>
