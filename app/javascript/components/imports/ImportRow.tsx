import ImportStatusBadge from '@/components/imports/ImportStatusBadge'
import { AdminImportListItem } from '@/types'

function formatDate(value: string) {
  return new Date(value).toLocaleDateString()
}

type Props = {
  spreadsheetImport: AdminImportListItem
}

// Desktop table row (md and up) - read-only, every column the progress modal would otherwise
// show is already visible here. See ImportHistoryTable.
export default function ImportRow({ spreadsheetImport }: Props) {
  return (
    <tr className="border-b border-border">
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
