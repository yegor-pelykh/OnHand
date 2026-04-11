import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class I18nService {
  private readonly isChromeExtension: boolean;

  constructor() {
    this.isChromeExtension = typeof chrome !== 'undefined' && !!chrome.i18n;
  }

  public t(key: string, substitutions?: Record<string, string | number>): string {
    if (!this.isChromeExtension) {
      return key;
    }

    let message = chrome.i18n.getMessage(key);

    if (substitutions) {
      for (const [subKey, subValue] of Object.entries(substitutions)) {
        message = message.replace(new RegExp(`#${subKey}#`, 'gi'), String(subValue));
      }
    }
    return message;
  }

  public p(msgNameBase: string, substitutions: { count: number } & Record<string, string | number>): string {
    const count = substitutions.count;
    let pluralFormKey: 'zero' | 'one' | 'few' | 'many';

    if (count === 0) {
      pluralFormKey = 'zero';
    } else if (count === 1) {
      pluralFormKey = 'one';
    } else if (count >= 2 && count <= 4) {
      pluralFormKey = 'few';
    } else {
      pluralFormKey = 'many';
    }

    const key = `${msgNameBase}_${pluralFormKey}`;
    return this.t(key, substitutions);
  }
}
