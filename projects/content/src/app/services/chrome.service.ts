import { Injectable } from '@angular/core';

@Injectable({ providedIn: 'root' })
export class ChromeService {
  public async openTab(url: string, newTab = false): Promise<void> {
    if (newTab) {
      if (chrome?.tabs !== undefined) {
        await chrome.tabs.create({ url, active: false });
      } else {
        window.open(url, '_blank');
      }
    } else {
      window.open(url, '_self');
    }
  }

  public async launch(url: string, newTab: boolean): Promise<void> {
    await this.openTab(url, newTab);
  }
}
