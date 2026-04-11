import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, Signal, effect, inject, signal } from '@angular/core';
import { toObservable, toSignal } from '@angular/core/rxjs-interop';
import { AbstractControl, FormBuilder, FormGroup, ReactiveFormsModule, ValidatorFn, Validators } from '@angular/forms';
import { DomSanitizer, SafeUrl } from '@angular/platform-browser';
import { MatButtonModule } from '@angular/material/button';
import { MatOptionModule } from '@angular/material/core';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatTooltipModule } from '@angular/material/tooltip';
import { Observable, debounceTime, distinctUntilChanged, filter, firstValueFrom, startWith } from 'rxjs';
import { isURL } from 'validator';
import { Metadata } from '@shared/models/metadata.model';
import { I18nService } from '@shared/services/i18n.service';
import { MetadataService } from '@shared/services/metadata.service';
import { StorageService } from '@shared/services/storage.service';
import { Group } from '@shared/models/group.model';
import { ChromeService } from '../services/chrome.service';

enum PopupState {
  NotReady = 'NotReady',
  LoadingMetadata = 'LoadingMetadata',
  InputForm = 'InputForm',
  Completed = 'Completed',
  Error = 'Error',
}

const PROTOCOL_HTTP = 'http';
const PROTOCOL_HTTPS = 'https';
const PROTOCOLS_TO_TRY_IF_NO_SCHEME = [PROTOCOL_HTTPS, PROTOCOL_HTTP];
const POPUP_CLOSE_DELAY_MS = 1500;

@Component({
  selector: 'app-popup-root',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatInputModule,
    MatButtonModule,
    MatIconModule,
    MatSelectModule,
    MatOptionModule,
    MatProgressSpinnerModule,
    MatTooltipModule,
  ],
  template: `
    <div class="main-container">
      @switch (state()) {
        @case (PopupState.NotReady) {
          <div class="splash-screen">
            <mat-progress-spinner mode="indeterminate" diameter="50"></mat-progress-spinner>
          </div>
        }
        @case (PopupState.LoadingMetadata) {
          <div class="splash-screen">
            <mat-progress-spinner mode="indeterminate" diameter="50"></mat-progress-spinner>
            <p>{{ i18nService.t('loading_metadata_hint') }}</p>
          </div>
        }
        @case (PopupState.InputForm) {
          <form [formGroup]="bookmarkForm" class="bookmark-info-form" (ngSubmit)="onSubmit()">
            <div class="favicon-area">
              @if (metadataState() === 'requesting') {
                <mat-progress-spinner
                  mode="indeterminate"
                  diameter="24"
                  strokeWidth="2"
                  aria-label="{{ i18nService.t('loading_metadata_hint') }}"></mat-progress-spinner>
              } @else if (favIconSource()) {
                <img
                  [src]="favIconSource()!"
                  alt="{{ bookmarkForm.get('title')?.value }} icon"
                  width="24"
                  height="24" />
              } @else {
                <mat-icon color="primary" aria-label="Default link icon">link</mat-icon>
              }
            </div>
            <div class="address-row">
              <mat-form-field appearance="fill" class="address-field">
                <mat-label>{{ i18nService.t('bookmark_address_label') }}</mat-label>
                <input matInput formControlName="address" required cdkFocusInitial />
                @if (bookmarkForm.get('address')?.hasError('required') && bookmarkForm.get('address')?.touched) {
                  <mat-error>{{ i18nService.t('bookmark_address_empty_hint') }}</mat-error>
                }
                @if (bookmarkForm.get('address')?.hasError('invalidUrl') && bookmarkForm.get('address')?.touched) {
                  <mat-error>{{ i18nService.t('bookmark_address_invalid_hint') }}</mat-error>
                }
              </mat-form-field>
              <div
                class="metadata-error-icon-container"
                [class.visible]="
                  bookmarkForm.get('address')?.valid &&
                  metadataState() === 'noMetadata' &&
                  bookmarkForm.get('address')?.value
                "
                [matTooltip]="i18nService.t('bookmark_metadata_not_found_hint')"
                matTooltipPosition="above">
                <mat-icon color="warn" aria-label="{{ i18nService.t('bookmark_metadata_not_found_hint') }}"
                  >info</mat-icon
                >
              </div>
            </div>
            <mat-form-field appearance="fill" class="full-width-input">
              <mat-label>{{ i18nService.t('bookmark_title_label') }}</mat-label>
              <input matInput formControlName="title" required />
              @if (bookmarkForm.get('title')?.hasError('required') && bookmarkForm.get('title')?.touched) {
                <mat-error>{{ i18nService.t('bookmark_title_empty_hint') }}</mat-error>
              }
            </mat-form-field>
            <mat-form-field appearance="fill" class="full-width-input">
              <mat-label>{{ i18nService.t('bookmark_group_label') }}</mat-label>
              <mat-select formControlName="groupTitle" required>
                @for (group of storageService.groupStorage().groups; track group.id) {
                  <mat-option [value]="group.title">{{ group.title }}</mat-option>
                }
              </mat-select>
              @if (bookmarkForm.get('groupTitle')?.hasError('required') && bookmarkForm.get('groupTitle')?.touched) {
                <mat-error>{{ i18nService.t('bookmark_group_empty_hint') }}</mat-error>
              }
            </mat-form-field>
            <button
              mat-stroked-button
              color="primary"
              type="submit"
              [disabled]="bookmarkForm.invalid || metadataState() === 'requesting'"
              aria-label="{{ i18nService.t('add_bookmark') }}">
              {{ i18nService.t('add_bookmark') }}
            </button>
          </form>
        }
        @case (PopupState.Completed) {
          <div class="success-info-container">
            <mat-icon class="success-icon" aria-label="{{ i18nService.t('bookmark_created_hint') }}"
              >bookmark_added</mat-icon
            >
            <div class="success-text">{{ i18nService.t('bookmark_created_hint') }}</div>
          </div>
        }
        @case (PopupState.Error) {
          <div class="error-state">
            <mat-icon color="warn" aria-label="{{ i18nService.t('popup_error_hint') }}">error</mat-icon>
            <p>{{ i18nService.t('popup_error_hint') }}</p>
          </div>
        }
      }
    </div>
  `,
  styles: [
    `
      :host {
        margin: 0;
        padding: 0;
      }
      .main-container {
        min-width: 400px;
        min-height: 400px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        padding: 48px;
      }
      .splash-screen,
      .error-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        text-align: center;
        gap: 16px;
      }
      .bookmark-info-form {
        display: flex;
        flex-direction: column;
        align-items: stretch;
        width: 100%;
        gap: 12px;
      }
      .favicon-area {
        align-self: center;
        width: 24px;
        height: 24px;
        display: flex;
        align-items: center;
        justify-content: center;
        margin-bottom: 20px;
      }
      .favicon-area img {
        width: 100%;
        height: 100%;
        object-fit: contain;
      }
      .favicon-area mat-icon {
        font-variation-settings: 'FILL' 1;
        width: 100%;
        height: 100%;
      }
      .full-width-input {
        width: 100%;
      }
      .address-row {
        display: flex;
        align-items: flex-start;
        gap: 8px;
        width: 100%;
      }
      .address-field {
        flex-grow: 1;
      }
      .metadata-error-icon-container {
        width: 0;
        overflow: hidden;
        opacity: 0;
        transform: translateX(100%);
        transition:
          width 0.3s ease-in-out,
          opacity 0.3s ease-in-out,
          transform 0.3s ease-in-out;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        height: 40px;
        margin-top: 8px;
      }
      .metadata-error-icon-container.visible {
        opacity: 1;
        transform: translateX(0);
        width: 40px;
      }
      .metadata-error-icon-container mat-icon {
        font-size: 24px;
        height: 24px;
        width: 24px;
      }
      .success-info-container,
      .error-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 100%;
      }
      .success-icon,
      .error-state mat-icon {
        font-variation-settings: 'FILL' 1;
        font-size: 100px;
        width: 100px;
        height: 100px;
        color: var(--mat-sys-primary);
      }
      .error-state mat-icon {
        color: var(--mat-sys-error);
      }
      .success-text {
        color: var(--mat-sys-primary);
        font-size: 1.1em;
        margin-top: 20px;
        text-align: center;
      }
    `,
  ],
})
export class AppComponent implements OnInit, OnDestroy {
  public readonly i18nService = inject(I18nService);
  public readonly storageService = inject(StorageService);
  public readonly bookmarkForm: FormGroup;
  public readonly state = signal<PopupState>(PopupState.NotReady);
  public readonly favIconSource = signal<SafeUrl | undefined>(undefined);
  public readonly metadataState = signal<'noMetadata' | 'requesting' | 'metadataReady'>('noMetadata');
  protected readonly PopupState: typeof PopupState = PopupState;
  private readonly _metadataService = inject(MetadataService);
  private readonly _chromeService = inject(ChromeService);
  private readonly _domSanitizer = inject(DomSanitizer);
  private readonly _formBuilder = inject(FormBuilder);
  private readonly _currentTab = signal<chrome.tabs.Tab | undefined>(undefined);
  private readonly _metadata = signal<Metadata | undefined>(undefined);
  private readonly _addressInputSignal: Signal<string>;
  private readonly _tabUpdateListener: (
    tabId: number,
    changeInfo: chrome.tabs.OnUpdatedInfo,
    tab: chrome.tabs.Tab
  ) => void;
  private readonly _storageLoaded$: Observable<boolean>;
  private _currentRequestId = 0;

  constructor() {
    this.bookmarkForm = this._formBuilder.group({
      address: ['', [Validators.required, AppComponent._urlValidator]],
      title: ['', Validators.required],
      groupTitle: ['', Validators.required],
    });
    this._addressInputSignal = toSignal(
      this.bookmarkForm.controls['address'].valueChanges.pipe(startWith(''), debounceTime(500), distinctUntilChanged()),
      { initialValue: '' }
    );
    this._tabUpdateListener = (tabId: number, changeInfo: chrome.tabs.OnUpdatedInfo, tab: chrome.tabs.Tab): void =>
      this._onTabUpdated(tabId, changeInfo, tab);
    effect(() => {
      const address: string = this._addressInputSignal();
      if (address && AppComponent._isValidUrl(address)) {
        const requestId: number = ++this._currentRequestId;
        void this._fetchAndSetMetadata(address, undefined, requestId);
      } else {
        this._metadata.set(undefined);
        this.metadataState.set('noMetadata');
        this.favIconSource.set(undefined);
        this._currentRequestId = 0;
      }
    });
    this._storageLoaded$ = toObservable(this.storageService.loaded);
  }

  private static _isValidUrl(address: string): boolean {
    const testAddress: string =
      !address.startsWith(PROTOCOL_HTTP) && !address.startsWith(PROTOCOL_HTTPS)
        ? `${PROTOCOL_HTTP}://${address}`
        : address;
    return isURL(testAddress, { require_tld: false, allow_underscores: true });
  }

  private static readonly _urlValidator: ValidatorFn = (control: AbstractControl): { invalidUrl: boolean } | null => {
    const address = control.value as string | null;
    if (!address) {
      return null;
    }
    return AppComponent._isValidUrl(address) ? null : { invalidUrl: true };
  };

  public ngOnInit(): void {
    void this._initializePopup();
  }

  public ngOnDestroy(): void {
    this._chromeService.removeTabUpdateListener(this._tabUpdateListener);
  }

  public async onSubmit(): Promise<void> {
    this.bookmarkForm.markAllAsTouched();
    if (!this.bookmarkForm.valid || this.metadataState() === 'requesting') {
      return;
    }
    const { address, title, groupTitle } = this.bookmarkForm.value as {
      address: string;
      title: string;
      groupTitle: string;
    };
    const iconUrl: string | undefined = this._metadata()?.icon?.url;
    const targetGroup = this.storageService.groupStorage().groups.find((group: Group) => group.title === groupTitle);
    if (targetGroup) {
      await this.storageService.addBookmark(targetGroup.id, address, title, iconUrl);
      this.state.set(PopupState.Completed);
      setTimeout(() => {
        window.close();
      }, POPUP_CLOSE_DELAY_MS);
    } else {
      this.state.set(PopupState.Error);
    }
  }

  private async _initializePopup(): Promise<void> {
    this.state.set(PopupState.NotReady);
    try {
      await firstValueFrom(this._storageLoaded$.pipe(filter((loaded: boolean) => loaded)));
      const groupStorage = this.storageService.groupStorage();
      if (!groupStorage || groupStorage.groups.length === 0) {
        this.state.set(PopupState.Error);
        return;
      }
      if (!this.bookmarkForm.get('groupTitle')?.value) {
        this.bookmarkForm.get('groupTitle')?.setValue(groupStorage.groups[0].title);
      }
      const currentActiveTab: chrome.tabs.Tab | undefined = await this._chromeService.getCurrentActiveTab();
      if (!currentActiveTab?.url) {
        this.state.set(PopupState.Error);
        return;
      }
      this._currentTab.set(currentActiveTab);
      const urlWithoutTrailingSlash: string = this._trimTrailingSlash(currentActiveTab.url);
      this.bookmarkForm.patchValue({
        address: urlWithoutTrailingSlash,
        title: currentActiveTab.title ?? urlWithoutTrailingSlash,
      });
      this.state.set(PopupState.LoadingMetadata);
      void this._fetchAndSetMetadata(urlWithoutTrailingSlash, currentActiveTab.favIconUrl);
      this.state.set(PopupState.InputForm);
      this._chromeService.addTabUpdateListener(this._tabUpdateListener);
    } catch {
      this.state.set(PopupState.Error);
    }
  }

  private _onTabUpdated(tabId: number, changeInfo: chrome.tabs.OnUpdatedInfo, tab: chrome.tabs.Tab): void {
    if (tab.id === this._currentTab()?.id && tab.active) {
      if (changeInfo.url || changeInfo.title || changeInfo.favIconUrl) {
        this._currentTab.set(tab);
        const urlWithoutTrailingSlash: string = tab.url ? this._trimTrailingSlash(tab.url) : tab.url!;
        this.bookmarkForm.patchValue({
          address: urlWithoutTrailingSlash,
          title: tab.title ?? urlWithoutTrailingSlash,
        });
        if (tab.url) {
          void this._fetchAndSetMetadata(urlWithoutTrailingSlash, tab.favIconUrl);
        }
      }
    }
  }

  private async _fetchAndSetMetadata(
    address: string,
    initialFavIconUrl?: string,
    effectRequestId?: number
  ): Promise<void> {
    if (effectRequestId !== undefined && effectRequestId !== this._currentRequestId) {
      return;
    }
    this.metadataState.set('requesting');
    let fetchedMetadata: Metadata | undefined;
    let finalAddress: string = address;
    let iconUrlToUse: string | undefined = initialFavIconUrl;
    try {
      if (!address.startsWith(PROTOCOL_HTTP) && !address.startsWith(PROTOCOL_HTTPS)) {
        for (const protocol of PROTOCOLS_TO_TRY_IF_NO_SCHEME) {
          const fullUri = `${protocol}://${address}`;
          fetchedMetadata = await this._metadataService.getMetadata(fullUri);
          if (fetchedMetadata) {
            finalAddress = fullUri;
            break;
          }
        }
      } else {
        fetchedMetadata = await this._metadataService.getMetadata(address);
      }
      if (effectRequestId !== undefined && effectRequestId !== this._currentRequestId) {
        return;
      }
      this._metadata.set(fetchedMetadata);
      if (fetchedMetadata) {
        if (
          fetchedMetadata.title &&
          (!this.bookmarkForm.get('title')?.dirty || this.bookmarkForm.get('title')?.value === '')
        ) {
          this.bookmarkForm.get('title')?.setValue(fetchedMetadata.title);
        }
        if (this.bookmarkForm.get('address')?.value !== finalAddress) {
          this.bookmarkForm.get('address')?.setValue(finalAddress, { emitEvent: false });
        }
        if (fetchedMetadata.icon?.url) {
          iconUrlToUse = fetchedMetadata.icon.url;
        }
        this.metadataState.set('metadataReady');
      } else {
        this.metadataState.set('noMetadata');
      }
    } catch {
      if (effectRequestId !== undefined && effectRequestId !== this._currentRequestId) {
        return;
      }
      this._metadata.set(undefined);
      this.metadataState.set('noMetadata');
    } finally {
      if (effectRequestId === undefined || effectRequestId === this._currentRequestId) {
        if (iconUrlToUse) {
          this.favIconSource.set(this._domSanitizer.bypassSecurityTrustUrl(iconUrlToUse));
        } else {
          this.favIconSource.set(undefined);
        }
      }
    }
  }

  private _trimTrailingSlash(url: string): string {
    if (url.endsWith('/')) {
      return url.slice(0, -1);
    }
    return url;
  }
}
