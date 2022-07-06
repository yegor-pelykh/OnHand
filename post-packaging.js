const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

const { execSync } = require('child_process');

console.info('Packaging:');

const buildDirectory = path.resolve('./build/web');

// Create a folder where we will put our archive.
const packageDirectory = path.join(buildDirectory, '../package');
if (!fs.existsSync(packageDirectory)) {
    fs.mkdirSync(packageDirectory);
}

// Get the name of the Git branch (if possible)
let gitBranchName = '';
try {
    gitBranchName = execSync('git rev-parse --abbrev-ref HEAD', {
        encoding: 'utf8',
    }).trim();
} catch (err) {
    console.warn(`Warning: ${err.message}`);
}

// Create a file to stream archive data to.
const zipFileName = gitBranchName.length > 0 ? `onhand-${gitBranchName.replace(/[^a-z0-9]/gi, '_')}.zip` : 'onhand.zip';
const zipFilePath = path.join(packageDirectory, zipFileName);
const zipStream = fs.createWriteStream(zipFilePath);
const zipArchive = archiver('zip');

zipStream.on('close', function () {
    console.info('Packaging has been finalized and the output file descriptor has closed.');
    console.info(`Output file path: ${zipFilePath}`);
    console.info('Done.');
});
zipStream.on('warning', function (err) {
    if (err.code === 'ENOENT') {
        console.warn(`Warning: ${err.message}`);
    } else {
        console.error(`Error: ${err.message}`);
    }
});
zipStream.on('error', function (err) {
    console.error(`Error: ${err.message}`);
    console.error('Packaging failed.');
});

// Pipe archive data to the file
zipArchive.pipe(zipStream);

// Append files from build directory, putting its contents at the root of archive
zipArchive.directory(buildDirectory, false);

// Finalize the archive
zipArchive.finalize();