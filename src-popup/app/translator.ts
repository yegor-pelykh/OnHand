export class Translator {
  get addressLabel(): string {
    return chrome.i18n.getMessage('addressLabel');
  }
  get titleLabel(): string {
    return chrome.i18n.getMessage('titleLabel');
  }
  get groupLabel(): string {
    return chrome.i18n.getMessage('groupLabel');
  }
  get addBookmarkLabel(): string {
    return chrome.i18n.getMessage('addBookmarkLabel');
  }
  get successInfoLabel(): string {
    return chrome.i18n.getMessage('successInfoLabel');
  }
  get selectGroup(): string {
    return chrome.i18n.getMessage('selectGroup');
  }
  get close(): string {
    return chrome.i18n.getMessage('close');
  }
  get select(): string {
    return chrome.i18n.getMessage('select');
  }
}
