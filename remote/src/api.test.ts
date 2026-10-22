import { describe, expect, it, vi } from 'vitest'
import { press } from './api'

describe('press', () => {
  it('is ok on 204', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await press('ok', { token: 'abc', fetch })).toBe('ok')
  })

  it('is unauthorized on 401', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 401 }))
    expect(await press('ok', { token: 'abc', fetch })).toBe('unauthorized')
  })

  it('is offline when fetch rejects', async () => {
    const fetch = vi.fn().mockRejectedValue(new TypeError('Load failed'))
    expect(await press('ok', { token: 'abc', fetch })).toBe('offline')
  })

  it('sends the token and the button', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    await press('volumeUp', { token: 'abc', fetch })
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/press')
    expect(init.method).toBe('POST')
    expect(new Headers(init.headers).get('Authorization')).toBe('Bearer abc')
    expect(JSON.parse(init.body)).toEqual({ button: 'volumeUp' })
  })
})
