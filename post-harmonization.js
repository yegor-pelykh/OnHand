const fs = require('fs');
const path = require('path');
const jsdom = require("jsdom");
const strip = require('strip-comments');
const pretty = require('pretty');

function removeDuplicateWhitespaces(str) {
    return str
        .replace(/\s+/g, ' ')
        .replace(/^\s+|\s+$/, '');
};

function insertString(base, index, string) {
    var ind = index < 0 ? base.length + index : index;
    return base.substring(0, ind) + string + base.substring(ind);
};

console.info('Harmonization:');

const buildDirectory = './build/web';

if (!fs.existsSync(buildDirectory)) {
    console.error(`Error: Directory ${buildDirectory} not found.`);
    console.error('Harmonization failed.');
    return;
}

// Reading and parsing index.html file
const indexFileName = 'index.html';
const indexFilePath = path.join(buildDirectory, indexFileName);
const indexFileContents = fs.readFileSync(indexFilePath, {
    encoding: 'utf8'
});
const { JSDOM } = jsdom;
const indexDocument = new JSDOM(indexFileContents);

// Collecting all inline scripts from index.html
let inlineJsContents = '';
const scriptNodes = indexDocument.window.document.querySelectorAll('script');
scriptNodes.forEach(scriptNode => {
    if (scriptNode != null && (scriptNode.src == null || scriptNode.src == '')) {
        // Strip comments
        let scriptContents = strip(scriptNode.innerHTML);
        // Remove extra whitespaces
        scriptContents = removeDuplicateWhitespaces(scriptContents);
        // Submit to collected content
        inlineJsContents += `${scriptContents}\n`;
        // Remove existing node
        scriptNode.remove();
    }
});
inlineJsContents = pretty(inlineJsContents);

// We are injecting code to switch the background color for different color modes
// to reduce page flicker when the page is opened.
const bgColorLight = '#FCFCFD';
const bgColorDark = '#1F1B17';
const entryPointCode = 'window.addEventListener(\'load\', function(ev) {';
const entryPointCodeStartIndex = inlineJsContents.indexOf(entryPointCode);
if (entryPointCodeStartIndex >= 0) {
    const splashBgCodeStartIndex = entryPointCodeStartIndex + entryPointCode.length;
    const splashBgCode = ` window.document.body.style.backgroundColor = window.matchMedia && window.matchMedia(\'(prefers-color-scheme: dark)\').matches ? \'${bgColorDark}\' : \'${bgColorLight}\';`
    inlineJsContents = insertString(inlineJsContents, splashBgCodeStartIndex, splashBgCode);
} else {
    console.error('Error: Can\'t find entry point to inject code for switching splash background.');
    console.error('Harmonization failed.');
    return;
}

// We remove the part of the script responsible for using the Flutter ServiceWorker.
// This will allow the extension to load faster.
const serviceWorkerCode = 'serviceWorker: { serviceWorkerVersion: serviceWorkerVersion, } ';
const serviceWorkerCodeStartIndex = inlineJsContents.indexOf(serviceWorkerCode);
if (serviceWorkerCodeStartIndex >= 0) {
    inlineJsContents = inlineJsContents.replace(serviceWorkerCode, '');
} else {
    console.error('Error: Can\'t find ServiceWorker initialization code to remove it.');
    console.error('Harmonization failed.');
    return;
}

// Writing scripts into separate js file
const jsFileName = 'index_scripts.js';
const jsFilePath = path.join(buildDirectory, jsFileName);
fs.writeFileSync(jsFilePath, inlineJsContents, {
    encoding: 'utf8'
});

// Add new script node that refers to new js file
var scriptNode = indexDocument.window.document.createElement('script');
scriptNode.src = jsFileName;
indexDocument.window.document.body.appendChild(scriptNode);

// 'base' tag correction (to fix the possibility of reloading the extension page in web browser)
const baseNode = indexDocument.window.document.head.querySelector('base');
baseNode.href = '';

// Saving new version of index.html file
const prettyString = pretty(indexDocument.serialize());
fs.writeFileSync(indexFilePath, prettyString);

console.info('Done.');