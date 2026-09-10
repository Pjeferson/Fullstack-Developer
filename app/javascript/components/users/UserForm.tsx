import { SetDataByKeyValuePair } from '@inertiajs/react'

import AvatarField from '@/components/AvatarField'
import Input from '@/components/ui/Input'

export type UserFormData = {
  full_name: string
  email_address: string
  avatar_image: File | null
  avatar_image_url: string
}

type Props = {
  data: UserFormData
  setData: SetDataByKeyValuePair<UserFormData>
  errors: Partial<Record<keyof UserFormData, string[]>>
  // Only full_name/email_address are schema-validated (see userFormSchema) - avatar validation
  // stays server-side (Users::AvatarAssigner), so there's nothing to touch for those fields.
  touch: (field: 'full_name' | 'email_address') => void
  currentAvatarUrl?: string | null
}

// The fields shared by creating and editing a User - previously duplicated between
// pages/admin/users/new.tsx and edit.tsx, now the one place that markup lives. The caller
// (UserModal, or profiles/show.tsx) owns the useForm() and useValidation() calls and passes
// their already-merged (client + server) errors and a `touch` callback down here - this stays a
// dumb presentational component either way.
export default function UserForm({ data, setData, errors, touch, currentAvatarUrl }: Props) {
  return (
    <div className="space-y-4">
      <Input
        id="full_name"
        label="Full name"
        type="text"
        required
        value={data.full_name}
        onChange={(e) => setData('full_name', e.target.value)}
        onBlur={() => touch('full_name')}
        error={errors.full_name}
      />

      <Input
        id="email_address"
        label="Email address"
        type="email"
        required
        value={data.email_address}
        onChange={(e) => setData('email_address', e.target.value)}
        onBlur={() => touch('email_address')}
        error={errors.email_address}
      />

      <AvatarField
        currentAvatarUrl={currentAvatarUrl}
        file={data.avatar_image}
        url={data.avatar_image_url}
        onFileChange={(file) => setData('avatar_image', file)}
        onUrlChange={(url) => setData('avatar_image_url', url)}
        errors={errors.avatar_image}
      />
    </div>
  )
}
