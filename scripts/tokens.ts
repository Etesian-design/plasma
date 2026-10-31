// The etesian-design tokens (src/styles/tokens.css) for the generators: the light (:root), hybrid and dark sets, and colour
// helpers. Shared by colors.ts (Plasma colour schemes) and thunderbird.ts (the Thunderbird theme).

import { readFileSync } from 'node:fs'
import { join } from 'node:path'
import { designRepo } from './design.ts'

export const design = designRepo(process.argv[2])
const css = readFileSync(join(design, 'src/styles/tokens.css'), 'utf8')

export type Tokens = Record<string, string>
/** The custom properties of the first rule whose selector list contains `selector` (later duplicates win, as in CSS). */
export function block(selector: string): Tokens {
  const at = css.indexOf(selector)
  if (at < 0) throw new Error(`no rule for ${selector} in tokens.css`)
  const body = css.slice(css.indexOf('{', at) + 1, css.indexOf('}', at))
  const out: Tokens = {}
  for (const m of body.matchAll(/--hd-([\w-]+):\s*([^;]+);/g)) out[m[1]] = m[2].trim()
  return out
}
export const root = block(':root {')
export const hybrid = { ...root, ...block('[data-hd-mode="hybrid"]') }
export const dark = { ...root, ...block('[data-hd-mode="dark"]') }

export type RGB = [number, number, number]
export function rgb(v: string): RGB {
  const hex = v.match(/^#([0-9a-f]{6})$/i)
  if (hex) return [0, 2, 4].map((i) => parseInt(hex[1].slice(i, i + 2), 16)) as RGB
  throw new Error(`not a #rrggbb colour: ${v}`)
}
/** `fg` at `alpha` over `bg`, for the translucent tokens (dividers, pressed). */
export function over(bg: RGB, v: string): RGB {
  const m = v.match(/^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([\d.]+)\)$/)
  if (!m) return rgb(v)
  const a = Number(m[4])
  return bg.map((b, i) => Math.round(Number(m[i + 1]) * a + b * (1 - a))) as RGB
}
export const mix = (a: RGB, b: RGB, t: number) => a.map((x, i) => Math.round(x * (1 - t) + b[i] * t)) as RGB
