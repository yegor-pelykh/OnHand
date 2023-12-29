import { HttpClient, HttpResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Buffer } from 'buffer';
import { lastValueFrom } from 'rxjs';
import { CommunicationService } from './communication.service';
import { IconData } from './icon-data';

const contentTypeFlagPng = 'png';
const contentTypeFlagSvg = 'svg+xml';

@Injectable({
  providedIn: 'root'
})
export class MetadataProviderService {
  constructor(
    private http: HttpClient,
    private communication: CommunicationService,
  ) { }

  async getIconDataByUrl(url: string) {
    let response: HttpResponse<ArrayBuffer>;
    try {
      response = await lastValueFrom(this.http.get(url, {
        observe: 'response',
        responseType: 'arraybuffer',
      }));
    } catch {
      return undefined;
    }
    if (!response.ok || response.body == null) {
      return undefined;
    }
    const contentType = response.headers.get('content-type')?.toLowerCase();
    if (contentType == null) {
      return undefined;
    }
    if (!contentType.includes('image') && !contentType.includes('application/octet-stream')) {
      return undefined;
    }
    const origImageBytes = Buffer.from(response.body);
    if (contentType.includes(contentTypeFlagSvg) || url.endsWith('.svg')) {
      return new IconData(contentType, origImageBytes);
    } else {
      try {
        const convResponse = await this.communication.sendMessage(
          'to-png',
          {
            'contentType': contentType,
            'content': origImageBytes.toString('base64'),
          },
        );
        if (typeof convResponse !== 'object') {
          return undefined;
        }
        const imageBytes = 'bytes' in convResponse && typeof convResponse['bytes'] === 'string'
          ? Buffer.from(convResponse['bytes'], 'base64')
          : undefined;
        const width = 'width' in convResponse && typeof convResponse['width'] === 'number'
          ? convResponse['width']
          : 0;
        const height = 'height' in convResponse && typeof convResponse['height'] === 'number'
          ? convResponse['height']
          : 0;
        if (imageBytes === undefined || width == 0 || height == 0) {
          return undefined;
        }
        return new IconData(
          `image/${contentTypeFlagPng}`,
          imageBytes,
          width,
          height,
        );
      } catch {
        return undefined;
      }
    }
  }
}
