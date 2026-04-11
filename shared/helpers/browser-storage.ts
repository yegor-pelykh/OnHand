type StorageChangeListener = (newValue: string | undefined, oldValue: string | undefined) => void;

export class BrowserStorage {
  private static readonly _STORAGE_KEY = 'data';
  private _listeners = new Set<StorageChangeListener>();

  constructor() {
    if (chrome?.storage?.onChanged) {
      chrome.storage.onChanged.addListener(this._handleChromeStorageChange);
    }
  }

  public async getItem(): Promise<string | undefined> {
    if (typeof chrome !== 'undefined' && chrome.storage?.local) {
      return new Promise(resolve => {
        chrome.storage.local.get([BrowserStorage._STORAGE_KEY], result => {
          resolve(result[BrowserStorage._STORAGE_KEY] as string | undefined);
        });
      });
    } else {
      return Promise.resolve(localStorage.getItem(BrowserStorage._STORAGE_KEY) ?? undefined);
    }
  }

  public async setItem(value: string): Promise<void> {
    if (typeof chrome !== 'undefined' && chrome.storage?.local) {
      return new Promise(resolve => {
        chrome.storage.local.set({ [BrowserStorage._STORAGE_KEY]: value }, () => resolve());
      });
    } else {
      localStorage.setItem(BrowserStorage._STORAGE_KEY, value);
      this._emitChange(value, undefined);
      return Promise.resolve();
    }
  }

  public async removeItem(): Promise<void> {
    if (typeof chrome !== 'undefined' && chrome.storage?.local) {
      return new Promise(resolve => {
        chrome.storage.local.remove([BrowserStorage._STORAGE_KEY], () => resolve());
      });
    } else {
      localStorage.removeItem(BrowserStorage._STORAGE_KEY);
      this._emitChange(undefined, undefined);
      return Promise.resolve();
    }
  }

  public addChangeListener(listener: StorageChangeListener): void {
    this._listeners.add(listener);
  }

  public removeChangeListener(listener: StorageChangeListener): void {
    this._listeners.delete(listener);
  }

  private _emitChange(newValue: string | undefined, oldValue: string | undefined): void {
    for (const listener of this._listeners) {
      listener(newValue, oldValue);
    }
  }

  private _handleChromeStorageChange = (
    changes: Record<string, chrome.storage.StorageChange>,
    areaName: string
  ): void => {
    if (areaName === 'local' && changes[BrowserStorage._STORAGE_KEY]) {
      const { newValue, oldValue } = changes[BrowserStorage._STORAGE_KEY];
      this._emitChange(newValue as string | undefined, oldValue as string | undefined);
    }
  };
}
