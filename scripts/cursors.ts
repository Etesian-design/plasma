// The Etesian cursor theme: SVG cursors (KWin draws scalable cursors since Plasma 6.2), drawn here, no Nokia material.
// A near-black arrow with a white rim and softened corners, like the dark chrome; the busy cursor is an accent arc running
// round a squircle (spinners are squircles). Anything not drawn here comes from Breeze (Inherits=breeze_cursors).
//   node --experimental-strip-types scripts/cursors.ts    # writes look/cursors/Etesian-cursors/
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

const OUT = join(import.meta.dirname, '..', 'look', 'cursors', 'Etesian-cursors');
const S = 32; // nominal size; hotspots are in this grid
const FILL = '#141414', RIM = '#FFFFFF', ACCENT = '#4591FF';
const svg = (body: string) => `<svg xmlns="http://www.w3.org/2000/svg" width="${S}" height="${S}" viewBox="0 0 ${S} ${S}">${body}</svg>\n`;
/** a shape filled dark with a 2 px white rim, joints rounded (the soft corners) */
const shape = (d: string) => `<path d="${d}" fill="${FILL}" stroke="${RIM}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round"/>`;
const line = (d: string, w = 2.2, c = RIM) => `<path d="${d}" fill="none" stroke="${c}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round"/>`;
/** superellipse (n = 2.8 as measured on N9 icons) path, the squircle */
function squircle(cx: number, cy: number, r: number): string {
  const p: string[] = [];
  for (let i = 0; i <= 64; i++) {
    const t = (i / 64) * 2 * Math.PI, c = Math.cos(t), s = Math.sin(t);
    p.push(`${(cx + r * Math.sign(c) * Math.abs(c) ** (2 / 2.8)).toFixed(2)},${(cy + r * Math.sign(s) * Math.abs(s) ** (2 / 2.8)).toFixed(2)}`);
  }
  return `M${p.join('L')}Z`;
}
const ARROW = 'M5,3 L5,24 L10.5,19 L14.5,28 L18,26.5 L14,17.5 L21,17.5 Z';
/** the double arrow, pointing both ways along an angle (degrees), centred */
const DOUBLE = 'M4,16 L10,10 L10,13.5 L22,13.5 L22,10 L28,16 L22,22 L22,18.5 L10,18.5 L10,22 Z';
const MOVE = 'M3,16 L8,11.5 L8,14.6 L24,14.6 L24,11.5 L29,16 L24,20.5 L24,17.4 L8,17.4 L8,20.5 Z'; // slimmer: four heads that do not touch
const resize = (deg: number) => `<g transform="rotate(${deg} 16 16)">${shape(DOUBLE)}</g>`;

type Frame = string;
const cursors: Record<string, { hot: [number, number]; frames: Frame[]; delay?: number; aliases?: string[] }> = {
  default: { hot: [5, 3], frames: [svg(shape(ARROW))], aliases: ['left_ptr', 'arrow', 'top_left_arrow'] },
  pointer: { hot: [12, 4], frames: [svg(shape('M10,15 L10,6 a2.2,2.2 0 0 1 4.4,0 L14.4,13 L21,14 a3,3 0 0 1 2.6,3.2 L22.5,24 a4,4 0 0 1 -4,3.6 L14,27.6 a4,4 0 0 1 -3.2,-1.6 L6.6,20 a2,2 0 0 1 3.4,-2.3 Z'))], aliases: ['hand1', 'hand2', 'pointing_hand'] },
  text: { hot: [16, 16], frames: [svg(line('M12,6 Q16,6 16,9 L16,23 Q16,26 12,26 M20,6 Q16,6 16,9 M20,26 Q16,26 16,23', 4, FILL) + line('M12,6 Q16,6 16,9 L16,23 Q16,26 12,26 M20,6 Q16,6 16,9 M20,26 Q16,26 16,23', 1.8, RIM))], aliases: ['xterm', 'ibeam'] },
  'not-allowed': { hot: [16, 16], frames: [svg(`<circle cx="16" cy="16" r="10" fill="${FILL}" stroke="${RIM}" stroke-width="2"/>` + line('M9.5,22.5 L22.5,9.5', 2.6, '#DA201E'))], aliases: ['forbidden', 'crossed_circle', 'no-drop'] },
  grab: { hot: [16, 14], frames: [svg(shape('M8,16 L8,11 a2,2 0 0 1 4,0 L12,9 a2,2 0 0 1 4,0 L16,9.5 a2,2 0 0 1 4,0 L20,11 a2,2 0 0 1 4,0 L24,20 a7,7 0 0 1 -7,7 L15,27 a7,7 0 0 1 -6,-3.5 L5.5,18 a2,2 0 0 1 3.4,-2 Z'))], aliases: ['openhand'] },
  grabbing: { hot: [16, 16], frames: [svg(shape('M9,15 a2,2 0 0 1 3,-1.5 a2,2 0 0 1 4,-0.5 a2,2 0 0 1 4,0 a2,2 0 0 1 4,1.5 L24,20 a7,7 0 0 1 -7,7 L15,27 a7,7 0 0 1 -6,-4 Z'))], aliases: ['closedhand', 'dnd-move'] },
  // the rims of both arrows first, then both fills on top, so no rim line crosses the middle
  move: { hot: [16, 16], frames: [svg(['stroke', 'fill'].map((layer) => [0, 90].map((deg) => `<g transform="rotate(${deg} 16 16)"><path d="${MOVE}" fill="${layer === 'fill' ? FILL : 'none'}" stroke="${layer === 'stroke' ? RIM : 'none'}" stroke-width="2" stroke-linejoin="round"/></g>`).join('')).join(''))], aliases: ['fleur', 'all-scroll', 'size_all'] },
  crosshair: { hot: [16, 16], frames: [svg(line('M16,4 L16,13 M16,19 L16,28 M4,16 L13,16 M19,16 L28,16', 4, FILL) + line('M16,4 L16,13 M16,19 L16,28 M4,16 L13,16 M19,16 L28,16', 1.8))], aliases: ['cross', 'tcross'] },
  help: { hot: [5, 3], frames: [svg(shape(ARROW) + `<circle cx="24" cy="24" r="6.5" fill="${ACCENT}" stroke="${RIM}" stroke-width="1.5"/>` + line('M21.8,22.3 a2.2,2.2 0 1 1 3,2 L24,25.3', 1.6) + `<circle cx="24" cy="27.6" r="0.9" fill="${RIM}"/>`)], aliases: ['question_arrow', 'whats_this', 'left_ptr_help'] },
  'ew-resize': { hot: [16, 16], frames: [svg(resize(0))], aliases: ['col-resize', 'e-resize', 'w-resize', 'sb_h_double_arrow', 'size_hor', 'split_h', 'left_side', 'right_side'] },
  'ns-resize': { hot: [16, 16], frames: [svg(resize(90))], aliases: ['row-resize', 'n-resize', 's-resize', 'sb_v_double_arrow', 'size_ver', 'split_v', 'top_side', 'bottom_side'] },
  'nwse-resize': { hot: [16, 16], frames: [svg(resize(45))], aliases: ['nw-resize', 'se-resize', 'size_fdiag', 'top_left_corner', 'bottom_right_corner'] },
  'nesw-resize': { hot: [16, 16], frames: [svg(resize(-45))], aliases: ['ne-resize', 'sw-resize', 'size_bdiag', 'top_right_corner', 'bottom_left_corner'] },
};
// busy: an accent arc running round a squircle, 12 frames; progress: the arrow with the small spinner
const ring = squircle(16, 16, 9), small = squircle(24, 24, 5.5);
const spin = (path: string, i: number, w: number) =>
  `<path d="${path}" fill="none" stroke="${FILL}" stroke-width="${w + 2}"/><path d="${path}" fill="none" stroke="${RIM}" stroke-opacity="0.35" stroke-width="${w}"/>` +
  `<path d="${path}" pathLength="120" fill="none" stroke="${ACCENT}" stroke-width="${w}" stroke-linecap="round" stroke-dasharray="34 86" stroke-dashoffset="${-i * 10}"/>`;
cursors.wait = { hot: [16, 16], frames: Array.from({ length: 12 }, (_, i) => svg(spin(ring, i, 3.2))), delay: 70, aliases: ['watch', 'busy'] };
cursors.progress = { hot: [5, 3], frames: Array.from({ length: 12 }, (_, i) => svg(shape(ARROW) + spin(small, i, 2.4))), delay: 70, aliases: ['left_ptr_watch', 'half-busy', 'half_busy'] };

rmSync(OUT, { recursive: true, force: true });
mkdirSync(OUT, { recursive: true });
writeFileSync(join(OUT, 'index.theme'), '[Icon Theme]\nName=Etesian Cursors\nComment=Etesian cursors (scalable)\nInherits=breeze_cursors\n');
let n = 0;
for (const [name, c] of Object.entries(cursors)) {
  for (const id of [name, ...(c.aliases ?? [])]) {
    const dir = join(OUT, 'cursors_scalable', id);
    mkdirSync(dir, { recursive: true });
    const meta = c.frames.map((f, i) => {
      const file = c.frames.length > 1 ? `${name}-${String(i + 1).padStart(2, '0')}.svg` : `${name}.svg`;
      writeFileSync(join(dir, file), f);
      return { filename: file, hotspot_x: c.hot[0], hotspot_y: c.hot[1], nominal_size: S, ...(c.delay ? { delay: c.delay } : {}) };
    });
    writeFileSync(join(dir, 'metadata.json'), JSON.stringify(meta, null, 1) + '\n');
    n++;
  }
}
console.log(`wrote ${n} cursors to ${OUT}`);
