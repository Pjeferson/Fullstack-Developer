import { useMemo, useState } from 'react'
import { z } from 'zod'

// Client-side validation layered on top of Inertia's useForm, not replacing it - useForm still
// owns the form's data/submit state exactly as it did before; this only adds a second read of
// that same data through a Zod schema. Errors for a field only appear once it's been `touch`ed
// (blurred), so a fresh empty form doesn't open already red. See README's "Input Validation"
// section for why this mirrors backend rules instead of inventing its own.
export function useValidation<T extends Record<string, unknown>>(schema: z.ZodType<T>, data: T) {
  const [ touched, setTouched ] = useState<Partial<Record<keyof T, boolean>>>({})

  const result = useMemo(() => schema.safeParse(data), [ schema, data ])

  const errors = useMemo(() => {
    const fieldErrors: Partial<Record<keyof T, string[]>> = {}
    if (!result.success) {
      for (const issue of result.error.issues) {
        const field = issue.path[0] as keyof T
        if (!touched[field] || fieldErrors[field]) continue // one message per field - a blank
        // value can fail more than one check at once (e.g. both "can't be blank" and "is
        // invalid" on an empty email), and Input renders the array with no separator between
        // messages, so only the first (most relevant) one is kept.
        fieldErrors[field] = [ issue.message ]
      }
    }
    return fieldErrors
  }, [ result, touched ])

  function touch(field: keyof T) {
    setTouched((current) => ({ ...current, [field]: true }))
  }

  // Called on submit when the form is invalid, so every error shows immediately instead of only
  // the ones for fields the User happened to have already blurred.
  function touchAll() {
    setTouched(Object.fromEntries(Object.keys(data).map((key) => [ key, true ])) as Record<keyof T, boolean>)
  }

  return { errors, isValid: result.success, touch, touchAll }
}
