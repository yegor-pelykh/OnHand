import { Injectable } from '@angular/core';

@Injectable({
  providedIn: 'root',
})
export class ChromeService {
  public async openUrlInTab(url: string, newTab = false): Promise<void> {
    if (chrome?.tabs !== undefined) {
      if (newTab) {
        await chrome.tabs.create({ url, active: false });
      } else {
        const currentTab = await this.getCurrentActiveTab();
        if (currentTab?.id !== undefined) {
          await chrome.tabs.update(currentTab.id, { url, active: true });
        } else {
          await chrome.tabs.create({ url, active: true });
        }
      }
    } else {
      window.open(url, newTab ? '_blank' : '_self');
    }
  }

  public async getCurrentActiveTab(): Promise<chrome.tabs.Tab | undefined> {
    if (chrome?.tabs === undefined) {
      return undefined;
    }
    return new Promise(resolve => {
      chrome.tabs.query({ active: true, currentWindow: true }, (tabs: chrome.tabs.Tab[]) => {
        resolve(tabs[0]);
      });
    });
  }

  public addTabUpdateListener(
    listener: (tabId: number, changeInfo: chrome.tabs.OnUpdatedInfo, tab: chrome.tabs.Tab) => void
  ): void {
    if (chrome?.tabs !== undefined) {
      chrome.tabs.onUpdated.addListener(listener);
    }
  }

  public removeTabUpdateListener(
    listener: (tabId: number, changeInfo: chrome.tabs.OnUpdatedInfo, tab: chrome.tabs.Tab) => void
  ): void {
    if (chrome?.tabs !== undefined) {
      chrome.tabs.onUpdated.removeListener(listener);
    }
  }
}
