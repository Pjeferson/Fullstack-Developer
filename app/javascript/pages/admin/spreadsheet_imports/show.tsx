import { Head, Link, router } from '@inertiajs/react'
import { ReactNode } from 'react'

import AdminLayout from '@/layouts/AdminLayout'
import { SpreadsheetImportSummary } from '@/types'

export default function AdminSpreadsheetImportsShow({ import: spreadsheetImport }: { import: SpreadsheetImportSummary }) {
  const { status, total_rows, processed_rows, success_count, error_count } = spreadsheetImport

  function handleRefresh() {
    router.reload()
  }

  return (
    <>
      <Head title="Import status" />

      <h1 className="text-2xl font-semibold mb-1">Import status</h1>
      <p className="text-sm text-gray-500 mb-6 capitalize">{status}</p>

      {/* No live updates in this branch — Refresh re-reads the persisted state above. */}
      <dl className="max-w-sm space-y-2 text-sm">
        <div className="flex justify-between border-b border-gray-100 py-1">
          <dt className="text-gray-500">Total rows</dt>
          <dd>{total_rows ?? '—'}</dd>
        </div>
        <div className="flex justify-between border-b border-gray-100 py-1">
          <dt className="text-gray-500">Processed</dt>
          <dd>{processed_rows}</dd>
        </div>
        <div className="flex justify-between border-b border-gray-100 py-1">
          <dt className="text-gray-500">Succeeded</dt>
          <dd>{success_count}</dd>
        </div>
        <div className="flex justify-between py-1">
          <dt className="text-gray-500">Failed</dt>
          <dd>{error_count}</dd>
        </div>
      </dl>

      <div className="mt-6 flex gap-4 text-sm">
        <button type="button" onClick={handleRefresh} className="underline">
          Refresh
        </button>
        <Link href="/admin/spreadsheet_imports/new" className="underline">
          Import another file
        </Link>
      </div>
    </>
  )
}

AdminSpreadsheetImportsShow.layout = (page: ReactNode) => <AdminLayout>{page}</AdminLayout>
