import { useChannel } from '@/hooks/useChannel'
import { SpreadsheetImportSummary } from '@/types'

// Names the channel + payload for one live-updating SpreadsheetImport, so call sites read as
// "what data am I watching" instead of re-wiring the channel string and shape each time.
// `importId: null` (e.g. the modal watching it is closed) skips subscribing - see useChannel.
export function useImportProgress(importId: number | null, onUpdate: (data: SpreadsheetImportSummary) => void) {
  useChannel<SpreadsheetImportSummary>('SpreadsheetImportChannel', importId ? { id: importId } : null, onUpdate)
}
