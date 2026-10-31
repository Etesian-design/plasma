// Generates the Etesian icon theme from the etesian-design line icons (src/components/icons.ts: original drawings, MIT, not
// Nokia's) and app colours (src/stories/explorations/parts/data.ts):
// - app icons: the N9 lit squircle (src/lighting.ts: tile gradient from the app colour, top rim, off-white glyph with its own
//   gradient and a short cast shadow), the glyph at half the tile;
// - symbolic icons (actions, status): the line glyph under the freedesktop names, recoloured by Plasma (ColorScheme-Text).
// Everything else comes from Breeze (Inherits).
// Usage: node --experimental-strip-types scripts/icons.ts [path/to/design-repo]  ->  look/icons/Etesian/

import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { designRepo } from './design.ts'

const design = designRepo(process.argv[2])
const out = join(import.meta.dirname, '../look/icons/Etesian')

// The design's glyphs: `name: 'path'` (stroke-only, 24 px grid, 2 px round strokes).
const src = readFileSync(join(design, 'src/components/icons.ts'), 'utf8')
const glyphs: Record<string, string> = {}
for (const m of src.matchAll(/^\s+'?([a-z-]+)'?: '([^']+)'/gm)) glyphs[m[1]!] = m[2]!
// Drawn here in the same style, for desktop apps the phone does not have.
glyphs.terminal = 'M4 6l5 5-5 5M11 17h9'
glyphs.calculator = 'M6 3h12v18H6zM9 7h6M9 12h.01M12 12h.01M15 12h.01M9 16h.01M12 16h.01M15 16h.01'
glyphs.document = 'M6 3h8l4 4v14H6zM14 3v4h4M9 12h6M9 16h6'

// --- lighting (src/lighting.ts and the icon.lighting tokens) ---
const LIGHTNESS = 0.12, HUE_SHIFT = 12
const GLYPH = ['#F6F8ED', '#EAE9E3', '#D0C9C6']
function rgb(hex: string): [number, number, number] { const n = parseInt(hex.slice(1), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255] }
function toHsl([r, g, b]: [number, number, number]): [number, number, number] {
  r /= 255; g /= 255; b /= 255
  const max = Math.max(r, g, b), min = Math.min(r, g, b), l = (max + min) / 2
  if (max === min) return [0, 0, l]
  const d = max - min, s = l > 0.5 ? d / (2 - max - min) : d / (max + min)
  const h = max === r ? (g - b) / d + (g < b ? 6 : 0) : max === g ? (b - r) / d + 2 : (r - g) / d + 4
  return [h * 60, s, l]
}
const clamp = (v: number) => Math.min(1, Math.max(0, v))
/** hsl → #rrggbb (Qt's SVG renderer does not read hsl()) */
function hex(h: number, s: number, l: number): string {
  h = ((h % 360) + 360) % 360; s = clamp(s); l = clamp(l)
  const a = s * Math.min(l, 1 - l), f = (n: number) => { const k = (n + h / 30) % 12; return l - a * Math.max(-1, Math.min(k - 3, 9 - k, 1)) }
  return '#' + [f(0), f(8), f(4)].map(v => Math.round(v * 255).toString(16).padStart(2, '0')).join('')
}
const hueDist = (a: number, b: number) => ((b - a + 540) % 360) - 180
function lit(accent: string): { top: string; bottom: string } {
  const [h, s, l] = toHsl(rgb(accent)), d = LIGHTNESS
  if (s < 0.12) return { top: hex(h, s, l + d * 0.7), bottom: hex(h, s, l - d * 0.5) }
  const anchor = Math.abs(hueDist(h, 60)) < Math.abs(hueDist(h, 190)) ? 60 : 190
  const dist = hueDist(h, anchor), shift = Math.sign(dist) * Math.min(Math.abs(dist), HUE_SHIFT), up = anchor === 60 ? 0.85 : 0.4
  return { top: hex(h + shift * up, anchor === 60 ? s : s * 0.82, l + d * 0.55), bottom: hex(h - shift * (1.6 - up), Math.min(1, s * 1.05), l - d * 0.45) }
}

/** the N9 squircle, a superellipse with n = 2.8 (measured on N9 icons), as a path in a size × size box */
function squircle(size: number): string {
  const r = size / 2, pts: string[] = []
  for (let i = 0; i < 96; i++) {
    const t = (i / 96) * 2 * Math.PI, c = Math.cos(t), s = Math.sin(t)
    pts.push(`${(r + r * Math.sign(c) * Math.pow(Math.abs(c), 2 / 2.8)).toFixed(2)},${(r + r * Math.sign(s) * Math.pow(Math.abs(s), 2 / 2.8)).toFixed(2)}`)
  }
  return 'M' + pts.join('L') + 'Z'
}

function appIcon(glyph: string, color: string, tone: 'colour' | 'light' = 'colour'): string {
  const S = 48, p = tone === 'light' ? { top: '#FFFFFF', bottom: '#DADADA' } : lit(color)
  const g = glyphs[glyph]
  if (!g) throw new Error(`no glyph ${glyph}`)
  const ink = tone === 'light' ? ['#3A3A3A', '#2A2A2A', '#1A1A1A'] : GLYPH
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
<defs>
<linearGradient id="tile" x1="0" y1="${S * 0.1}" x2="0" y2="${S * 0.72}" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="${p.top}"/><stop offset="1" stop-color="${p.bottom}"/></linearGradient>
<linearGradient id="ink" x1="0" y1="12" x2="0" y2="36" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="${ink[0]}"/><stop offset=".5" stop-color="${ink[1]}"/><stop offset="1" stop-color="${ink[2]}"/></linearGradient>
<linearGradient id="rim" x1="0" y1="0" x2="0" y2="${S}" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".55"/><stop offset=".025" stop-color="#FFFFFF" stop-opacity="0"/><stop offset=".975" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".06"/></linearGradient>
</defs>
<path d="${squircle(S)}" fill="url(#tile)"/>
<path d="${squircle(S)}" fill="url(#rim)"/>
<g transform="translate(12 12.7)" fill="none" stroke="#000000" stroke-opacity=".22" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="${g}"/></g>
<g transform="translate(12 12)" fill="none" stroke="url(#ink)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${g}"/></g>
</svg>
`
}

function symbolic(glyph: string): string {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24">
<style id="current-color-scheme">.ColorScheme-Text { color:#232629; }</style>
<path class="ColorScheme-Text" d="${glyphs[glyph]}" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>
`
}

// App icons: the Icon= names of common desktop apps → [glyph, colour (data.ts), tone].
const APPS: [string[], string, string, ('colour' | 'light')?][] = [
  [['system-file-manager', 'org.kde.dolphin', 'dolphin', 'org.gnome.Nautilus'], 'folder', '#7B7B7B'],           // Files
  [['utilities-terminal', 'org.kde.konsole', 'konsole', 'org.gnome.Terminal'], 'terminal', '#505050'],
  [['accessories-text-editor', 'org.kde.kate', 'kate', 'org.kde.kwrite', 'kwrite'], 'edit', '#F2B111'],        // Notes
  [['preferences-system', 'systemsettings', 'org.kde.systemsettings'], 'settings', '#505050'],                // Settings
  [['internet-web-browser', 'firefox', 'org.mozilla.firefox', 'chromium', 'google-chrome', 'org.kde.falkon', 'falkon'], 'globe', '#2EA8C7'], // Browser
  [['internet-mail', 'thunderbird', 'org.mozilla.Thunderbird', 'org.kde.kmail2', 'kmail'], 'mail', '#0067BC'],  // Mail
  [['office-calendar', 'org.kde.merkuro.calendar', 'org.kde.korganizer', 'korganizer'], 'calendar', '#EF5500'], // Calendar
  [['x-office-address-book', 'org.kde.kaddressbook', 'kaddressbook', 'org.kde.merkuro.contact'], 'person', '#007DC9'], // Contacts
  [['multimedia-photo-viewer', 'org.kde.gwenview', 'gwenview', 'org.kde.koko'], 'photo', '#821DDE'],          // Gallery
  [['multimedia-audio-player', 'org.kde.elisa', 'elisa'], 'music', '#CC09BA'],                                 // Music
  [['multimedia-video-player', 'org.kde.haruna', 'haruna', 'vlc', 'mpv', 'org.kde.dragonplayer'], 'play', '#D9001E'], // Videos
  [['system-software-install', 'org.kde.discover', 'plasmadiscover'], 'bag', '#1C51AF'],                       // Store
  [['org.kde.kclock', 'kclock'], 'clock', '#FFFFFF', 'light'],                                                  // Clock
  [['accessories-calculator', 'org.kde.kcalc', 'kcalc', 'org.kde.kalk'], 'calculator', '#EFBB00'],
  [['accessories-screenshot', 'org.kde.spectacle', 'spectacle'], 'camera', '#505050'],
  [['org.kde.kdeconnect', 'kdeconnect', 'kdeconnect.app'], 'phone', '#62B700'],                               // Phone
  [['utilities-system-monitor', 'org.kde.plasma-systemmonitor', 'ksysguard'], 'data', '#505050'],
  [['org.kde.kinfocenter', 'hwinfo', 'help-about'], 'info', '#7B7B7B'],
  [['help-browser', 'org.kde.help', 'khelpcenter'], 'info', '#2EA8C7'],
  [['internet-chat', 'org.kde.neochat', 'org.kde.konversation', 'konversation', 'org.telegram.desktop', 'signal-desktop'], 'message', '#09A7CC'], // Messages
  [['org.kde.marble', 'marble', 'org.kde.itinerary'], 'location', '#60AD00'],                                  // Maps
  [['org.kde.kwalletmanager', 'kwalletmanager', 'kwalletmanager2'], 'lock', '#505050'],                         // Security
  [['preferences-system-bluetooth', 'bluedevil', 'blueman'], 'bluetooth', '#0093D0'],                          // Sharing
  [['org.kde.okular', 'okular', 'office-document', 'x-office-document'], 'document', '#D9001E'],
  [['org.kde.kweather', 'kweather'], 'moon', '#007DC9'],
]

// Symbolic: freedesktop names → glyph. Each is written as name and name-symbolic.
const SYMBOLIC: Record<string, string> = {
  'go-previous': 'back', 'go-next': 'chevron-right', 'go-down': 'chevron-down', 'arrow-left': 'back', 'arrow-right': 'chevron-right',
  'arrow-down': 'chevron-down', 'application-menu': 'more', 'overflow-menu': 'more', 'list-add': 'add', 'window-close': 'close',
  'dialog-close': 'close', 'dialog-ok': 'check', 'checkmark': 'check', 'edit-find': 'search', 'system-search': 'search',
  'document-edit': 'edit', 'edit-delete': 'delete', 'user-trash': 'delete', 'document-share': 'share', 'view-refresh': 'refresh',
  'configure': 'settings', 'settings-configure': 'settings', 'airplane-mode': 'flight', 'mark-location': 'location',
  'media-record': 'record', 'network-wireless-hotspot': 'hotspot', 'audio-input-microphone': 'mic', 'camera-photo': 'camera',
  'view-barcode-qr': 'qr', 'preferences-desktop-accessibility': 'accessibility', 'audio-volume-high': 'speaker',
  'audio-headphones': 'headset', 'system-shutdown': 'power', 'system-reboot': 'restart', 'folder': 'folder', 'tools': 'wrench',
  'mail-attachment': 'attach', 'face-smile': 'smile', 'view-list-details': 'list', 'edit-clear': 'backspace', 'call-start': 'phone',
  'mail-message': 'mail', 'user-identity': 'person', 'go-home': 'home', 'view-calendar': 'calendar', 'chronometer': 'clock',
  'clock': 'clock', 'image-x-generic': 'photo', 'dialog-information': 'info', 'dialog-warning': 'warning',
  'network-wireless': 'wifi', 'internet-services': 'globe', 'object-locked': 'lock', 'starred': 'star', 'bookmark-new': 'star',
  'network-bluetooth': 'bluetooth', 'media-playback-start': 'play', 'view-split-left-right': 'split',
  'window-maximize': 'maximize', 'window-minimize': 'minimize', 'window': 'window', 'view-app-grid': 'grid',
  'notifications-disabled': 'moon', 'brightness-high': 'torch', 'document-edit-sign': 'edit',
}

rmSync(out, { recursive: true, force: true })
for (const d of ['apps/scalable', 'actions/symbolic']) mkdirSync(join(out, d), { recursive: true })
let apps = 0, sym = 0
for (const [names, glyph, color, tone] of APPS) {
  const svg = appIcon(glyph, color, tone)
  for (const n of names) { writeFileSync(join(out, 'apps/scalable', `${n}.svg`), svg); apps++ }
}
for (const [name, glyph] of Object.entries(SYMBOLIC)) {
  if (!glyphs[glyph]) throw new Error(`no glyph ${glyph} for ${name}`)
  const svg = symbolic(glyph)
  for (const n of [name, `${name}-symbolic`]) { writeFileSync(join(out, 'actions/symbolic', `${n}.svg`), svg); sym++ }
}
writeFileSync(join(out, 'index.theme'), `[Icon Theme]
Name=Etesian
Comment=Lit squircle app icons and thin line symbols from the Etesian Design Language; everything else from Breeze
Inherits=breeze-dark,breeze,hicolor
DisplayDepth=32
DesktopDefault=48
ToolbarDefault=22
MainToolbarDefault=22
SmallDefault=16
PanelDefault=48
DialogDefault=32
FollowsColorScheme=true
Directories=apps/scalable,actions/symbolic

[apps/scalable]
Size=48
MinSize=16
MaxSize=512
Context=Applications
Type=Scalable

[actions/symbolic]
Size=24
MinSize=16
MaxSize=256
Context=Actions
Type=Scalable
`)
// The dock and the launcher draw a squircle behind other apps' icons; these already are squircles.
const names = APPS.flatMap(([n]) => n).sort()
for (const w of ['org.etesian.dock', 'org.etesian.launcher'])
  writeFileSync(join(import.meta.dirname, `../look/plasmoids/${w}/contents/ui/etesianicons.js`),
    `// Generated by scripts/icons.ts: icon names and app ids the Etesian icon theme draws as lit squircles.\n.pragma library\nvar names = ${JSON.stringify(names)}\nfunction has(n) { return names.indexOf(String(n).replace(/^applications:/, "").replace(/\\.desktop$/, "")) >= 0 }\n`)
console.log(`look/icons/Etesian: ${apps} app icons, ${sym} symbolic icons`)
