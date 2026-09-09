import ImportStatusBadge from '@/components/imports/ImportStatusBadge'
import { AdminImportListItem } from '@/types'

function formatDate(value: string) {
  return new Date(value).toLocaleDateString()
}

type Props = {
  spreadsheetImport: AdminImportListItem
  onSelect: (spreadsheetImport: AdminImportListItem) => void
}

// Mobile stacked card (below md) - same data and behavior as ImportRow.
export default function ImportCard({ spreadsheetImport, onSelect }: Props) {
  return (
    <button
      type="button"
      onClick={() => onSelect(spreadsheetImport)}
      className="flex w-full items-center justify-between gap-3 border-b border-border py-3 text-left"
    >
      <div className="min-w-0">
        <p className="truncate font-medium text-text">{spreadsheetImport.filename}</p>
        <p className="text-sm text-text-muted">{formatDate(spreadsheetImport.created_at)}</p>
      </div>
      <ImportStatusBadge status={spreadsheetImport.status} />
    </button>
  )
}
