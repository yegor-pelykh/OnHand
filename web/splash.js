const bgColorLight = '#fcfcfd';
const bgColorDark = '#1f1b17';

function setBgColor() {
    window.document.body.style.backgroundColor = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? bgColorDark : bgColorLight;
}

window.addEventListener('load', function (ev) {
    setBgColor();
});