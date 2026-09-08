import { useState } from 'react'

type Mode = 'file' | 'url'

type Props = {
  currentAvatarUrl?: string | null
  file: File | null
  url: string
  onFileChange: (file: File | null) => void
  onUrlChange: (url: string) => void
  errors?: string[]
}

// A single avatar field with two mutually-exclusive input modes: upload a
// file, or paste a remote URL. Switching modes clears the other value so
// only one of avatar_image/avatar_image_url is ever sent on submit.
export default function AvatarField({ currentAvatarUrl, file, url, onFileChange, onUrlChange, errors }: Props) {
  const [mode, setMode] = useState<Mode>('file')

  function switchTo(next: Mode) {
    setMode(next)
    onFileChange(null)
    onUrlChange('')
  }

  return (
    <div>
      <label className="block text-sm font-medium mb-1">Avatar</label>

      {currentAvatarUrl && (
        <img src={currentAvatarUrl} alt="Current avatar" className="mb-2 h-12 w-12 rounded-full object-cover" />
      )}

      <div className="flex gap-2 mb-2 text-sm">
        <button
          type="button"
          onClick={() => switchTo('file')}
          className={mode === 'file' ? 'font-semibold underline' : 'text-gray-500'}
        >
          Upload
        </button>
        <button
          type="button"
          onClick={() => switchTo('url')}
          className={mode === 'url' ? 'font-semibold underline' : 'text-gray-500'}
        >
          URL
        </button>
      </div>

      {mode === 'file' ? (
        <>
          <input
            type="file"
            accept="image/png,image/jpeg,image/webp,image/gif"
            onChange={(e) => onFileChange(e.target.files?.[0] ?? null)}
            className="block w-full text-sm"
          />
          {file && <p className="mt-1 text-xs text-gray-500">Selected: {file.name}</p>}
        </>
      ) : (
        <input
          type="url"
          placeholder="https://..."
          value={url}
          onChange={(e) => onUrlChange(e.target.value)}
          className="mt-1 block w-full rounded border-gray-300"
        />
      )}

      {errors?.map((error) => (
        <p key={error} className="text-sm text-red-600">
          {error}
        </p>
      ))}
    </div>
  )
}
