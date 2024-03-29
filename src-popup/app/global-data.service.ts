import { Injectable } from '@angular/core';
import { Bookmark } from './bookmark';
import { Group } from './group';
import { GroupStorage } from './group-storage';
import { StorageManagerService } from './storage-manager.service';

const keyData = 'data';

@Injectable({
  providedIn: 'root',
})
export class GlobalDataService {
  private readonly storageDataChangeListener = (
    changes: {
      [key: string]: chrome.storage.StorageChange;
    },
    areaName: 'sync' | 'local' | 'managed' | 'session',
  ) => this.onStorageDataChange(changes, areaName);
  private readonly storageManager: StorageManagerService;
  readonly groupStorage: GroupStorage = new GroupStorage();

  constructor(storageManager: StorageManagerService) {
    this.storageManager = storageManager;
  }

  private onStorageDataChange(
    changes: {
      [key: string]: chrome.storage.StorageChange;
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
    const data = await this.storageManager.get(keyData);
    if (data !== undefined) {
      this.groupStorage.replaceFromJson(data);
    } else {
      this.groupStorage.replaceByDefault();
    }
  }

  public async saveToStorage(): Promise<void> {
    await this.storageManager.set(keyData, this.groupStorage.json);
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
