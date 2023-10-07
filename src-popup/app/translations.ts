export class Translator {
    get addressLabel(): string { return chrome.i18n.getMessage('addressLabel'); }
    get titleLabel(): string { return chrome.i18n.getMessage('titleLabel'); }
    get groupLabel(): string { return chrome.i18n.getMessage('groupLabel'); }
    get addBookmarkLabel(): string { return chrome.i18n.getMessage('addBookmarkLabel'); }
    get successInfoLabel(): string { return chrome.i18n.getMessage('successInfoLabel'); }
}
