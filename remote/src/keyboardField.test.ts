import { describe, expect, it } from 'vitest'
import { readField, sentinel } from './keyboardField'

describe('readField', () => {
  it('finds nothing when only the sentinel is there', () => {
    expect(readField(sentinel)).toEqual({ text: '', deleted: false })
  })

  it('reports a delete when the sentinel is gone', () => {
    expect(readField('')).toEqual({ text: '', deleted: true })
  })

  it('returns what was typed after the sentinel', () => {
    expect(readField(`${sentinel}ação`)).toEqual({ text: 'ação', deleted: false })
  })

  it('returns the text when typing replaced the sentinel', () => {
    expect(readField('a')).toEqual({ text: 'a', deleted: false })
  })
})
