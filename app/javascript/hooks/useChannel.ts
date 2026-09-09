import { useEffect } from 'react'
import { createConsumer } from '@rails/actioncable'

// One shared consumer for the whole page — Action Cable multiplexes every subscription over a
// single WebSocket connection, so there's no reason for each caller to open its own.
let consumer: ReturnType<typeof createConsumer> | null = null
function getConsumer() {
  return (consumer ??= createConsumer())
}

// A hook, not a plain function, because subscribing is tied to a component's lifecycle: it has
// to (re)subscribe when the component mounts or channel/params change, and always unsubscribe
// on unmount — exactly what useEffect's setup/cleanup pair models. A plain function would leave
// every caller re-implementing that same effect + cleanup by hand.
//
// `params: null` skips subscribing entirely - lets a caller stay mounted (e.g. a modal that's
// closed but still in the tree for its close transition) without holding an open subscription
// for nothing to watch.
export function useChannel<T>(channel: string, params: Record<string, unknown> | null, onReceived: (data: T) => void) {
  useEffect(() => {
    if (!params) return

    const subscription = getConsumer().subscriptions.create({ channel, ...params }, { received: onReceived })

    return () => {
      subscription.unsubscribe()
    }
    // Deliberately not depending on `onReceived`: callers typically pass an inline function
    // (a new reference every render), and re-subscribing on every render would defeat the
    // point of this hook. Re-subscribes only when the channel or its params actually change.
  }, [ channel, params ? JSON.stringify(params) : null ])
}
