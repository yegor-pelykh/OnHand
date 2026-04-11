import { Injectable, inject, signal } from '@angular/core';
import { toObservable } from '@angular/core/rxjs-interop';
import { Observable } from 'rxjs';
import { MatSnackBar } from '@angular/material/snack-bar';
import { Bookmark } from '../models/bookmark.model';
import { GroupStorage } from '../models/group-storage';
import { Group } from '../models/group.model';
import { I18nService } from '../services/i18n.service';
import { isGroupStorageJson } from '@shared/helpers/type-guards';
import { BrowserStorage } from '@shared/helpers/browser-storage';

@Injectable({ providedIn: 'root' })
export class StorageService {
  private readonly _i18n = inject(I18nService);
  private readonly _snackBar = inject(MatSnackBar);
  private readonly _groupStorage = signal<GroupStorage>(new GroupStorage());
  public readonly groupStorage = this._groupStorage.asReadonly();
  private readonly _loaded = signal<boolean>(false);
  public readonly loaded = this._loaded.asReadonly();
  private readonly _browserStorage = new BrowserStorage();

  constructor() {
    void this._loadInitialStorage();
    this._browserStorage.addChangeListener(this._onStorageChanged);
  }

  public groupStorageToObservable(): Observable<GroupStorage> {
    return toObservable(this._groupStorage);
  }

  public getGroupTitles(): string[] {
    return this._groupStorage().titles;
  }

  public getGroupById(id: string): Group | undefined {
    return this._groupStorage().groupById(id);
  }

  public groupAt(index: number): Group | undefined {
    return this._groupStorage().groupAt(index);
  }

  public groupIndexWhere(predicate: (group: Group) => boolean): number {
    return this._groupStorage().groupIndexWhere(predicate);
  }

  public async setStorage(newStorage: GroupStorage): Promise<void> {
    this._groupStorage.set(newStorage);
    await this._save();
  }

  public async addGroup(group: Group): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      updatedStorage.addGroup(group);
      return updatedStorage;
    });
    await this._save();
  }

  public async removeGroup(groupId: string): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      updatedStorage.removeGroup(groupId);
      return updatedStorage;
    });
    await this._save();
  }

  public async moveGroup(oldIndex: number, newIndex: number): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      updatedStorage.moveGroup(oldIndex, newIndex);
      return updatedStorage;
    });
    await this._save();
  }

  public async addBookmark(
    groupId: string,
    url: string,
    title: string,
    iconUrl?: string
  ): Promise<Bookmark | undefined> {
    let newBookmark: Bookmark | undefined;
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      newBookmark = updatedStorage.addBookmark(groupId, url, title, iconUrl);
      return updatedStorage;
    });
    await this._save();
    return newBookmark;
  }

  public async updateBookmark(
    groupId: string,
    bookmarkId: string,
    url: string,
    title: string,
    iconUrl?: string
  ): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      const group = updatedStorage.groupById(groupId);
      if (group) {
        const bookmarkIndex = group.bookmarks.findIndex((b: Bookmark) => b.id === bookmarkId);
        if (bookmarkIndex !== -1) {
          group.bookmarks[bookmarkIndex] = new Bookmark(url, title, iconUrl, bookmarkId);
        }
      }
      return updatedStorage;
    });
    await this._save();
  }

  public async removeBookmark(groupId: string, bookmarkId: string): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      updatedStorage.removeBookmark(groupId, bookmarkId);
      return updatedStorage;
    });
    await this._save();
  }

  public async moveBookmark(groupId: string, oldIndex: number, newIndex: number): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      updatedStorage.moveBookmark(groupId, oldIndex, newIndex);
      return updatedStorage;
    });
    await this._save();
  }

  public async moveBookmarkToGroup(bookmarkId: string, fromGroupId: string, toGroupId: string): Promise<void> {
    this._groupStorage.update((currentStorage: GroupStorage) => {
      const updatedStorage = currentStorage.clone();
      updatedStorage.moveBookmarkToGroup(bookmarkId, fromGroupId, toGroupId);
      return updatedStorage;
    });
    await this._save();
  }

  public async importDataFromJson(jsonString: string): Promise<boolean> {
    const success = this._updateGroupStorageFromJsonString(jsonString);
    if (success) {
      await this._save();
      this._snackBar.open(this._i18n.t('data_imported'), this._i18n.t('ok'), { duration: 3000 });
      return true;
    } else {
      this._snackBar.open(this._i18n.t('import_error'), this._i18n.t('ok'), { duration: 3000 });
      return false;
    }
  }

  private _updateGroupStorageFromJsonString(jsonString: string): boolean {
    try {
      const parsed: unknown = JSON.parse(jsonString);
      if (isGroupStorageJson(parsed)) {
        const newStorage = GroupStorage.fromJson(parsed);
        this._groupStorage.set(newStorage);
        return true;
      } else {
        return false;
      }
    } catch {
      return false;
    }
  }

  private async _loadInitialStorage(): Promise<void> {
    try {
      const data = await this._browserStorage.getItem();
      if (data) {
        const success = this._updateGroupStorageFromJsonString(data);
        if (!success) {
          this._snackBar.open(this._i18n.t('data_load_error_general'), this._i18n.t('ok'), {
            duration: 7000,
          });
          this._replaceWithDefaultStorage();
        }
      } else {
        this._replaceWithDefaultStorage();
      }
    } catch {
      this._snackBar.open(this._i18n.t('data_load_error_general'), this._i18n.t('ok'), {
        duration: 7000,
      });
      this._replaceWithDefaultStorage();
    } finally {
      this._loaded.set(true);
    }
  }

  private async _save(): Promise<void> {
    const jsonString = JSON.stringify(this._groupStorage().toJson());
    await this._browserStorage.setItem(jsonString);
  }

  private _replaceWithDefaultStorage(): void {
    const defaultGroup = new Group(this._i18n.t('default_group_title'));
    const newStorage = new GroupStorage([defaultGroup]);
    this._groupStorage.set(newStorage);
    void this._save();
  }

  private _onStorageChanged = (newValue: string | undefined): void => {
    if (newValue !== undefined && newValue !== JSON.stringify(this._groupStorage().toJson())) {
      this._updateGroupStorageFromJsonString(newValue);
    }
  };
}
