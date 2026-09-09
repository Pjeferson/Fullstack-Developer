import { useEffect, useState } from 'react'

import ImportStatusBadge from '@/components/imports/ImportStatusBadge'
import Modal from '@/components/ui/Modal'
import Progress from '@/components/ui/Progress'
import { useImportProgress } from '@/hooks/useImportProgress'
import { AdminImportListItem, SpreadsheetImportSummary } from '@/types'

type Props = {
  spreadsheetImport: AdminImportListItem | null // null = closed
  // Hands back whatever this modal's live subscription last saw, so the caller can patch that
  // row in the history list - the row otherwise stays exactly as it was when the page loaded,
  // even after the admin watches it change live in here. `null` only if the modal never had
  // anything to show in the first place.
  onClose: (summary: SpreadsheetImportSummary | null) => void
}

// Replaces the old dedicated admin/spreadsheet_imports/show.tsx page - opened from a row in the
// import history (seeded from that row's already-loaded data) or right after an upload (seeded
// from imports[0] - see ImportUploader/design.md). Subscribes over the same
// SpreadsheetImportChannel/useImportProgress the old page used; useImportProgress(null, ...)
// while closed skips subscribing entirely (see useChannel).
export default function ImportProgressModal({ spreadsheetImport, onClose }: Props) {
  const [ summary, setSummary ] = useState<SpreadsheetImportSummary | null>(spreadsheetImport)

  // Reseeds whenever a (possibly different) import is opened - live updates below take over
  // from there.
  useEffect(() => {
    setSummary(spreadsheetImport)
  }, [ spreadsheetImport?.id ])

  useImportProgress(spreadsheetImport?.id ?? null, setSummary)

  const { status, total_rows, processed_rows, success_count, error_count } = summary ?? {
    status: 'pending' as const,
    total_rows: null,
    processed_rows: 0,
    success_count: 0,
    error_count: 0,
  }
  const progressPercent = total_rows ? Math.min(100, Math.round((processed_rows / total_rows) * 100)) : 0

  return (
    <Modal
      open={spreadsheetImport !== null}
      onClose={() => onClose(summary)}
      title={spreadsheetImport?.filename ?? 'Import status'}
    >
      <div className="mb-4">
        <ImportStatusBadge status={status} />
      </div>

      <Progress value={progressPercent} label={`${progressPercent}%`} />

      <dl className="mt-4 space-y-2 text-sm">
        <div className="flex justify-between border-b border-border py-1">
          <dt className="text-text-muted">Total rows</dt>
          <dd className="text-text">{total_rows ?? '—'}</dd>
        </div>
        <div className="flex justify-between border-b border-border py-1">
          <dt className="text-text-muted">Processed</dt>
          <dd className="text-text">{processed_rows}</dd>
        </div>
        <div className="flex justify-between border-b border-border py-1">
          <dt className="text-text-muted">Succeeded</dt>
          <dd className="text-text">{success_count}</dd>
        </div>
        <div className="flex justify-between py-1">
          <dt className="text-text-muted">Failed</dt>
          <dd className="text-text">{error_count}</dd>
        </div>
      </dl>
    </Modal>
  )
}
