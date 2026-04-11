import { Injectable } from '@angular/core';
import { IconData, Metadata } from '../models/metadata.model';

@Injectable({ providedIn: 'root' })
export class MetadataService {
  private static readonly LINK_REL_ATTRIBUTES: readonly string[] = [
    'icon',
    'shortcut icon',
    'apple-touch-icon',
    'apple-touch-icon-precomposed',
    'mask-icon',
    'fluid-icon',
  ];
  private static readonly DEFAULT_CHARSET = 'utf-8';
  private static readonly FALLBACK_CHARSET = 'utf-8';

  public async getMetadata(url: string): Promise<Metadata | undefined> {
    try {
      const htmlString = await this.getHtml(url);
      if (!htmlString) {
        return undefined;
      }

      const parser = new DOMParser();
      const doc = parser.parseFromString(htmlString, 'text/html');

      const title = doc.querySelector('title')?.textContent?.trim() || '';
      const icon = await this.getIconData(new URL(url), doc);

      return { title, icon };
    } catch (error: unknown) {
      console.error(`Error fetching or processing metadata for URL ${url}:`, error);
      return undefined;
    }
  }

  public getIconDataUrl(data: { contentType?: string; content: string }): string {
    const mimeType = data.contentType || 'image';
    return `data:${mimeType};base64,${data.content}`;
  }

  private async getHtml(url: string): Promise<string | undefined> {
    try {
      const response = await fetch(url);
      if (!response.ok) {
        return undefined;
      }

      const arrayBuffer = await response.arrayBuffer();
      const uint8Array = new Uint8Array(arrayBuffer);

      const contentTypeHeader = response.headers.get('Content-Type');
      const httpCharset = this.extractCharsetFromContentType(contentTypeHeader);

      const initialDecodeLength = Math.min(uint8Array.length, 1024);
      const initialHtmlChunk = new TextDecoder(MetadataService.DEFAULT_CHARSET, {
        fatal: false,
      }).decode(uint8Array.slice(0, initialDecodeLength));
      const metaCharset = this.extractCharsetFromMetaTag(initialHtmlChunk);

      const finalCharset = metaCharset || httpCharset || MetadataService.DEFAULT_CHARSET;

      let htmlString: string;
      try {
        htmlString = new TextDecoder(finalCharset, { fatal: true }).decode(uint8Array);
      } catch (decodeError: unknown) {
        console.warn(
          `Failed to decode with ${finalCharset} for URL ${url}. Falling back to ${MetadataService.FALLBACK_CHARSET} lenient decoding.`,
          decodeError
        );
        htmlString = new TextDecoder(MetadataService.FALLBACK_CHARSET, { fatal: false }).decode(uint8Array);
      }

      return htmlString;
    } catch (error: unknown) {
      console.error(`Error fetching HTML for URL ${url}:`, error);
      return undefined;
    }
  }

  private extractCharsetFromContentType(contentTypeHeader: string | null): string | undefined {
    if (!contentTypeHeader) {
      return undefined;
    }
    const charsetMatch = contentTypeHeader.match(/charset=([^;"]+)/i);
    return charsetMatch && charsetMatch[1] ? charsetMatch[1].trim().toLowerCase() : undefined;
  }

  private extractCharsetFromMetaTag(htmlChunk: string): string | undefined {
    const metaCharsetRegex =
      /<meta\s+(?:charset=["']?([^"'\s>]+)["']?|http-equiv=["']Content-Type["']\s+content=["'][^"']*charset=([^"']+))/i;
    const metaMatch = htmlChunk.match(metaCharsetRegex);
    return metaMatch ? (metaMatch[1] || metaMatch[2])?.trim().toLowerCase() : undefined;
  }

  private async getIconData(baseUrl: URL, document: Document): Promise<IconData | undefined> {
    const iconPromises: Promise<IconData | undefined>[] = [];
    for (const rel of MetadataService.LINK_REL_ATTRIBUTES) {
      const iconTags = document.querySelectorAll(`link[rel*='${rel}']`);
      for (const iconTag of Array.from(iconTags)) {
        let url = iconTag.getAttribute('href');
        if (url) {
          url = url.trim();
          const imageUrl = new URL(url, baseUrl).toString();
          iconPromises.push(this.getIconDataByUrl(imageUrl));
        }
      }
    }

    const faviconUrl = new URL('/favicon.ico', baseUrl).toString();
    iconPromises.push(this.getIconDataByUrl(faviconUrl));

    const iconDataList = (await Promise.all(iconPromises)).filter((icon): icon is IconData => icon !== undefined);

    if (iconDataList.length === 0) {
      return undefined;
    }

    const uniqueIconsMap = new Map<string, IconData>();
    for (const icon of iconDataList) {
      if (!uniqueIconsMap.has(icon.url)) {
        uniqueIconsMap.set(icon.url, icon);
      }
    }

    const uniqueIcons = Array.from(uniqueIconsMap.values());

    uniqueIcons.sort((a: IconData, b: IconData) => {
      const isASVG = a.url.startsWith('data:image/svg+xml');
      const isBSVG = b.url.startsWith('data:image/svg+xml');

      if (isASVG && !isBSVG) return -1;
      if (!isASVG && isBSVG) return 1;

      const areaA = (a.width || 0) * (a.height || 0);
      const areaB = (b.width || 0) * (b.height || 0);
      return areaB - areaA;
    });

    return uniqueIcons.length > 0 ? uniqueIcons[0] : undefined;
  }

  private async getIconDataByUrl(uri: string): Promise<IconData | undefined> {
    try {
      const response = await fetch(uri);
      if (!response.ok) {
        return undefined;
      }

      const contentType = response.headers.get('content-type')?.toLowerCase();
      if (!contentType || (!contentType.includes('image') && !contentType.includes('application/octet-stream'))) {
        return undefined;
      }

      const arrayBuffer = await response.arrayBuffer();
      const bytes = new Uint8Array(arrayBuffer);
      const base64Content = btoa(String.fromCharCode(...bytes));

      const dataUrl = this.getIconDataUrl({
        contentType: contentType,
        content: base64Content,
      });

      let width = 0;
      let height = 0;
      if (contentType.includes('image')) {
        ({ width, height } = await this.getImageDimensions(dataUrl));
      }

      return {
        url: dataUrl,
        width: width,
        height: height,
      };
    } catch (error: unknown) {
      console.error(`Failed to fetch or process icon from ${uri}: `, error);
      return undefined;
    }
  }

  private async getImageDimensions(dataUrl: string): Promise<{ width: number; height: number }> {
    return new Promise(resolve => {
      const img = new Image();
      img.onload = () => {
        resolve({ width: img.width, height: img.height });
      };
      img.onerror = () => {
        resolve({ width: 0, height: 0 });
      };
      img.src = dataUrl;
    });
  }
}
