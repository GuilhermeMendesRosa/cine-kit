import { describe, expect, it, vi } from 'vitest'
import { fetchState, pointer, press, setSleep, setTheme, typeText } from './api'

describe('press', () => {
  it('is ok on 204', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await press('ok', { fetch })).toBe('ok')
  })

  it('is offline on 401', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 401 }))
    expect(await press('ok', { fetch })).toBe('offline')
  })

  it('is offline when fetch rejects', async () => {
    const fetch = vi.fn().mockRejectedValue(new TypeError('Load failed'))
    expect(await press('ok', { fetch })).toBe('offline')
  })

  it('sends the button without an Authorization header', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    await press('volumeUp', { fetch })
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/press')
    expect(init.method).toBe('POST')
    expect(new Headers(init.headers).has('Authorization')).toBe(false)
    expect(JSON.parse(init.body)).toEqual({ button: 'volumeUp' })
  })

  it('sends power', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await press('power', { fetch })).toBe('ok')
    expect(JSON.parse(fetch.mock.calls[0][1].body)).toEqual({ button: 'power' })
  })
})

describe('pointer', () => {
  it('sends type and deltas without an Authorization header', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await pointer({ type: 'move', dx: 3, dy: -4 }, { fetch })).toBe('ok')
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/pointer')
    expect(init.method).toBe('POST')
    expect(new Headers(init.headers).has('Authorization')).toBe(false)
    expect(JSON.parse(init.body)).toEqual({ type: 'move', dx: 3, dy: -4 })
  })
})

describe('fetchState', () => {
  it('returns the click sound on 200', async () => {
    const fetch = vi.fn().mockResolvedValue(Response.json({ clickSound: false }))
    expect(await fetchState({ fetch })).toEqual({ clickSound: false, theme: 'dark', power: false, sleep: null })
  })

  it('returns the theme on 200', async () => {
    const fetch = vi.fn().mockResolvedValue(Response.json({ clickSound: true, theme: 'light' }))
    expect(await fetchState({ fetch })).toEqual({ clickSound: true, theme: 'light', power: false, sleep: null })
  })

  it('returns power on 200', async () => {
    const fetch = vi.fn().mockResolvedValue(Response.json({ clickSound: true, theme: 'dark', power: true }))
    expect(await fetchState({ fetch })).toEqual({ clickSound: true, theme: 'dark', power: true, sleep: null })
  })

  it('returns sleep on 200', async () => {
    const fetch = vi.fn()
      .mockResolvedValueOnce(Response.json({ clickSound: true, sleep: 1740 }))
      .mockResolvedValueOnce(Response.json({ clickSound: true, sleep: null }))
    expect(await fetchState({ fetch })).toMatchObject({ sleep: 1740 })
    expect(await fetchState({ fetch })).toMatchObject({ sleep: null })
  })

  it('is offline on 401', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 401 }))
    expect(await fetchState({ fetch })).toBe('offline')
  })

  it('is offline when fetch rejects', async () => {
    const fetch = vi.fn().mockRejectedValue(new TypeError('Load failed'))
    expect(await fetchState({ fetch })).toBe('offline')
  })

  it('sends GET /api/state without an Authorization header', async () => {
    const fetch = vi.fn().mockResolvedValue(Response.json({ clickSound: true }))
    await fetchState({ fetch })
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/state')
    expect(init.method ?? 'GET').toBe('GET')
    expect(new Headers(init.headers).has('Authorization')).toBe(false)
  })
})

describe('typeText', () => {
  it('sends the text without an Authorization header', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await typeText('ação', { fetch })).toBe('ok')
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/text')
    expect(init.method).toBe('POST')
    expect(new Headers(init.headers).has('Authorization')).toBe(false)
    expect(JSON.parse(init.body)).toEqual({ text: 'ação' })
  })
})

describe('setTheme', () => {
  it('sends the theme without an Authorization header', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await setTheme('dark', { fetch })).toBe('ok')
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/theme')
    expect(init.method).toBe('POST')
    expect(new Headers(init.headers).has('Authorization')).toBe(false)
    expect(JSON.parse(init.body)).toEqual({ theme: 'dark' })
  })
})

describe('setSleep', () => {
  it('sends the minutes', async () => {
    const fetch = vi.fn().mockResolvedValue(new Response(null, { status: 204 }))
    expect(await setSleep(30, { fetch })).toBe('ok')
    const [url, init] = fetch.mock.calls[0]
    expect(url).toBe('/api/sleep')
    expect(init.method).toBe('POST')
    expect(JSON.parse(init.body)).toEqual({ minutes: 30 })
  })

  it('is offline when fetch rejects', async () => {
    const fetch = vi.fn().mockRejectedValue(new TypeError('Load failed'))
    expect(await setSleep(30, { fetch })).toBe('offline')
  })
})
