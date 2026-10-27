/* Generates build/icon.ico + PNGs from an inline SVG (pure Node, uses sharp). */
const path = require('path');
const fs = require('fs');
const sharp = require('sharp');
const pngToIco = require('png-to-ico').default;

const ICON_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <rect width="256" height="256" rx="62" fill="#8B5CF6"/>
  <g transform="translate(128 132) rotate(-45)">
    <rect x="-70" y="-40" width="140" height="80" rx="40" fill="none" stroke="#FFFFFF" stroke-width="18"/>
  </g>
  <circle cx="112" cy="127" r="6" fill="#3730A3"/>
  <circle cx="144" cy="127" r="6" fill="#3730A3"/>
  <path d="M118 140 Q128 149 138 140" stroke="#3730A3" stroke-width="5" fill="none" stroke-linecap="round"/>
  <ellipse cx="110" cy="137" rx="6.5" ry="4.5" fill="#FFB3C7"/>
  <ellipse cx="146" cy="137" rx="6.5" ry="4.5" fill="#FFB3C7"/>
  <path d="M52 40 Q54 50 64 52 Q54 54 52 64 Q50 54 42 52 Q50 50 52 40 Z" fill="#FFFFFF" opacity="0.95"/>
  <path d="M206 196 Q207.5 202.5 214 204 Q207.5 205.5 206 212 Q204.5 205.5 198 204 Q204.5 202.5 206 196 Z" fill="#FFFFFF" opacity="0.8"/>
  <circle cx="210" cy="50" r="4.5" fill="#FFFFFF" opacity="0.65"/>
</svg>`;

async function main() {
  const buildDir = path.join(__dirname, '..', 'build');
  fs.mkdirSync(buildDir, { recursive: true });

  const sizes = [256, 128, 64, 48, 32, 24, 16];
  const pngs = [];

  for (const size of sizes) {
    const png = await sharp(Buffer.from(ICON_SVG), { density: 300 })
      .resize(size, size)
      .png()
      .toBuffer();
    fs.writeFileSync(path.join(buildDir, 'icon-' + size + '.png'), png);
    pngs.push(png);
  }

  const bigPng = await sharp(Buffer.from(ICON_SVG), { density: 300 })
    .resize(512, 512)
    .png()
    .toBuffer();
  fs.writeFileSync(path.join(buildDir, 'icon.png'), bigPng);

  const ico = await pngToIco(pngs);
  fs.writeFileSync(path.join(buildDir, 'icon.ico'), ico);
  console.log('ICON_OK ' + path.join(buildDir, 'icon.ico'));
}

main().catch((err) => {
  console.error('ICON_FAIL', err);
  process.exit(1);
});
