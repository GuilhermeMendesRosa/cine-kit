/** Always in the field, so Backspace has something to delete and the phone reports it (ADR 0025). */
export const sentinel = '​'

/** What the keyboard did to the field: the text it added, or whether it deleted the sentinel. */
export function readField(value: string) {
  const text = value.replaceAll(sentinel, '')
  return { text, deleted: text === '' && !value.includes(sentinel) }
}
