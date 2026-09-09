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
  currentAvatarUrl?: string | null
}

// The fields shared by creating and editing a User - previously duplicated between
// pages/admin/users/new.tsx and edit.tsx, now the one place that markup lives. UserModal owns
// the useForm() call (create and edit submit differently) and passes its state down here.
export default function UserForm({ data, setData, errors, currentAvatarUrl }: Props) {
  return (
    <div className="space-y-4">
      <Input
        id="full_name"
        label="Full name"
        type="text"
        required
        value={data.full_name}
        onChange={(e) => setData('full_name', e.target.value)}
        error={errors.full_name}
      />

      <Input
        id="email_address"
        label="Email address"
        type="email"
        required
        value={data.email_address}
        onChange={(e) => setData('email_address', e.target.value)}
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
