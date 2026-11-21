// Generates the Etesian icon theme from the etesian-design line icons (src/components/icons.ts: original drawings, AGPL-3.0-only, not
// Nokia's) and app colours (src/shell/parts/data.ts):
// - app icons: the N9 lit squircle (src/lighting.ts: tile gradient from the app colour, top rim, off-white glyph with its own
//   gradient and a short cast shadow), the glyph at half the tile;
// - symbolic icons (actions, status): the line glyph under the freedesktop names, recoloured by Plasma (ColorScheme-Text).
// Everything else comes from Breeze (Inherits).
// Usage: node --experimental-strip-types scripts/icons.ts [path/to/design-repo]  ->  look/icons/Etesian/

import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import { join } from 'node:path'
import { designRepo } from './design.ts'

const design = designRepo(process.argv[2])
// The app drawings (src/components/app-art.ts), shared with the web shell's HdAppIcon.
const { APP_ART, ART_ACCENTS, appArtFragment } = await import(join(design, 'src/components/app-art.ts'))
const out = join(import.meta.dirname, '../look/icons/Etesian')

// The design's glyphs: `name: 'path'` (stroke-only, 24 px grid, 2 px round strokes).
const src = readFileSync(join(design, 'src/components/icons.ts'), 'utf8')
const glyphs: Record<string, string> = {}
for (const m of src.matchAll(/^\s+'?([a-z-]+)'?: '([^']+)'/gm)) glyphs[m[1]!] = m[2]!
// Drawn here in the same style, for desktop apps the phone does not have.
glyphs.terminal = 'M4 6l5 5-5 5M11 17h9'
glyphs.calculator = 'M6 3h12v18H6zM9 7h6M9 12h.01M12 12h.01M15 12h.01M9 16h.01M12 16h.01M15 16h.01'
glyphs.document = 'M6 3h8l4 4v14H6zM14 3v4h4M9 12h6M9 16h6'
glyphs.archive = 'M4 4h16v4H4zM5 8h14v12H5zM10 12h4'
glyphs.film = 'M4 4h16v16H4zM8 4v16M16 4v16M4 8h4M4 12h4M4 16h4M16 8h4M16 12h4M16 16h4'
glyphs.brush = 'M14 4l6 6-7 7-6-6zM7 11c-2 1-3 3-3 6v3h3c3 0 5-1 6-3'
glyphs.disk = 'M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18zM12 12V3M12 12l7.8 4.5'
glyphs.scanner = 'M3 13h18v6H3zM5 13l2-8h10l2 8M7 16h4'
glyphs.cards = 'M8 5h9l-3 16H5zM13 3h6l-1 6M9.5 11.5l1 2.5 2-2'
glyphs.dice = 'M4 4h16v16H4zM8.5 8.5h.01M15.5 8.5h.01M12 12h.01M8.5 15.5h.01M15.5 15.5h.01'
glyphs.mine = 'M12 7a5 5 0 1 1 0 10 5 5 0 0 1 0-10zM12 3v3M12 18v3M3 12h3M18 12h3M5.6 5.6l2.1 2.1M16.3 16.3l2.1 2.1M5.6 18.4l2.1-2.1M16.3 7.7l2.1-2.1'
glyphs.tiles = 'M4 6h7v12H4zM13 6h7v12h-7zM7.5 10h.01M16.5 14h.01'
glyphs.sudoku = 'M4 4h16v16H4zM9.3 4v16M14.7 4v16M4 9.3h16M4 14.7h16'
glyphs.keyboard = 'M3 7h18v11H3zM6 10h.01M9 10h.01M12 10h.01M15 10h.01M18 10h.01M7 14h10'
glyphs.letter = 'M5 20l7-16 7 16M8 14h8'
glyphs.log = 'M5 3h14v18H5zM8 7h8M8 11h8M8 15h5'
glyphs.remote = 'M3 4h18v12H3zM8 20h8M12 16v4M9 10h6M13 8l2 2-2 2'
glyphs.download = 'M12 3v12M7 10l5 5 5-5M4 20h16'
glyphs.usb = 'M12 3v15M9 6l3-3 3 3M12 13l-4-2V8M12 15l4-2v-3M10.5 18.5a1.5 1.5 0 1 0 3 0 1.5 1.5 0 0 0-3 0z'
glyphs.sheet = 'M4 4h16v16H4zM4 9h16M4 14h16M10 4v16'
glyphs.slides = 'M3 4h18v12H3zM12 16v4M8 20h8M7 8h6M7 12h10'
glyphs.shapes = 'M4 13h7v7H4zM16.5 4l4.5 8h-9zM17 15a2.5 2.5 0 1 1 0 5 2.5 2.5 0 0 1 0-5z'
glyphs.formula = 'M17 5H7l5 7-5 7h10'
glyphs.menu = 'M4 6h16M4 12h10M4 18h16'
glyphs.bug = 'M8 8h8v9a4 4 0 0 1-8 0zM9 8a3 3 0 0 1 6 0M4 12h4M16 12h4M5 18l3-2M19 18l-3-2M5 6l3 2M19 6l-3 2'
glyphs.vm = 'M3 4h18v12H3zM8 20h8M12 16v4M8 8h8v4H8z'
glyphs.package = 'M12 3l8 4.5v9L12 21l-8-4.5v-9zM4 7.5l8 4.5 8-4.5M12 12v9'
glyphs.emoji = 'M12 3a9 9 0 1 1 0 18 9 9 0 0 1 0-18zM8.5 14a4 4 0 0 0 7 0M9 9.5h.01M15 9.5h.01'
glyphs.bell = 'M6 16V11a6 6 0 0 1 12 0v5l2 2H4zM10 20a2 2 0 0 0 4 0'
glyphs.pen = 'M4 20l4-1L19 8l-3-3L5 16zM14 7l3 3'
glyphs.font = 'M4 20l5-14h2l5 14M6 15h8M17 11h4M19 9v6'
glyphs.vpn = 'M12 3l8 3v6c0 5-3.5 8-8 9-4.5-1-8-4-8-9V6zM9 12l2 2 4-4'

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
  const art = APP_ART[glyph], g = glyphs[glyph]
  if (!art && !g) throw new Error(`no glyph ${glyph}`)
  const ink = tone === 'light' ? ['#3A3A3A', '#2A2A2A', '#1A1A1A'] : GLYPH
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">
<defs>
<linearGradient id="tile" x1="0" y1="${S * 0.1}" x2="0" y2="${S * 0.72}" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="${p.top}"/><stop offset="1" stop-color="${p.bottom}"/></linearGradient>
<linearGradient id="ink" x1="0" y1="${art ? 8 : 12}" x2="0" y2="${art ? 40 : 36}" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="${ink[0]}"/><stop offset=".5" stop-color="${ink[1]}"/><stop offset="1" stop-color="${ink[2]}"/></linearGradient>
<linearGradient id="rim" x1="0" y1="0" x2="0" y2="${S}" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#FFFFFF" stop-opacity=".55"/><stop offset=".025" stop-color="#FFFFFF" stop-opacity="0"/><stop offset=".975" stop-color="#FFFFFF" stop-opacity="0"/><stop offset="1" stop-color="#FFFFFF" stop-opacity=".06"/></linearGradient>
</defs>
<path d="${squircle(S)}" fill="url(#tile)"/>
<path d="${squircle(S)}" fill="url(#rim)"/>
${art ? appArtFragment(glyph, { ink: 'url(#ink)', cut: p.bottom, ...ART_ACCENTS }, S)
  : `<g transform="translate(12 12.7)" fill="none" stroke="#000000" stroke-opacity=".22" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"><path d="${g}"/></g>
<g transform="translate(12 12)" fill="none" stroke="url(#ink)" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="${g}"/></g>`}
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

// App icons: the Icon= names of common desktop apps → [drawing (app-art.ts; a line glyph if there is none), colour (data.ts), tone].
const APPS: [string[], string, string, ('colour' | 'light')?][] = [
  [['system-file-manager', 'org.kde.dolphin', 'dolphin', 'org.gnome.Nautilus'], 'files', '#7B7B7B'],           // Files
  [['utilities-terminal', 'org.kde.konsole', 'konsole', 'org.gnome.Terminal'], 'terminal', '#505050'],
  [['accessories-text-editor', 'org.kde.kate', 'kate', 'org.kde.kwrite', 'kwrite'], 'notes', '#F2B111'],        // Notes
  [['preferences-system', 'systemsettings', 'org.kde.systemsettings'], 'settings', '#505050'],                // Settings
  [['internet-web-browser', 'firefox', 'org.mozilla.firefox', 'chromium', 'google-chrome', 'org.kde.falkon', 'falkon'], 'globe', '#2EA8C7'], // Browser
  [['internet-mail', 'thunderbird', 'org.mozilla.Thunderbird', 'org.kde.kmail2', 'kmail'], 'mail', '#0067BC'],  // Mail
  [['office-calendar', 'org.kde.merkuro.calendar', 'org.kde.korganizer', 'korganizer'], 'calendar', '#EF5500'], // Calendar
  [['x-office-address-book', 'org.kde.kaddressbook', 'kaddressbook', 'org.kde.merkuro.contact'], 'person', '#007DC9'], // Contacts
  [['multimedia-photo-viewer', 'org.kde.gwenview', 'gwenview', 'org.kde.koko'], 'photo', '#821DDE'],          // Gallery
  [['multimedia-audio-player', 'org.kde.elisa', 'elisa'], 'music', '#CC09BA'],                                 // Music
  [['multimedia-video-player', 'org.kde.haruna', 'haruna', 'vlc', 'mpv', 'org.kde.dragonplayer'], 'videos', '#D9001E'], // Videos
  [['system-software-install', 'org.kde.discover', 'plasmadiscover'], 'store', '#1C51AF'],                       // Store
  [['org.kde.kclock', 'kclock'], 'clock', '#FFFFFF', 'light'],                                                  // Clock
  [['accessories-calculator', 'org.kde.kcalc', 'kcalc', 'org.kde.kalk'], 'calculator', '#EFBB00'],
  [['accessories-screenshot', 'org.kde.spectacle', 'spectacle'], 'camera', '#505050'],
  [['org.kde.kdeconnect', 'kdeconnect', 'kdeconnect.app'], 'phone', '#62B700'],                               // Phone
  [['utilities-system-monitor', 'org.kde.plasma-systemmonitor', 'ksysguard'], 'monitor', '#505050'],
  [['org.kde.kinfocenter', 'hwinfo', 'help-about'], 'info', '#7B7B7B'],
  [['help-browser', 'org.kde.help', 'khelpcenter'], 'help', '#2EA8C7'],
  [['internet-chat', 'org.kde.neochat', 'org.kde.konversation', 'konversation', 'org.telegram.desktop', 'signal-desktop'], 'chat', '#09A7CC'], // Messages
  [['org.kde.marble', 'marble', 'org.kde.itinerary'], 'maps', '#60AD00'],                                  // Maps
  [['org.kde.kwalletmanager', 'kwalletmanager', 'kwalletmanager2'], 'security', '#505050'],                         // Security
  [['preferences-system-bluetooth', 'bluedevil', 'blueman'], 'sharing', '#0093D0'],                          // Sharing
  [['org.kde.okular', 'okular', 'office-document', 'x-office-document'], 'document', '#D9001E'],
  [['org.kde.kweather', 'kweather'], 'weather', '#007DC9'],
  // KDE Gear and the other desktop apps the N9 had no counterpart for: the same lit squircle, a glyph drawn in the same style.
  [['org.kde.ark', 'ark', 'utilities-file-archiver', 'file-roller', 'org.gnome.FileRoller'], 'archive', '#EF5500'],
  [['org.kde.konqueror', 'konqueror'], 'webfiles', '#1C51AF'],
  [['org.kde.kontact', 'kontact'], 'mail', '#09A7CC'],
  [['org.kde.krita', 'krita'], 'brush', '#CC09BA'],
  [['org.kde.kdenlive', 'kdenlive'], 'film', '#505050'],
  [['org.kde.kolourpaint', 'kolourpaint'], 'brush', '#EF5500'],
  [['org.kde.partitionmanager', 'partitionmanager', 'gparted', 'org.kde.filelight', 'filelight', 'baobab'], 'disk', '#7B7B7B'],
  [['org.kde.skanpage', 'skanpage', 'org.kde.skanlite', 'skanlite', 'simple-scan', 'scanner'], 'scanner', '#505050'],
  [['org.kde.kpat', 'kpat'], 'cards', '#60AD00'],
  [['org.kde.kmines', 'kmines'], 'mine', '#7B7B7B'],
  [['org.kde.kmahjongg', 'kmahjongg'], 'tiles', '#D9001E'],
  [['org.kde.ksudoku', 'ksudoku'], 'sudoku', '#0067BC'],
  [['org.kde.kbounce', 'org.kde.kblocks', 'org.kde.knights', 'org.kde.kreversi', 'org.kde.bovo', 'org.kde.knetwalk', 'applications-games'], 'dice', '#821DDE'],
  [['org.kde.kcharselect', 'kcharselect', 'accessories-character-map', 'gucharmap'], 'letter', '#505050'],
  [['org.kde.ksystemlog', 'ksystemlog', 'org.kde.kjournaldbrowser', 'utilities-log-viewer', 'org.gnome.Logs'], 'log', '#7B7B7B'],
  [['org.kde.krdc', 'krdc', 'org.remmina.Remmina', 'remmina', 'org.kde.krfb', 'krfb'], 'remote', '#0093D0'],
  [['org.kde.ktorrent', 'ktorrent', 'qbittorrent', 'org.qbittorrent.qBittorrent', 'transmission-qt', 'filezilla'], 'download', '#62B700'],
  [['org.kde.isoimagewriter', 'usb-creator-kde', 'usb-creator-gtk'], 'usb', '#505050'],
  [['org.kde.kmenuedit', 'kmenuedit'], 'menu', '#7B7B7B'],
  [['org.kde.drkonqi', 'tools-report-bug', 'apport', 'org.kde.kbugbuster'], 'bug', '#D9001E'],
  [['virtualbox', 'org.virtualbox.VirtualBox', 'org.gnome.Boxes', 'virt-manager'], 'vm', '#1C51AF'],
  [['synaptic', 'kubuntu-manage-software', 'jockey', 'org.kde.kpackagekit'], 'package', '#EF5500'],
  [['org.kde.qrca', 'qrca'], 'qr', '#505050'],
  [['org.kde.kalzium', 'kalzium', 'org.kde.kalgebra', 'kalgebra', 'libreoffice-math'], 'formula', '#EFBB00'],
  [['libreoffice-writer', 'libreoffice-startcenter', 'org.kde.calligrawords'], 'document', '#0067BC'],
  [['libreoffice-calc', 'org.kde.calligrasheets'], 'sheet', '#60AD00'],
  [['libreoffice-impress', 'org.kde.calligrastage'], 'slides', '#EF5500'],
  [['libreoffice-draw', 'org.kde.karbon'], 'shapes', '#EFBB00'],
  [['org.kde.kgpg', 'kgpg', 'org.kde.kleopatra', 'kleopatra', 'piavpn'], 'shield', '#505050'],
  [['org.kde.plasma.emojier', 'preferences-desktop-emoticons'], 'emoji', '#EFBB00'],
  [['preferences-desktop-notification'], 'bell', '#EF5500'],
  [['preferences-desktop-tablet'], 'pen', '#505050'],
  [['input-keyboard', 'org.kde.ktouch', 'ktouch', 'preferences-desktop-keyboard'], 'keyboard', '#7B7B7B'],
  [['org.kde.kfontview', 'kfontview', 'preferences-desktop-font', 'org.gnome.font-viewer'], 'font', '#505050'],
  [['org.kde.kamoso', 'kamoso', 'org.gnome.Cheese', 'cheese'], 'camera', '#D9001E'],
  [['org.kde.kget', 'kget'], 'download', '#0093D0'],
  [['org.kde.kompare', 'kompare', 'org.kde.kdiff3', 'meld'], 'split', '#7B7B7B'],
  [['org.kde.kfind', 'kfind', 'catfish'], 'search', '#7B7B7B'],
  [['org.kde.kruler', 'kruler', 'org.kde.kmag', 'kmag', 'org.kde.kcolorchooser', 'kcolorchooser'], 'wrench', '#505050'],
  [['org.kde.kgamma', 'org.kde.kmousetool', 'org.kde.kmouth', 'preferences-desktop-accessibility'], 'accessibility', '#0093D0'],
  [['org.kde.kteatime', 'kteatime'], 'hourglass', '#EF5500'],
  [['org.kde.kalarm', 'kalarm'], 'alarm', '#EF5500'],
  [['org.kde.knotes', 'knotes', 'org.kde.marknote'], 'notes', '#EFBB00'],
  [['org.kde.akregator', 'akregator'], 'rss', '#EF5500'],
  [['org.kde.kasts', 'kasts', 'org.kde.audiotube', 'org.kde.juk', 'juk', 'org.kde.amarok', 'amarok'], 'music', '#CC09BA'],
  [['org.kde.kdevelop', 'kdevelop', 'gvim', 'code'], 'terminal', '#1C51AF'],
  [['htop', 'org.kde.ksysguard', 'mini.xterm', 'xterm', 'MidnightCommander', 'mc'], 'terminal', '#505050'],
  [['qpdfview', 'org.kde.arianna', 'arianna', 'calibre-gui', 'org.gnome.Evince', 'evince'], 'document', '#D9001E'],
  [['org.gnome.Firmware'], 'power', '#505050'],
  [['org.kde.mobile.plasmasettings', 'preferences-desktop'], 'settings', '#505050'],
  [['org.kde.tokodon', 'tokodon'], 'chat', '#821DDE'],
  [['org.kde.ktrip', 'ktrip'], 'maps', '#60AD00'],
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
