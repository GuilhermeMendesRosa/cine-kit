const switchId = 'cinekit-haptic'

type Environment = { navigator?: { vibrate?: (pattern: number) => boolean | void }; document?: Document }

/**
 * A short tick on each press (ADR 0012). Safari on iOS has no `navigator.vibrate`, but toggling a
 * `<input type="checkbox" switch>` through its label ticks the Taptic Engine on iOS 18 and later.
 */
export function haptic({ navigator, document }: Environment = globalThis) {
  if (typeof navigator?.vibrate === 'function') {
    navigator.vibrate(10)
    return
  }
  if (!document) return
  const label = document.getElementById(switchId) ?? createSwitch(document)
  label.click()
}

function createSwitch(document: Document) {
  const input = document.createElement('input')
  input.type = 'checkbox'
  input.setAttribute('switch', '')
  const label = document.createElement('label')
  label.id = switchId
  label.setAttribute('aria-hidden', 'true')
  label.style.position = 'fixed'
  label.style.left = '-9999px'
  label.append(input)
  document.body.append(label)
  return label
}
