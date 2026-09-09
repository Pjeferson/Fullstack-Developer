import { Head, useForm } from '@inertiajs/react'
import { FormEvent, ReactNode } from 'react'

import AdminLayout from '@/layouts/AdminLayout'

export default function AdminSpreadsheetImportsNew() {
  const { data, setData, post, processing, errors } = useForm<{ file: File | null }>({ file: null })

  function handleSubmit(e: FormEvent) {
    e.preventDefault()
    post('/admin/spreadsheet_imports')
  }

  return (
    <>
      <Head title="Import users" />

      <h1 className="text-2xl font-semibold mb-6">Import users from a spreadsheet</h1>

      <form onSubmit={handleSubmit} className="max-w-sm space-y-4">
        <div>
          <label htmlFor="file" className="block text-sm font-medium">
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
          {data.file && <p className="mt-1 text-sm text-gray-500">{data.file.name}</p>}
          {errors.file && <p className="text-sm text-red-600">{errors.file}</p>}
        </div>

        <p className="text-sm text-gray-500">
          Each row becomes a new User (email address, full name, and optionally role and an
          avatar URL). No invite email is sent — share access with them separately.
        </p>

        <button type="submit" disabled={processing} className="w-full rounded bg-gray-900 text-white py-2">
          Upload
        </button>
      </form>
    </>
  )
}

AdminSpreadsheetImportsNew.layout = (page: ReactNode) => <AdminLayout>{page}</AdminLayout>
