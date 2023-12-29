import { Component, NgZone, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { FormControl, FormGroup, NgForm, Validators } from '@angular/forms';
import { DomSanitizer, SafeUrl } from '@angular/platform-browser';
import { Buffer } from 'buffer';
import { CommunicationService } from './communication.service';
import { GlobalDataService } from './global-data.service';
import { GroupStorage } from './group-storage';
import { IconData } from './icon-data';
import { MetadataProviderService } from './metadata-provider.service';
import { Translator as Translations } from './translations';

const bgColorLight = '#fcfcfd';
const bgColorDark = '#1f1b17';

enum PopupState {
  notReady,
  waitInput,
  completed,
}

@Component({
  selector: 'popup-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit, OnDestroy {
  private readonly tabUpdateListener = (
    tabId: number,
    changeInfo: chrome.tabs.TabChangeInfo,
    tab: chrome.tabs.Tab,
  ) => this.zone.run(
    () => this.onTabUpdate(tabId, changeInfo, tab),
  );
  private readonly groupStorageChangeListener = () => this.zone.run(
    () => this.onGroupStorageChange(),
  );
  private readonly colorSchemeChangeListener = () => this.zone.run(
    () => this.onColorSchemeChange(),
  );
  private readonly colorSchemeMediaQuery;
  translations: Translations;
  groupStorage?: GroupStorage;
  tab?: chrome.tabs.Tab;
  favIcon?: IconData;
  favIconSource?: SafeUrl;
  addressControl = new FormControl('', [
    Validators.required,
  ]);
  titleControl = new FormControl('', [
    Validators.required,
  ]);
  groupControl = new FormControl('', [
    Validators.required,
  ]);
  bookmarkInfo = new FormGroup({
    addressControl: this.addressControl,
    titleControl: this.titleControl,
    groupControl: this.groupControl,
  });
  @ViewChild('bookmarkForm')
  bookmarkForm?: NgForm;
  PopupState = PopupState;
  state: PopupState = PopupState.notReady;

  private get groupIndex(): number | null {
    const strValue = this.groupControl.value;
    if (strValue != null) {
      const value = parseInt(strValue);
      if (!isNaN(value)) {
        return value;
      }
    }
    return null;
  }
  private set groupIndex(value: number | null) {
    const strValue = value != null
      ? value.toString()
      : null;
    this.groupControl.setValue(strValue);
  }

  constructor(
    public zone: NgZone,
    private sanitizer: DomSanitizer,
    private globalData: GlobalDataService,
    private communication: CommunicationService,
    private metadataProvider: MetadataProviderService,
  ) {
    this.translations = new Translations();
    this.colorSchemeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    this.state = PopupState.notReady;
    window.addEventListener('load', () => this.onWindowLoad());
  }

  private onWindowLoad() {
    this.colorSchemeMediaQuery.addEventListener('change', this.colorSchemeChangeListener);
    this.onColorSchemeChange();
  }

  private onColorSchemeChange() {
    window.document.body.style.backgroundColor = this.colorSchemeMediaQuery.matches
        ? bgColorDark
        : bgColorLight;
  }

  private updateAddress() {
    if (this.tab?.url !== undefined) {
      this.addressControl.setValue(this.tab.url);
    }
  }

  private updateTitle() {
    if (this.tab?.title !== undefined) {
      this.titleControl.setValue(this.tab.title);
    }
  }

  private async updateFavIcon() {
    if (this.tab?.favIconUrl !== undefined) {
      this.favIcon = await this.metadataProvider.getIconDataByUrl(this.tab.favIconUrl);
      if (this.favIcon !== undefined) {
        const blob = new Blob([this.favIcon.bytes], {
          type: this.favIcon.contentType
        });
        this.favIconSource = this.sanitizer.bypassSecurityTrustUrl(URL.createObjectURL(blob));
      } else {
        this.favIconSource = undefined;
      }
    }
  }

  private updateCurrentGroup() {
    const groupsLength = this.groupStorage?.groupsLength;
    if (groupsLength != null) {
      const currentValue = this.groupIndex;
      if (currentValue == null || currentValue < 0 || currentValue >= groupsLength) {
        if (groupsLength > 0) {
          this.groupIndex = 0;
        }
      }
    }
  }

  private updatePopupState() {
    const isLoaded =
      this.addressControl.value != null &&
      this.titleControl.value != null &&
      this.groupControl.value != null &&
      this.groupStorage !== undefined;
    this.state = isLoaded
      ? PopupState.waitInput
      : PopupState.notReady;
  }

  private onGroupStorageChange(): void {
    this.groupStorage = this.globalData.groupStorage;
    if (this.state !== PopupState.completed) {
      this.updateCurrentGroup();
      this.updatePopupState();
    }
  }

  private async onTabUpdate(_tabId: number, _changeInfo: chrome.tabs.TabChangeInfo, tab: chrome.tabs.Tab) {
    const isUrlChanged = this.tab?.url !== tab.url;
    const isTitleChanged = this.tab?.title !== tab.title;
    const isFavIconChanged = this.tab?.favIconUrl !== tab.favIconUrl;
    this.tab = tab;
    if (isUrlChanged) {
      this.updateAddress();
    }
    if (isTitleChanged) {
      this.updateTitle();
    }
    if (isFavIconChanged) {
      await this.updateFavIcon();
    }
    this.updatePopupState();
  }

  private async getActiveTab() {
    return new Promise<chrome.tabs.Tab>((resolve, reject) => {
      chrome.tabs.query({
        active: true,
        currentWindow: true,
      }, async (tabs) => {
        if (tabs.length > 0) {
          resolve(tabs[0]);
        } else {
          reject('No active tab');
        }
      });
    });
  }

  private async subscribeToTabUpdates() {
    this.tab = await this.getActiveTab();
    chrome.tabs.onUpdated.addListener(this.tabUpdateListener);
    this.updateAddress();
    this.updateTitle();
    await this.updateFavIcon();
    this.updatePopupState();
  }

  private unsubscribeFromTabUpdates() {
    chrome.tabs.onUpdated.removeListener(this.tabUpdateListener);
  }

  ngOnInit(): void {
    this.communication.connect();
    this.globalData.groupStorage.addListener(this.groupStorageChangeListener);
    this.globalData.loadFromStorage().finally(() => {
      this.globalData.subscribeToStorageChange();
    });
    this.subscribeToTabUpdates();
  }

  onSubmit() {
    if (this.bookmarkInfo.valid) {
      const address = this.addressControl.value;
      const title = this.titleControl.value;
      const groupIndex = this.groupIndex;
      if (address != null && title != null && groupIndex != null) {
        const group = this.globalData.groupStorage.groupAt(groupIndex);
        if (group !== undefined) {
          const url = new URL(address);
          const favIconBuffer = this.favIcon !== undefined
            ? Buffer.from(this.favIcon.bytes)
            : undefined;
          group.addBookmark(url, title, favIconBuffer);
          this.globalData.saveToStorage();
          this.state = PopupState.completed;
        }
      }
    }
  }

  ngOnDestroy(): void {
    this.unsubscribeFromTabUpdates();
    this.globalData.unsubscribeFromStorageChange();
    this.globalData.groupStorage.removeAllListeners();
    this.communication.disconnect();
    this.colorSchemeMediaQuery.removeEventListener('change', this.colorSchemeChangeListener);
  }
}
