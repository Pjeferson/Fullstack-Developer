import { ReactNode } from 'react'

type Props = {
  title?: string
  children: ReactNode
  className?: string
}

export default function Card({ title, children, className = '' }: Props) {
  return (
    <div className={`rounded-lg border border-border bg-surface p-4 shadow-sm ${className}`}>
      {title && <h3 className="text-h3 mb-2 font-semibold text-text">{title}</h3>}
      {children}
    </div>
  )
}
