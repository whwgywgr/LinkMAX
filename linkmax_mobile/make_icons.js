/* Generates the Android adaptive icon foreground (white link glyph on transparent). */
const path = require('path');
const fs = require('fs');
const sharp = require(path.join(__dirname, '..', 'node_modules', 'sharp'));

const FOREGROUND_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 432 432" width="432" height="432">
  <g transform="translate(-27.2 -34.8) scale(1.9)">
    <g transform="translate(128 132) rotate(-45)">
      <rect x="-70" y="-40" width="140" height="80" rx="40" fill="none" stroke="#FFFFFF" stroke-width="18"/>
    </g>
    <circle cx="112" cy="127" r="6" fill="#3730A3"/>
    <circle cx="144" cy="127" r="6" fill="#3730A3"/>
    <path d="M118 140 Q128 149 138 140" stroke="#3730A3" stroke-width="5" fill="none" stroke-linecap="round"/>
  </g>
</svg>`;

async function main() {
  const out = path.join(__dirname, 'assets', 'icon-foreground.png');
  await sharp(Buffer.from(FOREGROUND_SVG), { density: 300 }).png().toFile(out);
  console.log('FG_OK ' + out);
}

main().catch((e) => {
  console.error('FG_FAIL', e);
  process.exit(1);
});
