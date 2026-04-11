import { CommonModule } from '@angular/common';
import { Component, ElementRef, EventEmitter, Output, ViewChild, inject } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { I18nService } from '@shared/services/i18n.service';

export interface FileUploaderDialogData {
  readonly title?: string;
}

@Component({
  selector: 'app-content-file-uploader',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, MatDialogModule, MatSnackBarModule],
  template: `
    <h2 mat-dialog-title>{{ data.title || i18n.t('import_from_file_dlg_title') }}</h2>
    <mat-dialog-content>
      <div
        class="dropzone"
        tabindex="0"
        role="button"
        [attr.aria-label]="i18n.t('dropzone_welcome_message')"
        (click)="onDropzoneClick()"
        (keydown.enter)="onDropzoneClick()"
        (dragover)="onDragOver($event)"
        (dragleave)="onDragLeave($event)"
        (drop)="onDrop($event)"
        [class.hovering]="isHovering"
        [class.has-file]="hasFile()">
        @if (hasFile()) {
          <mat-icon class="upload-icon" color="primary">description</mat-icon>
          <div class="file-name">{{ getFileName() }}</div>
          <div class="dropzone-subtitle">{{ i18n.t('dropzone_data_apply_question') }}</div>
          <div class="actions">
            <button mat-stroked-button color="primary" type="button" (click)="applyFileContent()">
              {{ i18n.t('apply') }}
            </button>
            <button mat-button color="warn" type="button" (click)="reset()">
              {{ i18n.t('cancel') }}
            </button>
          </div>
        } @else {
          <mat-icon class="upload-icon" color="primary">upload_file</mat-icon>
          <div class="dropzone-title">{{ i18n.t('dropzone_welcome_message') }}</div>
          <div class="dropzone-subtitle">{{ i18n.t('dropzone_welcome_message_alt') }}</div>
          <button mat-stroked-button color="primary" type="button" (click)="onSelectFileClick($event)">
            {{ i18n.t('select_file') }}
          </button>
          <input #fileInput type="file" accept=".onhand" (change)="onFileSelected($event)" style="display:none;" />
        }
      </div>
    </mat-dialog-content>
    @if (!hasFile()) {
      <mat-dialog-actions>
        <button mat-button type="button" (click)="cancel()">{{ i18n.t('cancel') }}</button>
      </mat-dialog-actions>
    }
  `,
  styles: [
    `
      .dropzone {
        width: 100%;
        min-height: 220px;
        border: 2px dashed var(--mat-sys-outline-variant);
        border-radius: var(--mat-sys-corner-medium);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        cursor: pointer;
        transition:
          border-color 0.2s,
          background 0.2s;
        outline: none;
        margin: 16px 0;
        background: var(--mat-sys-surface-container-low);
        position: relative;
        -webkit-user-select: none;
        user-select: none;
      }
      .dropzone.hovering {
        border-color: var(--mat-sys-primary);
        background: var(--mat-sys-primary-container);
      }
      .dropzone.has-file {
        border-style: solid;
        border-color: var(--mat-sys-primary);
        background: var(--mat-sys-surface-container);
      }
      .upload-icon {
        font-size: 32px;
        height: 32px;
        width: 32px;
        margin-bottom: 12px;
        color: var(--mat-sys-primary);
      }
      .dropzone-title {
        font: var(--mat-sys-title-medium);
        margin-bottom: 4px;
        color: var(--mat-sys-on-surface);
      }
      .dropzone-subtitle {
        font: var(--mat-sys-body-large);
        color: var(--mat-sys-on-surface-variant);
        margin-bottom: 18px;
      }
      .file-name {
        font: var(--mat-sys-title-medium);
        color: var(--mat-sys-primary);
        margin-bottom: 8px;
        word-break: break-all;
        text-align: center;
      }
      .actions {
        display: flex;
        gap: 12px;
        margin-top: 10px;
      }
    `,
  ],
})
export class FileUploaderComponent {
  @Output() public readonly fileContent: EventEmitter<string> = new EventEmitter<string>();
  @ViewChild('fileInput') private readonly _fileInput!: ElementRef<HTMLInputElement>;
  public readonly data = inject(MAT_DIALOG_DATA) as FileUploaderDialogData;
  public readonly i18n = inject(I18nService);
  private readonly _dialogRef = inject(MatDialogRef) as MatDialogRef<FileUploaderComponent, void>;
  private readonly _snackBar = inject(MatSnackBar);
  private _isHovering = false;
  private _file: File | undefined = undefined;

  public get isHovering(): boolean {
    return this._isHovering;
  }

  public hasFile(): boolean {
    return !!this._file;
  }

  public getFileName(): string {
    return this._file ? this._file.name : '';
  }

  public onDropzoneClick(): void {
    this._openFileDialog();
  }

  public onSelectFileClick(event: MouseEvent): void {
    this._openFileDialog();
    event.stopPropagation();
  }

  public onDragOver(event: DragEvent): void {
    event.preventDefault();
    this._isHovering = true;
  }

  public onDragLeave(event: DragEvent): void {
    event.preventDefault();
    this._isHovering = false;
  }

  public onDrop(event: DragEvent): void {
    event.preventDefault();
    this._isHovering = false;
    const files: FileList | null | undefined = event.dataTransfer?.files;
    if (files && files.length > 0) {
      this._setFile(files[0]);
    }
  }

  public onFileSelected(event: Event): void {
    const input = event.target as HTMLInputElement;
    if (input.files && input.files.length > 0) {
      this._setFile(input.files[0]);
    }
  }

  public applyFileContent(): void {
    if (!this._file) {
      return;
    }
    const reader: FileReader = new FileReader();
    reader.onload = (): void => {
      if (typeof reader.result === 'string') {
        this.fileContent.emit(reader.result);
        this._dialogRef.close();
      }
    };
    reader.readAsText(this._file);
  }

  public reset(): void {
    this._file = undefined;
    if (this._fileInput?.nativeElement) {
      this._fileInput.nativeElement.value = '';
    }
  }

  public cancel(): void {
    this._dialogRef.close();
  }

  private _openFileDialog(): void {
    if (this._fileInput?.nativeElement) {
      this._fileInput.nativeElement.click();
    }
  }

  private _setFile(file: File): void {
    if (file.name.toLowerCase().endsWith('.onhand')) {
      this._file = file;
    } else {
      this._file = undefined;
      this._snackBar.open(this.i18n.t('file_uploader_invalid_file_type'), this.i18n.t('ok'), {
        duration: 3000,
      });
      if (this._fileInput?.nativeElement) {
        this._fileInput.nativeElement.value = '';
      }
    }
  }
}
