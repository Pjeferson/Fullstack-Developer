import { z } from 'zod'

// Mirrors the backend's actual rules exactly (User's presence/format validations,
// has_secure_password's presence check) - no invented stricter rule the server doesn't also
// enforce, e.g. no client-only minimum password length. See README's "Input Validation" section
// for why this stays a mirror of the backend rather than the only source of truth.
const fullName = z.string().trim().min(1, "can't be blank")
const email = z.string().trim().min(1, "can't be blank").email('is invalid')
const password = z.string().min(1, "can't be blank")

// Full name + email - shared by UserForm (admin create/edit) and, via UserForm, the
// self-service profile page.
export const userFormSchema = z.object({
  full_name: fullName,
  email_address: email,
})

export const registrationSchema = z.object({
  full_name: fullName,
  email_address: email,
  password,
})

export const sessionSchema = z.object({
  email_address: email,
  password,
})

export const passwordsNewSchema = z.object({
  email_address: email,
})

export const passwordsEditSchema = z
  .object({
    password,
    password_confirmation: password,
  })
  .refine((data) => data.password === data.password_confirmation, {
    error: "doesn't match",
    path: [ 'password_confirmation' ],
  })

// Mirrors Admin::SpreadsheetImportsController#create's own checks, in the same order it makes
// them: presence first (`file.blank?`), then format (Imports::ParserFactory's supported
// extensions) - not a new, invented rule, and not stricter than what content-type sniffing on
// the server ultimately allows (the extension check here is necessarily looser, since a browser
// can't sniff content-type the way the server does off the uploaded bytes).
const importFile = z
  .instanceof(File, { error: "can't be blank" })
  .refine((file) => /\.(csv|xlsx)$/i.test(file.name), { error: 'must be a CSV or XLSX file' })

export const importUploadSchema = z.object({
  file: importFile,
})
