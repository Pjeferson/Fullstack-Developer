import { Head, InfiniteScroll, router } from '@inertiajs/react'
import { ReactNode, useState } from 'react'

import ImportHistoryTable from '@/components/imports/ImportHistoryTable'
import ImportProgressModal from '@/components/imports/ImportProgressModal'
import ImportUploader from '@/components/imports/ImportUploader'
import AppShell from '@/components/layout/AppShell'
import { AdminImportListItem } from '@/types'

// Replaces admin/spreadsheet_imports/{new,show}.tsx - one page: upload panel + paginated
// history, with an import's live progress in a modal instead of a dedicated status page.
export default function AdminSpreadsheetImportsIndex({ imports }: { imports: AdminImportListItem[] }) {
  // Only ever set right after a fresh upload (see handleUploaded) - the modal isn't a general
  // "view this row's details" affordance, so history rows aren't clickable at all. That keeps
  // the reload below (on close) simple: the row it needs to be fresh for is always the one at
  // the very top of the list, i.e. exactly what page 1 already contains.
  const [ selectedImport, setSelectedImport ] = useState<AdminImportListItem | null>(null)

  // The history is newest-first, so the just-uploaded import is always freshImports[0] - see
  // ImportUploader/design.md.
  function handleUploaded(freshImports: AdminImportListItem[]) {
    if (freshImports[0]) setSelectedImport(freshImports[0])
  }

  // A real reload rather than a local patch: `reset: ['imports']` tells InertiaRails.scroll to
  // send this prop back as a plain replacement instead of an appended page (see
  // ScrollProp/PropsResolver), so this correctly drops the admin back to page 1 of the history -
  // an acceptable cost now that the modal only ever opens for the newest import, which page 1
  // already contains.
  function handleCloseProgressModal() {
    setSelectedImport(null)
    router.reload({ only: [ 'imports' ], reset: [ 'imports' ] })
  }

  return (
    <>
      <Head title="Imports" />

      <h1 className="mb-6 text-h1 font-bold text-text">Imports</h1>

      <ImportUploader onUploaded={handleUploaded} />

      <InfiniteScroll data="imports" onlyNext>
        <ImportHistoryTable imports={imports} />
      </InfiniteScroll>

      <ImportProgressModal spreadsheetImport={selectedImport} onClose={handleCloseProgressModal} />
    </>
  )
}

AdminSpreadsheetImportsIndex.layout = (page: ReactNode) => <AppShell>{page}</AppShell>
