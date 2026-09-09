import Table from '@/components/ui/Table'
import ImportCard from '@/components/imports/ImportCard'
import ImportRow from '@/components/imports/ImportRow'
import { AdminImportListItem } from '@/types'

const COLUMNS = [
  { key: 'file', label: 'File' },
  { key: 'status', label: 'Status' },
  { key: 'progress', label: 'Progress' },
  { key: 'succeeded', label: 'Succeeded' },
  { key: 'failed', label: 'Failed' },
  { key: 'created', label: 'Created' },
]

type Props = {
  imports: AdminImportListItem[]
  onSelect: (spreadsheetImport: AdminImportListItem) => void
}

// Same table/card responsive split as UserTable - a CSS-only hidden md:table / md:hidden
// toggle, not JS breakpoint detection. See design.md.
export default function ImportHistoryTable({ imports, onSelect }: Props) {
  return (
    <>
      <Table columns={COLUMNS} className="hidden md:table">
        {imports.map((spreadsheetImport) => (
          <ImportRow key={spreadsheetImport.id} spreadsheetImport={spreadsheetImport} onSelect={onSelect} />
        ))}
      </Table>

      <div className="md:hidden">
        {imports.map((spreadsheetImport) => (
          <ImportCard key={spreadsheetImport.id} spreadsheetImport={spreadsheetImport} onSelect={onSelect} />
        ))}
      </div>
    </>
  )
}
