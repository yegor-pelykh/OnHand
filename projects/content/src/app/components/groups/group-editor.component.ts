import { CommonModule } from '@angular/common';
import { Component, OnInit, inject } from '@angular/core';
import { AbstractControl, FormControl, FormGroup, ReactiveFormsModule, ValidatorFn, Validators } from '@angular/forms';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatFormFieldModule } from '@angular/material/form-field';
import { MatInputModule } from '@angular/material/input';
import { I18nService } from '@shared/services/i18n.service';

export interface GroupEditorDialogData {
  readonly mode: 'create' | 'edit';
  readonly initialTitle: string;
  readonly forbiddenNames: readonly string[];
}

type GroupForm = FormGroup<{ title: FormControl<string> }>;

@Component({
  selector: 'app-content-group-editor',
  standalone: true,
  imports: [CommonModule, MatButtonModule, MatDialogModule, MatFormFieldModule, MatInputModule, ReactiveFormsModule],
  template: `
    <h2 mat-dialog-title>
      @if (data.mode === 'create') {
        {{ i18n.t('group_creating_dlg_title') }}
      } @else {
        {{ i18n.t('group_editing_dlg_title') }}
      }
    </h2>
    <mat-dialog-content>
      <form [formGroup]="groupForm" class="form" (ngSubmit)="submit()">
        <mat-form-field class="title-field">
          <mat-label>{{ i18n.t('group_title_label') }}</mat-label>
          <input matInput formControlName="title" required />
          @if (groupForm.controls.title.hasError('required') && groupForm.controls.title.touched) {
            <mat-error>{{ i18n.t('group_title_empty_hint') }}</mat-error>
          }
          @if (groupForm.controls.title.hasError('duplicate') && groupForm.controls.title.touched) {
            <mat-error>{{ i18n.t('group_title_already_used_hint') }}</mat-error>
          }
        </mat-form-field>
      </form>
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button type="button" (click)="cancel()">
        {{ i18n.t('cancel') }}
      </button>
      <button mat-stroked-button (click)="submit()" [disabled]="groupForm.invalid">
        @if (data.mode === 'create') {
          {{ i18n.t('create') }}
        } @else {
          {{ i18n.t('apply') }}
        }
      </button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      .form {
        min-width: 400px;
        margin: 16px 0;
      }
      .title-field {
        width: 100%;
      }
    `,
  ],
})
export class GroupEditorComponent implements OnInit {
  public readonly i18n = inject(I18nService);
  public readonly data: GroupEditorDialogData = inject(MAT_DIALOG_DATA) as GroupEditorDialogData;
  public readonly groupForm: GroupForm;
  private readonly _dialogRef = inject(MatDialogRef) as MatDialogRef<GroupEditorComponent, string | undefined>;
  private _forbiddenNames: string[] = [];

  constructor() {
    this.groupForm = new FormGroup({
      title: new FormControl(this.data.initialTitle, {
        nonNullable: true,
        validators: [Validators.required, this._duplicateTitleValidator.bind(this)],
      }),
    }) as GroupForm;
  }

  public ngOnInit(): void {
    this._forbiddenNames = this.data.forbiddenNames.map((name: string) => name.toLowerCase());
  }

  public submit(): void {
    this.groupForm.markAllAsTouched();
    if (this.groupForm.valid) {
      this._dialogRef.close(this.groupForm.value.title);
    }
  }

  public cancel(): void {
    this._dialogRef.close(undefined);
  }

  private _duplicateTitleValidator: ValidatorFn = (control: AbstractControl): Record<string, boolean> | null => {
    const titleControl = control as FormControl<string>;
    if (!titleControl.value || titleControl.value.trim().length === 0) {
      return null;
    }
    const currentValue: string = titleControl.value.toLowerCase();
    const initialTitleLower: string = this.data.initialTitle.toLowerCase();
    if (this.data.mode === 'edit' && currentValue === initialTitleLower) {
      return null;
    }
    if (this._forbiddenNames.includes(currentValue)) {
      return { duplicate: true };
    }
    return null;
  };
}
