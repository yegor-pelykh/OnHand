import { Bookmark, BookmarkJson } from './bookmark.model';
import { generateUUID } from '../helpers/utils';

export interface GroupJson {
  readonly t: string;
  readonly b: readonly BookmarkJson[];
}

export class Group {
  private static readonly KEY_TITLE = 't';
  private static readonly KEY_BOOKMARKS = 'b';

  public readonly id: string;
  public title: string;
  public bookmarks: Bookmark[];

  constructor(title: string, bookmarks: Bookmark[] = [], id?: string) {
    this.id = id || generateUUID();
    this.title = title;
    this.bookmarks = bookmarks;
  }

  public static fromJson(json: GroupJson): Group {
    const title: string = json[Group.KEY_TITLE] ?? '';
    const bookmarks: Bookmark[] = Array.isArray(json[Group.KEY_BOOKMARKS])
      ? json[Group.KEY_BOOKMARKS].map((bookmarkJson: object) => Bookmark.fromJson(bookmarkJson as BookmarkJson))
      : [];

    return new Group(title, bookmarks);
  }

  public static equals(g1: Group, g2: Group): boolean {
    return g1.id === g2.id;
  }

  public toJson(): GroupJson {
    return {
      [Group.KEY_TITLE]: this.title,
      [Group.KEY_BOOKMARKS]: this.bookmarks.map((bookmark: Bookmark) => bookmark.toJson()),
    };
  }

  public addBookmark(url: string, title: string, iconUrl?: string, id?: string): Bookmark {
    const bookmark = new Bookmark(url, title, iconUrl, id);
    this.bookmarks.push(bookmark);
    return bookmark;
  }

  public removeBookmark(bookmarkId: string): void {
    const index = this.bookmarks.findIndex((bookmark: Bookmark) => bookmark.id === bookmarkId);
    if (index > -1) {
      this.bookmarks.splice(index, 1);
    }
  }

  public moveBookmark(oldIndex: number, newIndex: number): void {
    if (oldIndex < 0 || oldIndex >= this.bookmarks.length || newIndex < 0 || newIndex >= this.bookmarks.length) {
      console.warn('Attempted to move bookmark with out-of-bounds index.');
      return;
    }
    const [removed] = this.bookmarks.splice(oldIndex, 1);
    this.bookmarks.splice(newIndex, 0, removed);
  }

  public clone(): Group {
    return new Group(
      this.title,
      this.bookmarks.map((b: Bookmark) => b.clone()),
      this.id
    );
  }
}
