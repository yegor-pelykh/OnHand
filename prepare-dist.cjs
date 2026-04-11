const { existsSync, copyFileSync, mkdirSync, cpSync, readdirSync, statSync } = require('fs');
const { join } = require('path');
const dotenv = require('dotenv');

dotenv.config();

const browser = process.env.BROWSER || 'default';
const manifestDir = join(__dirname, 'manifest');
const outputDir = join(__dirname, 'dist');

const manifestFile = browser === 'firefox' ? 'manifest.firefox.json' : 'manifest.default.json';

const src = join(manifestDir, manifestFile);
const dest = join(outputDir, 'manifest.json');

if (!existsSync(src)) {
  console.error(`Manifest file not found: ${src}`);
  process.exit(1);
}

if (!existsSync(outputDir)) {
  mkdirSync(outputDir, { recursive: true });
}

copyFileSync(src, dest);
console.log(`Copied ${manifestFile} to output as manifest.json`);

const publicSrc = join(__dirname, 'public');

if (existsSync(publicSrc)) {
  const items = readdirSync(publicSrc);
  items.forEach(item => {
    const srcPath = join(publicSrc, item);
    const destPath = join(outputDir, item);
    if (statSync(srcPath).isDirectory()) {
      cpSync(srcPath, destPath, { recursive: true });
    } else {
      copyFileSync(srcPath, destPath);
    }
  });
  console.log('Copied contents of public folder to dist.');
} else {
  console.warn('public folder not found, skipping copy.');
}
