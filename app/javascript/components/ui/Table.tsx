import { ReactNode } from 'react'

type Column = { key: string; label: string; className?: string }

type Props = {
  columns: Column[]
  children: ReactNode // <tr> rows
  className?: string
}

// A generic table shell (header row + body slot) - breakpoint-agnostic on purpose. Callers that
// need the table/card responsive split (UserTable, ImportHistoryTable) pass their own
// `hidden md:table` via className, rather than this primitive baking in one specific breakpoint
// decision for every table in the app.
export default function Table({ columns, children, className = '' }: Props) {
  return (
    <table className={`w-full text-left text-sm ${className}`}>
      <thead>
        <tr className="border-b border-border text-text-muted">
          {columns.map((column) => (
            <th key={column.key} className={`py-2 pr-4 font-medium ${column.className ?? ''}`}>
              {column.label}
            </th>
          ))}
        </tr>
      </thead>
      <tbody>{children}</tbody>
    </table>
  )
}
