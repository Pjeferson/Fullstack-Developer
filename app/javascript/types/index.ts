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

// Matches Admin::UsersController#users_json — the admin user list only. profile_json itself
// (shared with the edit form and the self-service profile page) doesn't carry timestamps.
export type AdminUserListItem = UserProfile & {
  created_at: string
  updated_at: string
}

export type SpreadsheetImportStatus = 'pending' | 'processing' | 'completed' | 'failed'

// Matches Admin::SpreadsheetImportsController#import_json. total_rows is null until the job
// has parsed the file and knows how many rows to expect.
export type SpreadsheetImportSummary = {
  id: number
  status: SpreadsheetImportStatus
  total_rows: number | null
  processed_rows: number
  success_count: number
  error_count: number
}
