import { Head, useForm, usePage } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AuthLayout from '@/components/layout/AuthLayout'
import Button from '@/components/ui/Button'
import Input from '@/components/ui/Input'
import { FlashData } from '@/types'

export default function PasswordsEdit({ token }: { token: string }) {
  const { flash } = usePage<{ flash?: FlashData }>().props
  const { data, setData, put, processing, errors } = useForm({
    password: '',
    password_confirmation: '',
  })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
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
          error={errors.password}
        />

        <Input
          id="password_confirmation"
          label="Confirm new password"
          type="password"
          autoComplete="new-password"
          required
          value={data.password_confirmation}
          onChange={(e) => setData('password_confirmation', e.target.value)}
        />

        <Button type="submit" disabled={processing} className="w-full">
          Reset password
        </Button>
      </form>
    </>
  )
}

PasswordsEdit.layout = (page: ReactNode) => <AuthLayout>{page}</AuthLayout>
