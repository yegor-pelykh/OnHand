import { generateUUID } from '../helpers/utils';

export interface BookmarkJson {
  readonly u: string;
  readonly t: string;
  readonly i?: string;
}

export class Bookmark {
  private static readonly KEY_URL = 'u';
  private static readonly KEY_TITLE = 't';
  private static readonly KEY_ICON = 'i';

  public readonly id: string;
  public readonly url: string;
  public title: string;
  public iconUrl?: string;

  constructor(url: string, title: string, iconUrl?: string, id?: string) {
    this.id = id || generateUUID();
    this.url = url;
    this.title = title;
    this.iconUrl = iconUrl;
  }

  public static fromJson(json: BookmarkJson): Bookmark {
    const url: string = json[Bookmark.KEY_URL] ?? '';
    const title: string = json[Bookmark.KEY_TITLE] ?? '';
    let iconUrl: string | undefined = json[Bookmark.KEY_ICON];

    if (iconUrl && !iconUrl.startsWith('data:')) {
      iconUrl = `data:image;base64,${iconUrl}`;
    }

    return new Bookmark(url, title, iconUrl);
  }

  public static equals(b1: Bookmark, b2: Bookmark): boolean {
    return b1.id === b2.id;
  }

  public toJson(): BookmarkJson {
    const result: BookmarkJson = {
      [Bookmark.KEY_URL]: this.url,
      [Bookmark.KEY_TITLE]: this.title,
      [Bookmark.KEY_ICON]: this.iconUrl,
    };
    return result;
  }

  public clone(): Bookmark {
    return new Bookmark(this.url, this.title, this.iconUrl, this.id);
  }
}
