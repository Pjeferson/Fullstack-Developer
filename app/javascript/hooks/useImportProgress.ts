import { useChannel } from '@/hooks/useChannel'
import { SpreadsheetImportSummary } from '@/types'

// Names the channel + payload for one live-updating SpreadsheetImport, so call sites read as
// "what data am I watching" instead of re-wiring the channel string and shape each time.
export function useImportProgress(importId: number, onUpdate: (data: SpreadsheetImportSummary) => void) {
  useChannel<SpreadsheetImportSummary>('SpreadsheetImportChannel', { id: importId }, onUpdate)
}
