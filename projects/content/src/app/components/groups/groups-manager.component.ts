import { CommonModule } from '@angular/common';
import { CdkDragDrop, DragDropModule, moveItemInArray } from '@angular/cdk/drag-drop';
import { Component, OnInit, computed, inject, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MAT_DIALOG_DATA, MatDialog, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { firstValueFrom } from 'rxjs';
import { Group } from '@shared/models/group.model';
import { I18nService } from '@shared/services/i18n.service';
import { CardComponent } from '../shared/card.component';
import { ConfirmationDialogComponent, ConfirmationDialogData } from '../shared/confirmation-dialog.component';
import { GroupEditorComponent, GroupEditorDialogData } from './group-editor.component';

export interface GroupsManagerDialogData {
  readonly groups: readonly Group[];
}

@Component({
  selector: 'app-content-groups-manager',
  standalone: true,
  imports: [
    CommonModule,
    CardComponent,
    DragDropModule,
    MatButtonModule,
    MatDialogModule,
    MatIconModule,
    MatMenuModule,
  ],
  template: `
    <h2 mat-dialog-title>{{ i18n.t('group_management') }}</h2>
    <mat-dialog-content>
      <div class="groups-manager-header">
        <button mat-raised-button color="primary" (click)="createGroup()">
          <mat-icon>add_circle</mat-icon>
          {{ i18n.t('new_group_label') }}
        </button>
      </div>
      <div class="groups-list-wrapper" cdkDropList tabindex="-1" (cdkDropListDropped)="drop($event)">
        @for (group of groups(); track group.id) {
          <app-content-card
            class="group-card"
            [title]="group.title"
            [subtitle]="i18n.p('bookmark_count', { count: group.bookmarks.length })"
            cdkDrag
            tabindex="-1"
            (mouseenter)="onMouseEnter(group.id)"
            (mouseleave)="onMouseLeave(group.id)"
            [hasTrailingContent]="shouldShowActions(group.id)">
            <div leading cdkDragHandle class="drag-handle">
              <mat-icon>drag_indicator</mat-icon>
            </div>
            <div trailing>
              <button
                mat-icon-button
                [matMenuTriggerFor]="groupMenu"
                [attr.aria-label]="i18n.t('aria_label_group_actions_menu')"
                (click)="$event.stopPropagation()"
                (menuOpened)="onMenuOpened(group.id)"
                (menuClosed)="onMenuClosed(group.id)"
                (focus)="onFocus(group.id)"
                (blur)="onBlur(group.id)"
                tabindex="0"
                class="action-button"
                [class.visible]="shouldShowActions(group.id)">
                <mat-icon>more_vert</mat-icon>
              </button>
              <mat-menu #groupMenu="matMenu" yPosition="below" xPosition="before">
                <button mat-menu-item (click)="editGroup(group)">
                  <mat-icon>edit</mat-icon>
                  <span>{{ i18n.t('edit') }}</span>
                </button>
                <button mat-menu-item (click)="deleteGroup(group.id)" class="delete-button">
                  <mat-icon>delete</mat-icon>
                  <span>{{ i18n.t('delete') }}</span>
                </button>
              </mat-menu>
            </div>
          </app-content-card>
        } @empty {
          <div class="empty-state-message">
            <div>{{ i18n.t('hint_no_groups_title') }}</div>
            <div>{{ i18n.t('hint_no_groups_subtitle') }}</div>
          </div>
        }
      </div>
    </mat-dialog-content>
    <mat-dialog-actions>
      <button mat-button (click)="cancel()">{{ i18n.t('cancel_changes') }}</button>
      <button mat-stroked-button color="primary" (click)="save()" [disabled]="!hasChanges()">
        {{ i18n.t('save') }}
      </button>
    </mat-dialog-actions>
  `,
  styles: [
    `
      :host ::ng-deep .mat-mdc-dialog-content {
        display: flex;
        flex-direction: column;
        padding: 0 24px;
        overflow: hidden;
        flex-grow: 1;
        min-height: 0;
      }
      .groups-manager-header {
        display: flex;
        justify-content: flex-end;
        margin-bottom: 8px;
        padding-top: 16px;
        flex-shrink: 0;
      }
      .groups-list-wrapper {
        display: flex;
        flex-direction: column;
        flex-grow: 1;
        overflow-y: auto;
        padding: 8px;
      }
      .group-card {
        margin-bottom: 8px;
      }
      .drag-handle {
        opacity: 0.5;
        transition: opacity 0.2s ease-in-out;
        cursor: grab;
      }
      .drag-handle:hover {
        opacity: 1;
      }
      .cdk-drag-preview {
        cursor: grabbing;
        pointer-events: auto !important;
      }
      .empty-state-message {
        height: 68px;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        text-align: center;
        color: var(--mat-sys-on-surface-variant);
        font: var(--mat-sys-body-small);
        padding: 0 8px;
      }
      .cdk-drag-placeholder {
        opacity: 0.4;
      }
      .cdk-drag-placeholder ::ng-deep .card {
        box-shadow: none !important;
      }
      .cdk-drag-animating {
        transition: transform 250ms cubic-bezier(0, 0, 0.2, 1);
      }
      .cdk-drop-list-dragging .cdk-drag:not(.cdk-drag-placeholder) {
        transition: transform 250ms cubic-bezier(0, 0, 0.2, 1);
      }
      .delete-button,
      .delete-button mat-icon {
        color: var(--mat-sys-error);
      }
      .action-button {
        opacity: 0;
        transition: opacity 0.2s ease-in-out;
        pointer-events: none;
      }

      .action-button.visible {
        opacity: 1;
        pointer-events: auto;
      }
    `,
  ],
})
export class GroupsManagerComponent implements OnInit {
  public readonly i18n = inject(I18nService);
  public readonly data = inject(MAT_DIALOG_DATA) as GroupsManagerDialogData;
  public readonly groups = signal<Group[]>([]);
  public readonly hoveredStates = signal<Set<string>>(new Set());
  public readonly menuOpenStates = signal<Set<string>>(new Set());
  public readonly focusedStates = signal<Set<string>>(new Set());
  public readonly hasChanges = computed<boolean>(
    () => JSON.stringify(this.groups().map((g: Group) => g.toJson())) !== this._initialGroupsJson
  );
  private readonly _dialog = inject(MatDialog);
  private readonly _dialogRef = inject(MatDialogRef) as MatDialogRef<GroupsManagerComponent, Group[] | undefined>;
  private _initialGroupsJson: string;

  constructor() {
    this._initialGroupsJson = JSON.stringify(this.data.groups.map((group: Group) => group.toJson()));
  }

  public ngOnInit(): void {
    this.groups.set(this.data.groups.map((group: Group) => group.clone()));
    this._initialGroupsJson = JSON.stringify(this.groups().map((g: Group) => g.toJson()));
  }

  public shouldShowActions(groupId: string): boolean {
    return this.hoveredStates().has(groupId) || this.menuOpenStates().has(groupId) || this.focusedStates().has(groupId);
  }

  public onMouseEnter(groupId: string): void {
    this.hoveredStates.update((set: Set<string>) => {
      set.add(groupId);
      return new Set(set);
    });
  }

  public onMouseLeave(groupId: string): void {
    this.hoveredStates.update((set: Set<string>) => {
      set.delete(groupId);
      return new Set(set);
    });
  }

  public onMenuOpened(groupId: string): void {
    this.menuOpenStates.update((set: Set<string>) => {
      set.add(groupId);
      return new Set(set);
    });
  }

  public onMenuClosed(groupId: string): void {
    this.menuOpenStates.update((set: Set<string>) => {
      set.delete(groupId);
      return new Set(set);
    });
  }

  public onFocus(groupId: string): void {
    this.focusedStates.update((set: Set<string>) => {
      set.add(groupId);
      return new Set(set);
    });
  }

  public onBlur(groupId: string): void {
    setTimeout((): void => {
      this.focusedStates.update((set: Set<string>) => {
        if (!this.menuOpenStates().has(groupId)) {
          set.delete(groupId);
        }
        return new Set(set);
      });
    }, 0);
  }

  public async createGroup(): Promise<void> {
    const forbiddenNames: string[] = this.groups().map((group: Group) => group.title);
    const dialogRef: MatDialogRef<GroupEditorComponent, string | undefined> = this._dialog.open(GroupEditorComponent, {
      width: '95vw',
      maxWidth: '450px',
      data: {
        mode: 'create',
        initialTitle: '',
        forbiddenNames: forbiddenNames,
      } as GroupEditorDialogData,
    });
    const resultTitle: string | undefined = await firstValueFrom(dialogRef.afterClosed());
    if (resultTitle && resultTitle.length > 0) {
      this.groups.update((currentGroups: Group[]) => [...currentGroups, new Group(resultTitle)]);
    }
  }

  public async editGroup(groupToEdit: Group): Promise<void> {
    const forbiddenNames: string[] = this.groups()
      .filter((group: Group) => group.id !== groupToEdit.id)
      .map((group: Group) => group.title);
    const dialogRef: MatDialogRef<GroupEditorComponent, string | undefined> = this._dialog.open(GroupEditorComponent, {
      width: '95vw',
      maxWidth: '450px',
      data: {
        mode: 'edit',
        initialTitle: groupToEdit.title,
        forbiddenNames: forbiddenNames,
      } as GroupEditorDialogData,
    });
    const resultTitle: string | undefined = await firstValueFrom(dialogRef.afterClosed());
    if (resultTitle && resultTitle.length > 0) {
      this.groups.update((currentGroups: Group[]) =>
        currentGroups.map((group: Group) =>
          group.id === groupToEdit.id ? new Group(resultTitle, group.bookmarks, group.id) : group
        )
      );
    }
  }

  public async deleteGroup(groupIdToDelete: string): Promise<void> {
    const groupToDelete: Group | undefined = this.groups().find((group: Group) => group.id === groupIdToDelete);
    if (!groupToDelete) {
      return;
    }
    const bookmarkCount: number = groupToDelete.bookmarks.length;
    const contentMessage =
      bookmarkCount > 0
        ? this.i18n.p('group_deleting_dlg_content_with_bookmarks', {
            groupTitle: groupToDelete.title,
            count: bookmarkCount,
          })
        : this.i18n.t('group_deleting_dlg_content_empty_group', {
            groupTitle: groupToDelete.title,
          });
    const confirmationDialogRef: MatDialogRef<ConfirmationDialogComponent, boolean | undefined> = this._dialog.open(
      ConfirmationDialogComponent,
      {
        data: {
          title: this.i18n.t('group_deleting_dlg_title'),
          content: contentMessage,
          confirmText: this.i18n.t('yes'),
          cancelText: this.i18n.t('no'),
        } as ConfirmationDialogData,
      }
    );
    const confirmed: boolean | undefined = await firstValueFrom(confirmationDialogRef.afterClosed());
    if (confirmed === true) {
      this.groups.update((currentGroups: Group[]) =>
        currentGroups.filter((group: Group) => group.id !== groupIdToDelete)
      );
    }
  }

  public drop(event: CdkDragDrop<Group[]>): void {
    this.groups.update((currentGroups: Group[]) => {
      const updatedGroups: Group[] = [...currentGroups];
      moveItemInArray(updatedGroups, event.previousIndex, event.currentIndex);
      return updatedGroups;
    });
  }

  public cancel(): void {
    this._dialogRef.close(undefined);
  }

  public save(): void {
    this._dialogRef.close(this.groups().map((group: Group) => group.clone()));
  }
}
