import { InputHTMLAttributes } from 'react'

type Props = InputHTMLAttributes<HTMLInputElement> & {
  label: string
  // string[], not string - Inertia errors carry one array of messages per field in this app
  // (see types/globals.d.ts's InertiaConfig override), and every other page already renders
  // that array directly rather than picking a single message.
  error?: string[]
}

// A labeled input with an inline error message - the shape every form field in the app already
// hand-rolled per-page; this is the one place that markup lives now.
export default function Input({ label, error, id, className = '', ...props }: Props) {
  return (
    <div>
      <label htmlFor={id} className="block text-sm font-medium text-text">
        {label}
      </label>
      <input
        id={id}
        className={`mt-1 block w-full rounded-md border-border shadow-sm focus:border-primary focus:ring-primary sm:text-sm ${className}`}
        {...props}
      />
      {error && <p className="mt-1 text-sm text-danger">{error}</p>}
    </div>
  )
}
