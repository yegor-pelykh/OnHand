import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root'
})
export class StorageManagerService {
  static async getString(key: string): Promise<string | undefined> {
    const result = await chrome.storage.local.get(key);
    if (key in result && typeof result[key] === 'string') {
      return result[key] as string;
    } else {
      return undefined;
    }
  }

  static async setString(key: string, value: string): Promise<void> {
    await chrome.storage.local.set({
      key: value,
    });
  }
}
