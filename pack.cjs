const fs = require('fs');
const path = require('path');
const process = require('process');
const archiver = require('archiver');
const { Select } = require('enquirer');
const { exec } = require('child_process');

async function selectBrowser() {
  const prompt = new Select({
    name: 'browser',
    message: 'Select a browser:',
    choices: [
      { message: 'Firefox', value: 'firefox' },
      { message: 'Other browsers', value: 'default' },
    ],
    initial: 1,
  });
  const browser = await prompt.run();
  return browser;
}

function writeEnv(browser) {
  fs.writeFileSync('.env', `BROWSER=${browser}`, 'utf8');
  console.info(`.env updated: ${browser}`);
}

function runCommand(command) {
  return new Promise((resolve, reject) => {
    exec(command, error => {
      if (error) {
        reject(error);
      } else {
        resolve();
      }
    });
  });
}

async function runBuild() {
  console.info('Running build...');
  try {
    await runCommand('npm run build');
    console.info('Build completed.');
  } catch (err) {
    console.error('Build failed:', err.stderr || err);
    process.exit(1);
  }
}

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

async function createArchive(browser) {
  const buildDirectory = path.resolve('./dist');
  const packageDirectory = path.resolve('./package');
  ensureDir(packageDirectory);
  const archiveName = `onhand-${browser}.zip`;
  const zipFilePath = path.join(packageDirectory, archiveName);
  if (!fs.existsSync(buildDirectory) || fs.readdirSync(buildDirectory).length === 0) {
    console.error('Build directory is empty. Nothing to archive.');
    process.exit(1);
  }
  const zipStream = fs.createWriteStream(zipFilePath);
  const zipArchive = archiver('zip', { zlib: { level: 9 } });
  return new Promise((resolve, reject) => {
    zipStream.on('close', () => {
      console.info('Packaging has been finalized.');
      console.info(`Output file path: ${zipFilePath}`);
      resolve();
    });
    zipArchive.on('warning', err => {
      if (err.code === 'ENOENT') {
        console.warn(`Warning: ${err.message}`);
      } else {
        reject(err);
      }
    });
    zipArchive.on('error', err => {
      reject(err);
    });
    zipArchive.pipe(zipStream);
    zipArchive.directory(buildDirectory, false);
    zipArchive.finalize();
  });
}

async function main() {
  const browser = await selectBrowser();
  writeEnv(browser);
  await runBuild();
  await createArchive(browser);
}

main().catch(err => {
  console.error('Unexpected error:', err);
  process.exit(1);
});
