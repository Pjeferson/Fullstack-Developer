import { FormEvent } from 'react'
import { useForm } from '@inertiajs/react'

import Button from '@/components/ui/Button'
import Card from '@/components/ui/Card'
import { AdminImportListItem } from '@/types'

type Props = {
  onUploaded: (imports: AdminImportListItem[]) => void
}

// Stays on the imports page after a successful upload (Admin::SpreadsheetImportsController#create
// redirects back to #index, not a dedicated status page). onSuccess reads the fresh `imports`
// prop straight off the response's page object, not a closed-over one from render time - the
// newest-first history ordering guarantees the just-created import is imports[0], which the
// caller uses to open its progress modal. See design.md.
export default function ImportUploader({ onUploaded }: Props) {
  const { data, setData, post, processing, errors, reset } = useForm<{ file: File | null }>({ file: null })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    post('/admin/spreadsheet_imports', {
      onSuccess: (page) => {
        reset()
        onUploaded(page.props.imports as AdminImportListItem[])
      },
    })
  }

  return (
    <Card title="Upload spreadsheet" className="mb-6">
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="file" className="block text-sm font-medium text-text">
            CSV or XLSX file
          </label>
          <input
            id="file"
            type="file"
            accept=".csv,.xlsx"
            required
            onChange={(e) => setData('file', e.target.files?.[0] ?? null)}
            className="mt-1 block w-full text-sm"
          />
          {data.file && <p className="mt-1 text-sm text-text-muted">{data.file.name}</p>}
          {errors.file && <p className="text-sm text-danger">{errors.file}</p>}
        </div>

        <p className="text-sm text-text-muted">
          Each row becomes a new User (email address, full name, and optionally role and an
          avatar URL). No invite email is sent — share access with them separately.
        </p>

        <Button type="submit" disabled={processing}>
          Upload
        </Button>
      </form>
    </Card>
  )
}
