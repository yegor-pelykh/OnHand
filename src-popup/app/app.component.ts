import { CommonModule } from '@angular/common';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  CUSTOM_ELEMENTS_SCHEMA,
  ElementRef,
  OnDestroy,
  OnInit,
  ViewChild,
} from '@angular/core';
import {
  FormControl,
  FormGroup,
  FormsModule,
  NgForm,
  ReactiveFormsModule,
  Validators,
} from '@angular/forms';
import { DomSanitizer, SafeUrl } from '@angular/platform-browser';
import { Buffer } from 'buffer';
import { CommunicationService } from './communication.service';
import { GlobalDataService } from './global-data.service';
import { GroupStorage } from './group-storage';
import { IconData } from './icon-data';
import { MetadataProviderService } from './metadata-provider.service';
import { Translator } from './translator';

import '@material/web/button/filled-button.js';
import '@material/web/button/text-button.js';
import '@material/web/dialog/dialog.js';
import '@material/web/icon/icon.js';
import '@material/web/list/list.js';
import '@material/web/list/list-item';
import '@material/web/radio/radio.js';
import '@material/web/select/outlined-select';
import '@material/web/select/select-option.js';
import '@material/web/textfield/outlined-text-field.js';

const bgColorLight = '#fcfcfd';
const bgColorDark = '#1f1b17';

enum PopupState {
  notReady,
  waitInput,
  completed,
}

@Component({
  standalone: true,
  imports: [CommonModule, FormsModule, ReactiveFormsModule],
  schemas: [CUSTOM_ELEMENTS_SCHEMA],
  changeDetection: ChangeDetectionStrategy.OnPush,
  selector: 'popup-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss'],
})
export class AppComponent implements OnInit, OnDestroy {
  private readonly tabUpdateListener = (
    tabId: number,
    changeInfo: chrome.tabs.TabChangeInfo,
    tab: chrome.tabs.Tab,
  ) => {
    this.onTabUpdate(tabId, changeInfo, tab);
    this.cdr.markForCheck();
  };
  private readonly groupStorageChangeListener = () => {
    this.onGroupStorageChange();
    this.cdr.markForCheck();
  };
  private readonly colorSchemeChangeListener = () => {
    this.onColorSchemeChange();
    this.cdr.markForCheck();
  };
  private readonly colorSchemeMediaQuery;
  translator: Translator;
  groupStorage?: GroupStorage;
  tab?: chrome.tabs.Tab;
  favIcon?: IconData;
  favIconSource?: SafeUrl;
  addressControl = new FormControl('', [Validators.required]);
  titleControl = new FormControl('', [Validators.required]);
  groupControl = new FormControl('', [Validators.required]);
  bookmarkInfo = new FormGroup({
    addressControl: this.addressControl,
    titleControl: this.titleControl,
    groupControl: this.groupControl,
  });
  PopupState = PopupState;
  state: PopupState = PopupState.notReady;
  groupIndexTemp?: number;
  @ViewChild('bookmarkForm')
  bookmarkForm?: NgForm;
  @ViewChild('dialog')
  dialog?: ElementRef;

  private _groupIndex: number | undefined;
  get groupIndex(): number | undefined {
    return this._groupIndex;
  }
  set groupIndex(value: number | undefined) {
    this._groupIndex = value;
    this.updateGroupControl(this._groupIndex);
  }

  constructor(
    private cdr: ChangeDetectorRef,
    private sanitizer: DomSanitizer,
    private globalData: GlobalDataService,
    private communication: CommunicationService,
    private metadataProvider: MetadataProviderService,
  ) {
    this.translator = new Translator();
    this.colorSchemeMediaQuery = window.matchMedia(
      '(prefers-color-scheme: dark)',
    );
    this.state = PopupState.notReady;
    window.addEventListener('load', () => this.onWindowLoad());
  }

  private onWindowLoad() {
    this.colorSchemeMediaQuery.addEventListener(
      'change',
      this.colorSchemeChangeListener,
    );
    this.onColorSchemeChange();
  }

  private onColorSchemeChange() {
    window.document.body.style.backgroundColor = this.colorSchemeMediaQuery
      .matches
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
      this.favIcon = await this.metadataProvider.getIconDataByUrl(
        this.tab.favIconUrl,
      );
      if (this.favIcon !== undefined) {
        const blob = new Blob([this.favIcon.bytes], {
          type: this.favIcon.contentType,
        });
        this.favIconSource = this.sanitizer.bypassSecurityTrustUrl(
          URL.createObjectURL(blob),
        );
      } else {
        this.favIconSource = undefined;
      }
      this.cdr.markForCheck();
    }
  }

  private updateCurrentGroup() {
    const groupsLength = this.groupStorage?.groupsLength;
    if (groupsLength !== undefined) {
      const currentValue = this.groupIndex;
      if (
        currentValue === undefined ||
        currentValue < 0 ||
        currentValue >= groupsLength
      ) {
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
      this.groupIndex !== undefined &&
      this.groupStorage !== undefined;
    this.state = isLoaded ? PopupState.waitInput : PopupState.notReady;
  }

  private onGroupStorageChange(): void {
    this.groupStorage = this.globalData.groupStorage;
    if (this.state !== PopupState.completed) {
      this.updateCurrentGroup();
      this.updatePopupState();
    }
  }

  private async onTabUpdate(
    _tabId: number,
    _changeInfo: chrome.tabs.TabChangeInfo,
    tab: chrome.tabs.Tab,
  ) {
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
      chrome.tabs.query(
        {
          active: true,
          currentWindow: true,
        },
        async (tabs) => {
          if (tabs.length > 0) {
            resolve(tabs[0]);
          } else {
            reject('No active tab');
          }
        },
      );
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

  private getGroupTitle(index: number | undefined): string | undefined {
    return this.groupStorage !== undefined &&
      index !== undefined &&
      0 <= index &&
      index < this.groupStorage.titles.length
      ? this.groupStorage.titles[index]
      : undefined;
  }

  private updateGroupControl(groupIndex: number | undefined) {
    const groupTitle = this.getGroupTitle(groupIndex) ?? null;
    this.groupControl.setValue(groupTitle, { emitEvent: false });
  }

  ngOnInit(): void {
    this.communication.connect();
    this.globalData.groupStorage.addListener(this.groupStorageChangeListener);
    this.globalData.loadFromStorage().finally(() => {
      this.globalData.subscribeToStorageChange();
    });
    this.subscribeToTabUpdates();
  }

  openGroupSelector(): void {
    const titles = this.groupStorage?.titles;
    if (titles !== undefined && titles.length > 0) {
      this.groupIndexTemp = this.groupIndex;
      const dialogElement = this.dialog?.nativeElement;
      dialogElement?.show();
    }
  }

  closeGroupSelector() {
    const dialogElement = this.dialog?.nativeElement;
    dialogElement?.close();
  }

  selectGroup(i: number) {
    this.groupIndexTemp = i;
  }

  isGroupSelected(i: number): boolean | undefined {
    return this.groupIndexTemp === i ? true : undefined;
  }

  applyGroupSelection() {
    this.groupIndex = this.groupIndexTemp;
    this.closeGroupSelector();
  }

  onSubmit(): void {
    if (this.bookmarkInfo.valid) {
      const address = this.addressControl.value;
      const title = this.titleControl.value;
      const groupIndex = this.groupIndex;
      if (address != null && title != null && groupIndex !== undefined) {
        const group = this.globalData.groupStorage.groupAt(groupIndex);
        if (group !== undefined) {
          const url = new URL(address);
          const favIconBuffer =
            this.favIcon !== undefined
              ? Buffer.from(this.favIcon.bytes)
              : undefined;
          group.addBookmark(url, title, favIconBuffer);
          this.globalData.saveToStorage();
          this.state = PopupState.completed;
          setTimeout(() => {
            window.close();
          }, 3000);
        }
      }
    }
  }

  ngOnDestroy(): void {
    this.unsubscribeFromTabUpdates();
    this.globalData.unsubscribeFromStorageChange();
    this.globalData.groupStorage.removeAllListeners();
    this.communication.disconnect();
    this.colorSchemeMediaQuery.removeEventListener(
      'change',
      this.colorSchemeChangeListener,
    );
  }
}
