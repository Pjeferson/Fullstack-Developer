import ImportStatusBadge from '@/components/imports/ImportStatusBadge'
import { AdminImportListItem } from '@/types'

function formatDate(value: string) {
  return new Date(value).toLocaleDateString()
}

type Props = {
  spreadsheetImport: AdminImportListItem
}

// Mobile stacked card (below md) - read-only, same data as ImportRow. See ImportHistoryTable.
export default function ImportCard({ spreadsheetImport }: Props) {
  return (
    <div className="flex items-center justify-between gap-3 border-b border-border py-3">
      <div className="min-w-0">
        <p className="truncate font-medium text-text">{spreadsheetImport.filename}</p>
        <p className="text-sm text-text-muted">{formatDate(spreadsheetImport.created_at)}</p>
      </div>
      <ImportStatusBadge status={spreadsheetImport.status} />
    </div>
  )
}
