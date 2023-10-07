import { Group } from "./group";
import { Notifier } from "./notifier";
import { Buffer } from 'buffer';

const keyUrl = 'u';
const keyTitle = 't';
const keyIcon = 'i';

export class Bookmark extends Notifier {
    public get group(): Group { return this._group; }
    public set group(v: Group) {
        if (this._group != v) {
            this._group = v;
            this.emit();
        }
    }

    public get url(): URL { return this._url; }
    public set url(v: URL) {
        if (this._url != v) {
            this._url = v;
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

    public get icon(): Buffer | undefined { return this._icon; }
    public set icon(v: Buffer | undefined) {
        if (this._icon != v) {
            this._icon = v;
            this.emit();
        }
    }

    public get json() {
        return {
            [keyUrl]: this._url.toString(),
            [keyTitle]: this._title,
            [keyIcon]: this.icon != null ? this._icon?.toString('base64') : undefined,
        };
    };

    constructor(
        private _group: Group,
        private _url: URL,
        private _title: string,
        private _icon?: Buffer,
    ) {
        super();
    }

    public static fromJson(
        group: Group,
        json: any,
    ): Bookmark {
        const url = new URL(json[keyUrl]);
        const title = json[keyTitle] as string;
        const icon = json[keyIcon] != null
            ? Buffer.from(json[keyIcon], 'base64')
            : undefined;
        return new Bookmark(group, url, title, icon);
    }

    public clone(
        parentGroup: Group,
    ): Bookmark {
        return new Bookmark(parentGroup, this._url, this._title, this._icon);
    }

    private static bufferEqual(
        b1: Buffer | undefined,
        b2: Buffer | undefined,
    ) {
        if ((b1 != null && b2 == null) || (b1 == null && b2 != null)) {
            return false;
        }
        if (b1 != null && b2 != null && !b1.equals(b2)) {
            return false;
        }
        return true;
    }

    public static equals(
        b1: Bookmark,
        b2: Bookmark,
    ): boolean {
        if (b1.title != b2.title) {
            return false;
        }
        if (b1.url != b2.url) {
            return false;
        }
        return this.bufferEqual(b1.icon, b2.icon);
    }

}