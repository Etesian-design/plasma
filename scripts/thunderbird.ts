// Generates the Etesian Thunderbird theme (a theme add-on) from the etesian-design tokens, like the Plasma colour schemes:
// Etesian Dark, the dark header bar over dark panes. Not the hybrid look (light pages) of the KDE apps: Thunderbird darkens its
// message list and reader under any dark frame, whatever the theme asks, so light panes would mean a light header bar.
// Usage: node --experimental-strip-types scripts/thunderbird.ts [path/to/design-repo]. Writes look/thunderbird/manifest.json;
// install.sh packs it into an .xpi (also installable by hand: Add-ons and Themes → Install Add-on From File).

import { writeFileSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { type RGB, type Tokens, root, dark, rgb, over, mix } from './tokens.ts'

const css = (c: RGB) => `rgb(${c.join(', ')})`
const accent = rgb(root['color-accent-default'])
const white: RGB = [255, 255, 255]

/** Thunderbird's theme colours: `chrome` tokens for the header, tabs and toolbars, `page` tokens for the panes and menus. */
function colors(page: Tokens, chrome: Tokens) {
  const bar = mix(rgb(chrome['c-toolbar-from']), rgb(chrome['c-toolbar-to']), 0.5) // the header gradient's middle, as colors.ts
  const barFg = rgb(chrome['c-fg'])
  const field = rgb(chrome['c-surface-raised'])
  const surface = rgb(page['c-surface']), fg = rgb(page['c-fg'])
  const divider = over(surface, page['c-divider'])
  return {
    frame: css(bar), frame_inactive: css(mix(bar, rgb(chrome['c-bg']), 0.12)),
    tab_background_text: css(barFg), tab_text: css(barFg), tab_selected: css(field), tab_line: css(accent), tab_loading: css(accent),
    toolbar: css(bar), toolbar_text: css(barFg), toolbar_top_separator: css(bar), toolbar_bottom_separator: css(bar),
    toolbar_field: css(field), toolbar_field_text: css(barFg), toolbar_field_border: css(field),
    toolbar_field_focus: css(field), toolbar_field_text_focus: css(barFg), toolbar_field_border_focus: css(accent),
    toolbar_field_highlight: css(accent), toolbar_field_highlight_text: css(white),
    button_background_hover: 'rgba(255, 255, 255, 0.12)', button_background_active: 'rgba(255, 255, 255, 0.2)',
    icons: css(barFg), icons_attention: css(accent),
    sidebar: css(surface), sidebar_text: css(fg), sidebar_border: css(divider),
    sidebar_highlight: css(accent), sidebar_highlight_text: css(white),
    popup: css(surface), popup_text: css(fg), popup_border: css(divider), popup_highlight: css(accent), popup_highlight_text: css(white),
  }
}

const manifest = {
  manifest_version: 2,
  name: 'Etesian',
  version: '1.0',
  description: 'The Etesian look: the dark header bar and panes, with the Etesian blue.',
  author: 'Etesian',
  homepage_url: 'https://etesian-design.com',
  browser_specific_settings: { gecko: { id: 'theme@etesian-design.com', strict_min_version: '128.0' } },
  theme: { colors: colors(dark, dark), properties: { color_scheme: 'dark' } },
}

const out = join(import.meta.dirname, '../look/thunderbird')
mkdirSync(out, { recursive: true })
writeFileSync(join(out, 'manifest.json'), JSON.stringify(manifest, null, 2) + '\n')
console.log('wrote', out)
