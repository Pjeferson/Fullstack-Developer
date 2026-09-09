type Size = 'sm' | 'md' | 'lg'

type Props = {
  src?: string | null
  name: string
  size?: Size
}

const SIZE_STYLES: Record<Size, string> = {
  sm: 'h-6 w-6 text-xs',
  md: 'h-9 w-9 text-sm',
  lg: 'h-12 w-12 text-base',
}

function initials(name: string) {
  const parts = name.trim().split(/\s+/).filter(Boolean)
  if (parts.length === 0) return '?'

  const first = parts[0][0]
  const last = parts.length > 1 ? parts[parts.length - 1][0] : ''
  return (first + last).toUpperCase()
}

// Displays a User's avatar image, or their initials when none is set (avatar_url is null) -
// today's plain <img> usage had no fallback at all.
export default function Avatar({ src, name, size = 'md' }: Props) {
  if (src) {
    return <img src={src} alt={name} className={`rounded-full object-cover ${SIZE_STYLES[size]}`} />
  }

  return (
    <span
      className={`inline-flex items-center justify-center rounded-full bg-primary/10 font-medium text-primary ${SIZE_STYLES[size]}`}
      aria-label={name}
    >
      {initials(name)}
    </span>
  )
}
