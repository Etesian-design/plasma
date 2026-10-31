// Where the Etesian design repo (the Storybook: tokens, icons, app colours) is checked out. The generators take it as their
// first argument or ETESIAN_DESIGN; otherwise a sibling folder, under its GitHub name (storybook) or its old local one.
import { existsSync } from 'node:fs'
import { join } from 'node:path'

export function designRepo(arg?: string): string {
  const tried = [arg, process.env.ETESIAN_DESIGN, ...['storybook', 'etesian-design'].map((n) => join(import.meta.dirname, '../..', n))]
    .filter((p): p is string => !!p)
  const found = tried.find((p) => existsSync(join(p, 'src/styles/tokens.css')))
  if (!found) throw new Error(`Etesian design repo not found (looked in ${tried.join(', ')}); pass its path or set ETESIAN_DESIGN`)
  return found
}
