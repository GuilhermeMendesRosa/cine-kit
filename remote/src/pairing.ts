const tokenKey = 'cinekit.token'

/** The token in the QR code URL wins and is saved; otherwise the one saved by an earlier scan. */
export function resolveToken(url: URL, storage: Storage): string | null {
  const token = url.searchParams.get('token')
  if (token) {
    storage.setItem(tokenKey, token)
    return token
  }
  return storage.getItem(tokenKey)
}

export function clearToken(storage: Storage): void {
  storage.removeItem(tokenKey)
}
