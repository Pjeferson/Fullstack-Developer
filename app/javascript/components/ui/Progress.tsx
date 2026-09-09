type Props = {
  value: number // 0-100
  label?: string
}

export default function Progress({ value, label }: Props) {
  const clamped = Math.min(100, Math.max(0, value))

  return (
    <div>
      <div className="h-2 w-full overflow-hidden rounded-full bg-slate-100">
        <div className="h-full rounded-full bg-primary transition-all" style={{ width: `${clamped}%` }} />
      </div>
      {label && <p className="mt-1 text-xs text-text-muted">{label}</p>}
    </div>
  )
}
