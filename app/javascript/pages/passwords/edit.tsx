import { Head, useForm, usePage } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import { useValidation } from '@/hooks/useValidation'
import { passwordsEditSchema } from '@/schemas'
import { FlashData } from '@/types'

export default function PasswordsEdit({ token }: { token: string }) {
  const { flash } = usePage<{ flash?: FlashData }>().props
  const { data, setData, put, processing, errors } = useForm({
    password: '',
    password_confirmation: '',
  })
  const { errors: clientErrors, touch, touchAll, isValid } = useValidation(passwordsEditSchema, data)

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    if (!isValid) {
      touchAll()
      return
    }
    put(`/passwords/${token}`)
  }

  return (
    <>
      <Head title="Reset password" />

      <h1 className="text-h2 mb-6 font-bold text-text">Reset your password</h1>

      {flash?.alert && <p className="mb-4 text-sm text-danger">{flash.alert}</p>}

      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          id="password"
          label="New password"
          type="password"
          autoFocus
          autoComplete="new-password"
          required
          value={data.password}
          onChange={(e) => setData('password', e.target.value)}
          onBlur={() => touch('password')}
          error={clientErrors.password ?? errors.password}
        />

        <Input
          id="password_confirmation"
          label="Confirm new password"
          type="password"
          autoComplete="new-password"
          required
          value={data.password_confirmation}
          onChange={(e) => setData('password_confirmation', e.target.value)}
          onBlur={() => touch('password_confirmation')}
          error={clientErrors.password_confirmation}
        />

        <Button type="submit" disabled={processing} className="w-full">
          Reset password
        </Button>
      </form>
    </>
  )
}

PasswordsEdit.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>
