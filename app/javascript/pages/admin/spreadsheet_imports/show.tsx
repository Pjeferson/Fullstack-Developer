import { Head, Link, router } from '@inertiajs/react'
import { ReactNode, useEffect, useState } from 'react'

import AdminLayout from '@/layouts/AdminLayout'
import { useChannel } from '@/hooks/useChannel'
import { SpreadsheetImportSummary } from '@/types'

export default function AdminSpreadsheetImportsShow({ import: initialImport }: { import: SpreadsheetImportSummary }) {
  const [ spreadsheetImport, setSpreadsheetImport ] = useState(initialImport)

  // Keeps the manual "Refresh" fallback working: a full Inertia reload lands a fresh `import`
  // prop, which this re-syncs into state. Live updates below never go through this path.
  useEffect(() => {
    setSpreadsheetImport(initialImport)
  }, [ initialImport ])

  // Applies each broadcast straight to state — summary_json is the one serialization already
  // shared with the initial props, so there's no risk of the two disagreeing on shape.
  useChannel<SpreadsheetImportSummary>(
    'SpreadsheetImportChannel',
    { id: initialImport.id },
    setSpreadsheetImport
  )

  const { status, total_rows, processed_rows, success_count, error_count } = spreadsheetImport
  const progressPercent = total_rows ? Math.min(100, Math.round((processed_rows / total_rows) * 100)) : 0

  function handleRefresh() {
    router.reload()
  }

  return (
    <>
      <Head title="Import status" />

      <h1 className="text-2xl font-semibold mb-1">Import status</h1>
      <p className="text-sm text-gray-500 mb-6 capitalize">{status}</p>

      <div className="max-w-sm mb-6">
        <div className="h-2 w-full rounded-full bg-gray-100 overflow-hidden">
          <div
            className="h-full rounded-full bg-gray-900 transition-all"
            style={{ width: `${progressPercent}%` }}
          />
        </div>
        <p className="mt-1 text-xs text-gray-500">{progressPercent}%</p>
      </div>

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
