// The GPL icon art the Etesian icon theme is built from, fetched at a pinned commit into ~/.cache/etesian-plasma (or
// ETESIAN_ICON_CACHE) and never edited there; scripts/icons.ts recolours and lights what it takes (look/icons/Etesian/CREDITS).
// - DX (GPL-3.0, from Dex and Papirus): desktop app icons.
// - harbour-themepack-n9ish (GPL-3.0; the N9-style launcher icons by hpluslabels): the app icons of the N9's own apps.
import { execFileSync } from 'node:child_process'
import { existsSync, mkdirSync } from 'node:fs'
import { homedir } from 'node:os'
import { join } from 'node:path'

const SOURCES = {
  dx: { url: 'https://github.com/Vitor238/DX', commit: '25d0d345ed6d4e6a2825bfc77ab7575fcf6f348c' },
  n9ish: { url: 'https://github.com/speactra/harbour-themepack-n9ish', commit: 'fac1be07f1640b58f5fb0e06586efb812b390cf9' },
  // Pebble (GPL-3.0 per its README; folders after Hatter, GPL-3.0): folders, file types, devices, status.
  pebble: { url: 'https://github.com/abhijeetshewale05/Pebble-Icon-Theme', commit: '185da58c2f4caf3c2a038aa0869fd2772acc0933' },
} as const
export type Source = keyof typeof SOURCES

export function iconSource(name: Source): string {
  const { url, commit } = SOURCES[name]
  const dir = join(process.env.ETESIAN_ICON_CACHE || join(homedir(), '.cache/etesian-plasma'), name)
  const git = (...a: string[]) => execFileSync('git', ['-C', dir, ...a], { stdio: ['ignore', 'pipe', 'inherit'] }).toString().trim()
  if (existsSync(join(dir, '.git')) && git('rev-parse', 'HEAD') === commit) return dir
  mkdirSync(dir, { recursive: true })
  if (!existsSync(join(dir, '.git'))) git('init', '-q')
  git('fetch', '-q', '--depth', '1', url, commit)
  git('checkout', '-q', '--force', commit)
  return dir
}

export const SOURCE_INFO = SOURCES
