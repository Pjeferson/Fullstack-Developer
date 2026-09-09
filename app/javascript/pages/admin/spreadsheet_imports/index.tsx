import { Head, InfiniteScroll } from '@inertiajs/react'
import { ReactNode, useState } from 'react'

import ImportHistoryTable from '@/components/imports/ImportHistoryTable'
import ImportProgressModal from '@/components/imports/ImportProgressModal'
import ImportUploader from '@/components/imports/ImportUploader'
import AppShell from '@/components/layout/AppShell'
import { AdminImportListItem } from '@/types'

// Replaces admin/spreadsheet_imports/{new,show}.tsx - one page: upload panel + paginated
// history, with an import's live progress in a modal instead of a dedicated status page.
export default function AdminSpreadsheetImportsIndex({ imports }: { imports: AdminImportListItem[] }) {
  const [ selectedImport, setSelectedImport ] = useState<AdminImportListItem | null>(null)

  // The history is newest-first, so the just-uploaded import is always freshImports[0] - see
  // ImportUploader/design.md.
  function handleUploaded(freshImports: AdminImportListItem[]) {
    if (freshImports[0]) setSelectedImport(freshImports[0])
  }

  return (
    <>
      <Head title="Imports" />

      <h1 className="mb-6 text-h1 font-bold text-text">Imports</h1>

      <ImportUploader onUploaded={handleUploaded} />

      <InfiniteScroll data="imports" onlyNext>
        <ImportHistoryTable imports={imports} onSelect={setSelectedImport} />
      </InfiniteScroll>

      <ImportProgressModal spreadsheetImport={selectedImport} onClose={() => setSelectedImport(null)} />
    </>
  )
}

AdminSpreadsheetImportsIndex.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
