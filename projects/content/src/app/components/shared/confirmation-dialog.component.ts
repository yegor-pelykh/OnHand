import { CommonModule } from '@angular/common';
import { Component, inject } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialogModule } from '@angular/material/dialog';
import { I18nService } from '@shared/services/i18n.service';

export interface ConfirmationDialogData {
  readonly title: string;
  readonly content: string;
  readonly confirmText?: string;
  readonly cancelText?: string;
}

@Component({
  selector: 'app-content-confirmation-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, MatButtonModule],
  template: `
    <h2 mat-dialog-title>{{ data.title }}</h2>
    <mat-dialog-content>
      <p>{{ data.content }}</p>
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button type="button" [mat-dialog-close]="false">
        {{ data.cancelText || i18n.t('cancel') }}
      </button>
      <button mat-stroked-button type="button" [mat-dialog-close]="true" cdkFocusInitial>
        {{ data.confirmText || i18n.t('confirm') }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [],
})
export class ConfirmationDialogComponent {
  public readonly i18n = inject(I18nService);
  public readonly data = inject(MAT_DIALOG_DATA) as ConfirmationDialogData;
}
