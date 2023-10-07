import { Injectable } from '@angular/core';
import { Bookmark } from './bookmark';
import { Group } from './group';
import { GroupStorage } from './group-storage';

const keyData = 'data';

@Injectable({
  providedIn: 'root'
})
export class GlobalDataService {
  private readonly storageDataChangeListener = (
    changes: {
      [key: string]: chrome.storage.StorageChange,
    },
    areaName: 'sync' | 'local' | 'managed' | 'session',
  ) => this.onStorageDataChange(changes, areaName);
  readonly groupStorage: GroupStorage = new GroupStorage();

  constructor() { }

  private onStorageDataChange(
    changes: {
      [key: string]: chrome.storage.StorageChange,
    },
    areaName: 'sync' | 'local' | 'managed' | 'session',
  ): void {
    if (areaName === 'local') {
      const dataChanges = changes[keyData];
      if (typeof dataChanges.newValue === 'string') {
        const jsonString = dataChanges.newValue;
        this.groupStorage.replaceFromJson(jsonString);
      }
    }
  }

  public subscribeToStorageChange(): void {
    chrome.storage.onChanged.addListener(this.storageDataChangeListener);
  }

  public unsubscribeFromStorageChange(): void {
    chrome.storage.onChanged.removeListener(this.storageDataChangeListener);
  }

  public async loadFromStorage(): Promise<void> {
    const results = await chrome.storage.local.get(keyData);
    if (keyData in results) {
      this.groupStorage.replaceFromJson(results[keyData]);
    } else {
      this.groupStorage.replaceByDefault();
    }
  }

  public async saveToStorage(): Promise<void> {
    await chrome.storage.local.set({
      [keyData]: this.groupStorage.json
    });
  }

  public moveBookmarkToGroup(bookmark: Bookmark, toGroup: Group): number {
    // remove from old group
    const oldGroup = bookmark.group;
    oldGroup.removeBookmark(bookmark);
    // add to new group
    toGroup.addBookmark(bookmark.url, bookmark.title, bookmark.icon);
    return this.groupStorage.indexOf(toGroup);
  }

}