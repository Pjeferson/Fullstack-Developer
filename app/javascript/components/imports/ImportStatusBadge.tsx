import Badge, { BadgeVariant } from '@/components/ui/Badge'
import { SpreadsheetImportStatus } from '@/types'

const LABELS: Record<SpreadsheetImportStatus, string> = {
  pending: 'Pending',
  processing: 'Processing',
  completed: 'Completed',
  failed: 'Failed',
}

const VARIANTS: Record<SpreadsheetImportStatus, BadgeVariant> = {
  pending: 'default',
  processing: 'warning',
  completed: 'success',
  failed: 'danger',
}

export default function ImportStatusBadge({ status }: { status: SpreadsheetImportStatus }) {
  return <Badge variant={VARIANTS[status]}>{LABELS[status]}</Badge>
}
