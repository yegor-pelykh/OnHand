const bgColorLight = '#fcfcfd';
const bgColorDark = '#1f1b17';
const appScriptName = 'main.dart.js';

function setBgColor() {
    window.document.body.style.backgroundColor = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? bgColorDark : bgColorLight;
}

function loadApp() {
    let scriptTag = document.createElement("script");
    scriptTag.src = appScriptName;
    scriptTag.type = "application/javascript";
    document.body.append(scriptTag);
}

window.addEventListener('load', function (_) {
    setBgColor();
    loadApp();
});