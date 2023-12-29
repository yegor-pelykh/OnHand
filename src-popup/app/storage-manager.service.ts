import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class StorageManagerService {
  private readonly isFirefox;

  constructor() {
    this.isFirefox = navigator.userAgent.toLowerCase().includes('firefox');
  }

  private async getObjForFirefox(key: string): Promise<any | undefined> {
    return new Promise((resolve, reject) => {
      chrome.storage.local.get(key, (results) => {
        resolve(results);
      });
    });
  }

  private async setObjForFirefox(obj: { [key: string]: any }): Promise<void> {
    return new Promise((resolve, reject) => {
      chrome.storage.local.set(obj, () => {
        resolve();
      });
    });
  }

  async get(key: string): Promise<any | undefined> {
    const results = this.isFirefox
      ? await this.getObjForFirefox(key)
      : await chrome.storage.local.get(key);
    if (key in results) {
      return results[key];
    } else {
      return undefined;
    }
  }

  async set(key: string, value: any): Promise<void> {
    if (this.isFirefox) {
      await this.setObjForFirefox({
        [key]: value,
      });
    } else {
      await chrome.storage.local.set({
        [key]: value,
      });
    }
  }
}
