const fs = require('fs');
const path = require('path');

console.info('I18n:');

const i18nDirectory = path.resolve('./web/i18n');
const buildDirectory = path.resolve('./build/web');

const localesDirectoryName = '_locales';
const buildLocalesDirectory = path.join(buildDirectory, localesDirectoryName);

if (!fs.existsSync(buildLocalesDirectory)) {
    fs.mkdirSync(buildLocalesDirectory);
}

fs.cpSync(i18nDirectory, buildLocalesDirectory, { recursive: true });

console.info('Done.');