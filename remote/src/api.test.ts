import { describe, expect, it, vi } from 'vitest'
import { fetchState, pointer, press } from './api'

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

describe('pointer', () => {
  it('sends type and deltas', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await pointer({ type: 'move', dx: 3, dy: -4 }, { token: 'abc', fetch })).toBe('ok')
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/pointer')
    expect(init.method).toBe('POST')
    expect(new Headers(init.headers).get('Authorization')).toBe('Bearer abc')
    expect(JSON.parse(init.body)).toEqual({ type: 'move', dx: 3, dy: -4 })
  })

  it('is unauthorized on 401', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 401 }))
    expect(await pointer({ type: 'click' }, { token: 'abc', fetch })).toBe('unauthorized')
  })
})

describe('fetchState', () => {
  it('returns the click sound on 200', async () => {
    const fetch = vi.fn().mockResolvedValue(Response.json({ clickSound: false }))
    expect(await fetchState({ token: 'abc', fetch })).toEqual({ clickSound: false })
  })

  it('is unauthorized on 401', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 401 }))
    expect(await fetchState({ token: 'abc', fetch })).toBe('unauthorized')
  })

  it('is offline when fetch rejects', async () => {
    const fetch = vi.fn().mockRejectedValue(new TypeError('Load failed'))
    expect(await fetchState({ token: 'abc', fetch })).toBe('offline')
  })

  it('sends the token in GET /api/state', async () => {
    const fetch = vi.fn().mockResolvedValue(Response.json({ clickSound: true }))
    await fetchState({ token: 'abc', fetch })
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/state')
    expect(init.method ?? 'GET').toBe('GET')
    expect(new Headers(init.headers).get('Authorization')).toBe('Bearer abc')
  })
})
