import { CommonModule } from '@angular/common';
import { toSignal } from '@angular/core/rxjs-interop';
import { Component, OnInit, Signal, effect, inject, signal } from '@angular/core';
import {
  AbstractControl,
  FormBuilder,
  FormControl,
  FormGroup,
  ReactiveFormsModule,
  ValidatorFn,
  Validators,
} from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MatOptionModule } from '@angular/material/core';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatIconModule } from '@angular/material/icon';
import { MatInputModule } from '@angular/material/input';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { MatSelectModule } from '@angular/material/select';
import { MatTooltipModule } from '@angular/material/tooltip';
import { debounceTime, distinctUntilChanged, startWith } from 'rxjs';
import { isURL } from 'validator';
import { Metadata } from '@shared/models/metadata.model';
import { I18nService } from '@shared/services/i18n.service';
import { MetadataService } from '@shared/services/metadata.service';

export interface BookmarkEditorData {
  readonly mode: 'create' | 'edit';
  readonly groupTitles: readonly string[];
  readonly selectedGroupTitle?: string;
  readonly initialAddress?: string;
  readonly initialTitle?: string;
  readonly initialIconUrl?: string;
}

export interface BookmarkEditorResult {
  readonly address: string;
  readonly title: string;
  readonly groupTitle: string;
  readonly iconUrl?: string;
}

const protocolHttp = 'http';
const protocolHttps = 'https';
const protocolsToTryIfNoScheme: readonly string[] = [protocolHttps, protocolHttp];

type BookmarkForm = FormGroup<{
  address: FormControl<string>;
  title: FormControl<string>;
  groupTitle: FormControl<string>;
}>;

@Component({
  selector: 'app-content-bookmark-editor',
  standalone: true,
  imports: [
    CommonModule,
    ReactiveFormsModule,
    MatFormFieldModule,
    MatDialogModule,
    MatInputModule,
    MatSelectModule,
    MatOptionModule,
    MatButtonModule,
    MatIconModule,
    MatProgressSpinnerModule,
    MatTooltipModule,
  ],
  template: `
    <h2 mat-dialog-title>
      {{ data.mode === 'create' ? i18n.t('bookmark_creating_dlg_title') : i18n.t('bookmark_editing_dlg_title') }}
    </h2>
    <mat-dialog-content>
      <form [formGroup]="bookmarkForm" class="editor-form" (ngSubmit)="submit()">
        <div class="address-row">
          <mat-form-field class="address-field">
            <mat-label>{{ i18n.t('bookmark_address_label') }}</mat-label>
            <input matInput formControlName="address" required cdkFocusInitial />
            @if (bookmarkForm.get('address')?.hasError('required') && bookmarkForm.get('address')?.touched) {
              <mat-error>{{ i18n.t('bookmark_address_empty_hint') }}</mat-error>
            }
            @if (bookmarkForm.get('address')?.hasError('invalidUrl') && bookmarkForm.get('address')?.touched) {
              <mat-error>{{ i18n.t('bookmark_address_invalid_hint') }}</mat-error>
            }
          </mat-form-field>
          <div
            class="metadata-error-icon-container"
            [class.visible]="
              bookmarkForm.get('address')?.valid &&
              metadataState() === 'noMetadata' &&
              bookmarkForm.get('address')?.value
            "
            [matTooltip]="i18n.t('bookmark_metadata_not_found_hint')"
            matTooltipPosition="above">
            <mat-icon color="warn">info</mat-icon>
          </div>
        </div>
        <div class="title-icon-row">
          <mat-form-field class="flex-grow">
            <mat-label>{{ i18n.t('bookmark_title_label') }}</mat-label>
            <input matInput formControlName="title" required />
            @if (bookmarkForm.get('title')?.hasError('required') && bookmarkForm.get('title')?.touched) {
              <mat-error>{{ i18n.t('bookmark_title_empty_hint') }}</mat-error>
            }
          </mat-form-field>
          <div class="icon-preview-area">
            @if (metadataState() === 'requesting') {
              <mat-progress-spinner mode="indeterminate" diameter="24" strokeWidth="2"></mat-progress-spinner>
            } @else if (metadata()?.icon) {
              <img [src]="metadata()!.icon!.url" alt="icon" width="24" height="24" class="bookmark-icon" />
            } @else {
              <mat-icon color="primary">link</mat-icon>
            }
          </div>
        </div>
        <mat-form-field class="group-selector">
          <mat-label>{{ i18n.t('bookmark_group_label') }}</mat-label>
          <mat-select formControlName="groupTitle" required>
            @for (g of groupTitles; track g) {
              <mat-option [value]="g">{{ g }}</mat-option>
            }
          </mat-select>
          @if (bookmarkForm.get('groupTitle')?.hasError('required') && bookmarkForm.get('groupTitle')?.touched) {
            <mat-error>{{ i18n.t('bookmark_group_empty_hint') }}</mat-error>
          }
        </mat-form-field>
      </form>
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button type="button" (click)="cancel()">
        {{ i18n.t('cancel') }}
      </button>
      <button
        mat-stroked-button
        (click)="submit()"
        [disabled]="bookmarkForm.invalid || metadataState() === 'requesting'">
        {{ data.mode === 'create' ? i18n.t('create') : i18n.t('apply') }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      .editor-form {
        min-width: 400px;
        margin: 16px 0;
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
      .group-selector {
        width: 100%;
        margin-top: 16px;
      }
      .title-icon-row {
        display: flex;
        margin-top: 16px;
        gap: 8px;
      }
      .flex-grow {
        flex: 1;
      }
      .icon-preview-area {
        width: 40px;
        height: 40px;
        display: flex;
        align-items: center;
        justify-content: center;
        flex-shrink: 0;
        margin-top: 8px;
      }
      .bookmark-icon {
        width: 24px;
        height: 24px;
        object-fit: contain;
      }
    `,
  ],
})
export class BookmarkEditorComponent implements OnInit {
  public readonly i18n = inject(I18nService);
  public readonly data = inject(MAT_DIALOG_DATA) as BookmarkEditorData;
  public readonly bookmarkForm: BookmarkForm;
  public readonly groupTitles: readonly string[];
  public readonly metadata = signal<Metadata | undefined>(undefined);
  public readonly metadataState = signal<'noMetadata' | 'requesting' | 'metadataReady'>('noMetadata');
  private readonly _dialogRef = inject(MatDialogRef) as MatDialogRef<
    BookmarkEditorComponent,
    BookmarkEditorResult | undefined
  >;
  private readonly _formBuilder = inject(FormBuilder);
  private readonly _metadataService = inject(MetadataService);
  private readonly _addressInputSignal: Signal<string>;
  private readonly _currentRequestId = signal<number>(0);

  constructor() {
    this.groupTitles = this.data.groupTitles;
    this.bookmarkForm = this._formBuilder.group({
      address: ['', [Validators.required, BookmarkEditorComponent._urlValidator]],
      title: ['', Validators.required],
      groupTitle: ['', Validators.required],
    }) as BookmarkForm;
    const initialAddressForSignal: string = this.data.initialAddress ?? '';
    this._addressInputSignal = toSignal(
      this.bookmarkForm.controls.address.valueChanges.pipe(
        startWith(initialAddressForSignal),
        debounceTime(500),
        distinctUntilChanged()
      ),
      { initialValue: initialAddressForSignal }
    );

    effect(() => {
      const address: string = this._addressInputSignal();
      if (address && BookmarkEditorComponent._isValidUrl(address)) {
        this._currentRequestId.update(id => id + 1);
        void this._fetchAndSetMetadata(address, this._currentRequestId());
      } else {
        this.metadata.set(undefined);
        this.metadataState.set('noMetadata');
        this._currentRequestId.set(0);
      }
    });
  }

  private static _isValidUrl(address: string): boolean {
    const testAddress =
      !address.startsWith(protocolHttp) && !address.startsWith(protocolHttps)
        ? `${protocolHttp}://${address}`
        : address;
    return isURL(testAddress, { require_tld: false, allow_underscores: true });
  }

  private static _urlValidator: ValidatorFn = (control: AbstractControl): Record<string, boolean> | null => {
    const address = control.value as string;
    if (!address || address.trim().length === 0) {
      return null;
    }
    return BookmarkEditorComponent._isValidUrl(address) ? null : { invalidUrl: true };
  };

  public ngOnInit(): void {
    this.bookmarkForm.patchValue({
      address: this.data.initialAddress ?? '',
      title: this.data.initialTitle ?? '',
      groupTitle: this.data.selectedGroupTitle ?? (this.groupTitles.length > 0 ? this.groupTitles[0] : ''),
    });
    if (this.data.initialTitle) {
      this.bookmarkForm.controls.title.markAsDirty();
    }
    if (this.data.initialIconUrl) {
      this.metadata.set({ icon: { url: this.data.initialIconUrl } });
      this.metadataState.set('metadataReady');
    }
  }

  public submit(): void {
    this.bookmarkForm.markAllAsTouched();
    if (!this.bookmarkForm.valid) {
      return;
    }
    if (this.metadataState() === 'requesting') {
      return;
    }
    const formValue = this.bookmarkForm.value;
    const result: BookmarkEditorResult = {
      address: formValue.address!,
      title: formValue.title!,
      groupTitle: formValue.groupTitle!,
      iconUrl: this.metadata()?.icon?.url,
    };
    this._dialogRef.close(result);
  }

  public cancel(): void {
    this._dialogRef.close(undefined);
  }

  private async _fetchAndSetMetadata(address: string, requestId: number): Promise<void> {
    this.metadataState.set('requesting');
    let fetchedMetadata: Metadata | undefined;
    let finalAddress: string = address;
    try {
      if (!address.startsWith(protocolHttp) && !address.startsWith(protocolHttps)) {
        for (const protocol of protocolsToTryIfNoScheme) {
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
      if (requestId === this._currentRequestId()) {
        this.metadata.set(fetchedMetadata);
        if (fetchedMetadata) {
          if (fetchedMetadata.title && this.bookmarkForm.controls.title.value === '') {
            this.bookmarkForm.controls.title.setValue(fetchedMetadata.title);
          }
          if (this.bookmarkForm.controls.address.value !== finalAddress) {
            this.bookmarkForm.controls.address.setValue(finalAddress, { emitEvent: false });
          }
          this.metadataState.set('metadataReady');
        } else {
          this.metadataState.set('noMetadata');
        }
      }
    } catch {
      if (requestId === this._currentRequestId()) {
        this.metadata.set(undefined);
        this.metadataState.set('noMetadata');
      }
    }
  }
}
