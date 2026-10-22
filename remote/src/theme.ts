import type { Theme } from './api'

const themeKey = 'cinekit.theme'

/** The last theme seen, so the remote opens without flashing; dark by default (ADR 0019). */
export function loadTheme(storage: Storage): Theme {
  return storage.getItem(themeKey) === 'light' ? 'light' : 'dark'
}

export function saveTheme(theme: Theme, storage: Storage): void {
  storage.setItem(themeKey, theme)
}

/** Themes the page through `data-theme` (App.css) and the browser bar through `theme-color`. */
export function applyTheme(theme: Theme, doc: Document = document): void {
  doc.documentElement.dataset.theme = theme
  doc.querySelector<HTMLMetaElement>('meta[name="theme-color"]')!.content = theme === 'light' ? '#f2f2f7' : '#000000'
}
