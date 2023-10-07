import { Bookmark } from "./bookmark";
import { GroupStorage } from "./group-storage";
import { Notifier } from "./notifier";
import { Buffer } from 'buffer';

const keyTitle = 't';
const keyBookmarks = 'b';

export class Group extends Notifier {
    public get storage(): GroupStorage { return this._storage; }
    public set storage(v: GroupStorage) {
        if (this._storage != v) {
            this._storage = v;
            this.emit();
        }
    }

    public get title(): string { return this._title; }
    public set title(v: string) {
        if (this._title != v) {
            this._title = v;
            this.emit();
        }
    }

    public get bookmarks(): Bookmark[] { return this._bookmarks; }

    public get json() {
        return {
            [keyTitle]: this._title,
            [keyBookmarks]: this._bookmarks.map((b) => b.json),
        }
    }

    constructor(
        private _storage: GroupStorage,
        private _title: string,
        private _bookmarks: Bookmark[],
    ) {
        super();
        for (const b of this._bookmarks) {
            b.addListener(() => this.handleBookmarkChange());
        }
    }

    public static fromJson(
        storage: GroupStorage,
        json: any,
    ): Group {
        const title = json[keyTitle] as string;
        const group = new Group(storage, title, []);
        group.replaceAllBookmarks((json[keyBookmarks] as []).map((j: any) => Bookmark.fromJson(group, j)));
        return group;
    }

    private handleBookmarkChange(): void {
        this.emit();
    }

    public addBookmark(
        url: URL,
        title: string,
        icon?: Buffer,
    ): Bookmark {
        const bookmark = new Bookmark(this, url, title, icon);
        this._bookmarks.push(bookmark);
        bookmark.addListener(() => this.handleBookmarkChange());
        this.emit();
        return bookmark;
    }

    public moveBookmark(
        oldIndex: number,
        newIndex: number,
    ): void {
        const bookmark = this._bookmarks[oldIndex];
        this._bookmarks.splice(oldIndex, 1);
        this._bookmarks.splice(newIndex, 0, bookmark);
        this.emit();
    }

    public removeBookmark(
        bookmark: Bookmark,
    ): void {
        bookmark.removeListener(this.handleBookmarkChange);
        const index = this._bookmarks.indexOf(bookmark);
        if (index >= 0) {
            this._bookmarks.splice(index, 1);
        }
        this.emit();
    }

    public replaceAllBookmarks(
        b: Bookmark[],
    ): void {
        if (!Group.bookmarksEqual(this._bookmarks, b)) {
            for (const b of this._bookmarks) {
                b.removeListener(this.handleBookmarkChange);
            }
            this._bookmarks = b;
            for (const b of this._bookmarks) {
                b.addListener(() => this.handleBookmarkChange());
            }
            this.emit();
        }
    }

    public clone(
        storage: GroupStorage,
    ): Group {
        const group = new Group(storage, this._title, this._bookmarks);
        group.replaceAllBookmarks(this._bookmarks.map((b) => b.clone(group)));
        return group;
    }

    private static bookmarksEqual(
        b1: Bookmark[],
        b2: Bookmark[],
    ): boolean {
        if (b1.length != b2.length) {
            return false;
        }
        for (var i = 0; i < b1.length; i++) {
            if (!Bookmark.equals(b1[i], b2[i])) {
                return false;
            }
        }
        return true;
    }

    public static equals(
        g1: Group,
        g2: Group,
    ): boolean {
        if (g1.title != g2.title) {
            return false;
        }
        return this.bookmarksEqual(g1.bookmarks, g2.bookmarks);
    }

}