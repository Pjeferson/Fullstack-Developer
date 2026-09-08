export type FlashData = {
  notice?: string
  alert?: string
}

export type Role = 'default' | 'admin'

export type CurrentUser = {
  id: number
  email_address: string
  role: Role
}

export type SharedProps = {
  current_user: CurrentUser | null
}

// Matches User#profile_json — used by both the admin user list/edit
// pages and the self-service profile page, so they can't drift apart.
export type UserProfile = {
  id: number
  email_address: string
  full_name: string
  role: Role
  avatar_url: string | null
  avatar_processing: boolean
  avatar_error: string | null
}
