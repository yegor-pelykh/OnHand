import { Bookmark } from './bookmark.model';
import { Group, GroupJson } from './group.model';

export interface GroupStorageJson {
  readonly g: readonly GroupJson[];
}

export class GroupStorage {
  private static readonly KEY_GROUPS = 'g';

  public groups: Group[];

  constructor(groups: Group[] = []) {
    this.groups = groups;
  }

  public static fromJson(json: GroupStorageJson): GroupStorage {
    const groupJsons = Array.isArray(json[GroupStorage.KEY_GROUPS]) ? json[GroupStorage.KEY_GROUPS] : [];
    const groups: Group[] = groupJsons.map((groupJson: object) => Group.fromJson(groupJson as GroupJson));
    return new GroupStorage(groups);
  }

  public toJson(): GroupStorageJson {
    return {
      [GroupStorage.KEY_GROUPS]: this.groups.map((group: Group) => group.toJson()),
    };
  }

  public clone(): GroupStorage {
    return new GroupStorage(this.groups.map((group: Group) => group.clone()));
  }

  public addGroup(group: Group): void {
    this.groups.push(group);
  }

  public moveGroup(oldIndex: number, newIndex: number): void {
    if (oldIndex < 0 || oldIndex >= this.groups.length || newIndex < 0 || newIndex >= this.groups.length) {
      console.warn('Attempted to move group with out-of-bounds index.');
      return;
    }
    const [removed] = this.groups.splice(oldIndex, 1);
    this.groups.splice(newIndex, 0, removed);
  }

  public removeGroup(groupId: string): void {
    const index = this.groups.findIndex((group: Group) => group.id === groupId);
    if (index > -1) {
      this.groups.splice(index, 1);
    }
  }

  public replaceAll(newGroups: Group[]): void {
    this.groups = newGroups;
  }

  public groupById(groupId: string): Group | undefined {
    return this.groups.find((group: Group) => group.id === groupId);
  }

  public groupAt(index: number): Group | undefined {
    return this.groups[index];
  }

  public groupIndexWhere(predicate: (group: Group) => boolean): number {
    return this.groups.findIndex(predicate);
  }

  public addBookmark(groupId: string, url: string, title: string, iconUrl?: string): Bookmark | undefined {
    const group = this.groupById(groupId);
    if (group) {
      return group.addBookmark(url, title, iconUrl);
    }
    return undefined;
  }

  public removeBookmark(groupId: string, bookmarkId: string): void {
    const group = this.groupById(groupId);
    if (group) {
      group.removeBookmark(bookmarkId);
    }
  }

  public moveBookmark(groupId: string, oldIndex: number, newIndex: number): void {
    const group = this.groupById(groupId);
    if (group) {
      group.moveBookmark(oldIndex, newIndex);
    }
  }

  public moveBookmarkToGroup(bookmarkId: string, fromGroupId: string, toGroupId: string): void {
    const fromGroup = this.groupById(fromGroupId);
    const toGroup = this.groupById(toGroupId);

    if (!fromGroup || !toGroup) {
      return;
    }

    const bookmarkIndex = fromGroup.bookmarks.findIndex((bookmark: Bookmark) => bookmark.id === bookmarkId);

    if (bookmarkIndex === -1) {
      return;
    }

    const [bookmarkToMove] = fromGroup.bookmarks.splice(bookmarkIndex, 1);
    toGroup.addBookmark(bookmarkToMove.url, bookmarkToMove.title, bookmarkToMove.iconUrl, bookmarkToMove.id);
  }

  public findGroupAndBookmark(bookmarkId: string): { group: Group; bookmark: Bookmark } | undefined {
    for (const group of this.groups) {
      const bookmark = group.bookmarks.find((bookmark: Bookmark) => bookmark.id === bookmarkId);
      if (bookmark) {
        return { group, bookmark };
      }
    }
    return undefined;
  }

  public findGroupAndBookmarkIndex(bookmarkToFind: Bookmark): { group: Group; bookmarkIndex: number } | undefined {
    for (const group of this.groups) {
      const bookmarkIndex = group.bookmarks.findIndex((bookmark: Bookmark) =>
        Bookmark.equals(bookmark, bookmarkToFind)
      );
      if (bookmarkIndex > -1) {
        return { group, bookmarkIndex };
      }
    }
    return undefined;
  }

  public get titles(): string[] {
    return this.groups.map((group: Group) => group.title);
  }

  public get isEmpty(): boolean {
    return this.groups.length === 0;
  }

  public get isNotEmpty(): boolean {
    return this.groups.length > 0;
  }
}
