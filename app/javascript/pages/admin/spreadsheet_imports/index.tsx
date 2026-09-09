import { Head, InfiniteScroll } from '@inertiajs/react'
import { ReactNode, useEffect, useState } from 'react'

import ImportHistoryTable from '@/components/imports/ImportHistoryTable'
import ImportProgressModal from '@/components/imports/ImportProgressModal'
import ImportUploader from '@/components/imports/ImportUploader'
import AppShell from '@/components/layout/AppShell'
import { AdminImportListItem, SpreadsheetImportSummary } from '@/types'

// Replaces admin/spreadsheet_imports/{new,show}.tsx - one page: upload panel + paginated
// history, with an import's live progress in a modal instead of a dedicated status page.
export default function AdminSpreadsheetImportsIndex({
  imports: initialImports,
}: {
  imports: AdminImportListItem[]
}) {
  const [ imports, setImports ] = useState(initialImports)
  const [ selectedImport, setSelectedImport ] = useState<AdminImportListItem | null>(null)

  // Keeps a full Inertia reload's (or InfiniteScroll's next page) fresh `imports` prop in sync
  // with state - the local patch on modal close below never goes through this path.
  useEffect(() => {
    setImports(initialImports)
  }, [ initialImports ])

  // The history is newest-first, so the just-uploaded import is always freshImports[0] - see
  // ImportUploader/design.md.
  function handleUploaded(freshImports: AdminImportListItem[]) {
    if (freshImports[0]) setSelectedImport(freshImports[0])
  }

  // Patches just the closed import's row with whatever the modal's live subscription last saw -
  // otherwise that row would keep showing whatever it looked like when the page/list loaded,
  // even right after watching it go from pending to completed in the modal. No server
  // round-trip: reloading `imports` from the server would also reset the infinite-scroll list
  // back to its first page, per InertiaRails.scroll's merge semantics.
  function handleCloseProgressModal(summary: SpreadsheetImportSummary | null) {
    if (summary) {
      setImports((current) => current.map((item) => (item.id === summary.id ? { ...item, ...summary } : item)))
    }
    setSelectedImport(null)
  }

  return (
    <>
      <Head title="Imports" />

      <h1 className="mb-6 text-h1 font-bold text-text">Imports</h1>

      <ImportUploader onUploaded={handleUploaded} />

      <InfiniteScroll data="imports" onlyNext>
        <ImportHistoryTable imports={imports} onSelect={setSelectedImport} />
      </InfiniteScroll>

      <ImportProgressModal spreadsheetImport={selectedImport} onClose={handleCloseProgressModal} />
    </>
  )
}

AdminSpreadsheetImportsIndex.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
