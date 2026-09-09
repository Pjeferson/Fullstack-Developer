import ImportStatusBadge from '@/components/imports/ImportStatusBadge'
import { AdminImportListItem } from '@/types'

function formatDate(value: string) {
  return new Date(value).toLocaleDateString()
}

type Props = {
  spreadsheetImport: AdminImportListItem
  onSelect: (spreadsheetImport: AdminImportListItem) => void
}

// Desktop table row (md and up) - the whole row opens the progress modal, seeded from this row's
// already-loaded data (no separate fetch - see design.md).
export default function ImportRow({ spreadsheetImport, onSelect }: Props) {
  return (
    <tr
      className="cursor-pointer border-b border-border hover:bg-background"
      onClick={() => onSelect(spreadsheetImport)}
    >
      <td className="py-2 pr-4">{spreadsheetImport.filename}</td>
      <td className="py-2 pr-4">
        <ImportStatusBadge status={spreadsheetImport.status} />
      </td>
      <td className="py-2 pr-4 text-text-muted">
        {spreadsheetImport.processed_rows}/{spreadsheetImport.total_rows ?? '—'}
      </td>
      <td className="py-2 pr-4 text-text-muted">{spreadsheetImport.success_count}</td>
      <td className="py-2 pr-4 text-text-muted">{spreadsheetImport.error_count}</td>
      <td className="whitespace-nowrap py-2 text-text-muted">{formatDate(spreadsheetImport.created_at)}</td>
    </tr>
  )
}
