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

console.log('Harmonization:');

const buildDirectory = './build/web';

if (!fs.existsSync(buildDirectory)) {
    console.log(`Directory ${buildDirectory} not found.`);
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

// We remove the part of the script responsible for using the Flutter ServiceWorker.
// This will allow the extension to load faster.
const unnecessaryCode = 'serviceWorker: { serviceWorkerVersion: serviceWorkerVersion, } ';
inlineJsContents = inlineJsContents.replace(unnecessaryCode, '');

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

console.log('Done.');