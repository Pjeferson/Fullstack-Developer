import { Head, Link, useForm, usePage } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import { useValidation } from '@/hooks/useValidation'
import { passwordsNewSchema } from '@/schemas'
import { FlashData } from '@/types'

export default function PasswordsNew() {
  const { flash } = usePage<{ flash?: FlashData }>().props
  const { data, setData, post, processing } = useForm({
    email_address: '',
  })
  const { errors: clientErrors, touch, touchAll, isValid } = useValidation(passwordsNewSchema, data)

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!isValid) {
      touchAll()
      return
    }
    post('/passwords')
  }

  return (
    <>
      <Head title="Forgot password" />

      <h1 className="text-h2 mb-6 font-bold text-text">Forgot your password?</h1>

      {flash?.notice && <p className="mb-4 text-sm text-success">{flash.notice}</p>}
      {flash?.alert && <p className="mb-4 text-sm text-danger">{flash.alert}</p>}

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
          error={clientErrors.email_address}
        />

        <Button type="submit" disabled={processing} className="w-full">
          Email reset instructions
        </Button>
      </form>

      <p className="mt-4 text-sm text-text-muted">
        <Link href="/session/new" className="text-primary underline">
          Back to sign in
        </Link>
      </p>
    </>
  )
}

PasswordsNew.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>
