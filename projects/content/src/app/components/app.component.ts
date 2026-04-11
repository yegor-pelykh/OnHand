import { CommonModule } from '@angular/common';
import { Component, OnDestroy, OnInit, WritableSignal, inject, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogModule, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatSnackBar, MatSnackBarModule } from '@angular/material/snack-bar';
import { MatTabsModule } from '@angular/material/tabs';
import { MatToolbarModule } from '@angular/material/toolbar';
import { firstValueFrom } from 'rxjs';

import { downloadFile } from '@shared/helpers/utils';
import { Group } from '@shared/models/group.model';
import { GroupStorage } from '@shared/models/group-storage';
import { I18nService } from '@shared/services/i18n.service';
import { StorageService } from '@shared/services/storage.service';

import {
  BookmarkEditorComponent,
  BookmarkEditorData,
  BookmarkEditorResult,
} from './bookmarks/bookmark-editor.component';
import { BookmarksViewComponent } from './bookmarks/bookmarks-view.component';
import { GroupsManagerComponent, GroupsManagerDialogData } from './groups/groups-manager.component';
import { ConfirmationDialogComponent, ConfirmationDialogData } from './shared/confirmation-dialog.component';
import { EmptyStateComponent } from './shared/empty-state.component';
import { FileUploaderComponent, FileUploaderDialogData } from './shared/file-uploader.component';

@Component({
  selector: 'app-content-root',
  standalone: true,
  imports: [
    CommonModule,
    MatButtonModule,
    MatDialogModule,
    MatIconModule,
    MatMenuModule,
    MatSnackBarModule,
    MatTabsModule,
    MatToolbarModule,
    BookmarksViewComponent,
    EmptyStateComponent,
  ],
  template: `
    @if (!storage.loaded()) {
      <div class="loading-state"></div>
    } @else {
      @let groupStorage = storage.groupStorage();
      @if (groupStorage && groupStorage.groups.length > 0) {
        <div class="main-container" animate.enter="view-enter-animation">
          <mat-tab-group
            [selectedIndex]="activeGroupIndex()"
            (selectedIndexChange)="onTabIndexChange($event)"
            [animationDuration]="'200ms'">
            @for (group of groupStorage.groups; track group.id) {
              <mat-tab [label]="group.title">
                <app-content-bookmarks-view
                  [groupId]="group.id"
                  (createBookmarkRequested)="createBookmark(group.id)"></app-content-bookmarks-view>
              </mat-tab>
            }
          </mat-tab-group>
        </div>
      } @else {
        <app-empty-state
          [icon]="'apps'"
          [title]="i18n.t('no_groups_title')"
          [subtitle]="i18n.t('no_groups_subtitle')"
          [buttonText]="i18n.t('group_management')"
          [buttonIcon]="'apps'"
          (buttonClick)="openGroupManagement()"></app-empty-state>
      }
    }
    <button
      matIconButton
      [matMenuTriggerFor]="aboveMenu"
      [attr.aria-label]="i18n.t('aria_label_actions_menu')"
      class="fab">
      <mat-icon>menu</mat-icon>
    </button>
    <mat-menu #aboveMenu="matMenu" yPosition="above">
      @if (storage.loaded() && storage.groupStorage().groups.length) {
        <button mat-menu-item (click)="createBookmark()">
          <mat-icon>add</mat-icon>
          <span>{{ i18n.t('create_bookmark') }}</span>
        </button>
      }
      <button mat-menu-item (click)="openGroupManagement()">
        <mat-icon>apps</mat-icon>
        <span>{{ i18n.t('group_management') }}</span>
      </button>
      @if (storage.loaded() && storage.groupStorage().groups.length) {
        <button mat-menu-item (click)="exportToFile()">
          <mat-icon>download</mat-icon>
          <span>{{ i18n.t('export_to_file') }}</span>
        </button>
      }
      <button mat-menu-item (click)="importFromFile()">
        <mat-icon>upload</mat-icon>
        <span>{{ i18n.t('import_from_file') }}</span>
      </button>
    </mat-menu>
  `,
  styles: [
    `
      :host {
        display: block;
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
      }
      .main-container {
        display: block;
        width: 100%;
        height: 100%;
        margin: 0;
        padding: 0;
      }
      .mat-mdc-tab-group {
        display: flex;
        flex-direction: column;
        height: 100%;
      }
      .mat-mdc-tab-group ::ng-deep .mat-mdc-tab-header {
        margin: 32px 60px 0px 60px;
      }
      .mat-mdc-tab-group ::ng-deep .mat-mdc-tab {
        transition:
          background-color 200ms ease-in-out,
          color 200ms ease-in-out;
      }
      .mat-mdc-tab-group ::ng-deep .mat-mdc-tab:hover {
        background-color: var(--mat-sys-surface-container-high);
      }
      .mat-tab-body-wrapper {
        flex-grow: 1;
        overflow-y: auto;
      }
      .fab {
        position: fixed;
        right: 24px;
        bottom: 24px;
        z-index: 1000;
      }
      .loading-state {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        width: 100%;
        height: 100%;
        text-align: center;
        padding: 24px;
        font: var(--mat-sys-body-large);
      }
      .view-enter-animation {
        animation: fade 400ms;
      }
      @keyframes fade {
        from {
          opacity: 0;
        }
        to {
          opacity: 1;
        }
      }
    `,
  ],
})
export class AppComponent implements OnInit, OnDestroy {
  public readonly i18n: I18nService = inject(I18nService);
  public readonly storage: StorageService = inject(StorageService);
  public readonly activeGroupIndex: WritableSignal<number> = signal<number>(0);
  private readonly _dialog: MatDialog = inject(MatDialog);
  private readonly _snackBar: MatSnackBar = inject(MatSnackBar);

  public ngOnInit(): void {
    document.addEventListener('mousedown', this._preventMiddleClickScroll);
    document.addEventListener('contextmenu', this._preventContextMenu);
  }

  public ngOnDestroy(): void {
    document.removeEventListener('mousedown', this._preventMiddleClickScroll);
    document.removeEventListener('contextmenu', this._preventContextMenu);
  }

  public onTabIndexChange(index: number): void {
    this.activeGroupIndex.set(index);
  }

  public async createBookmark(targetGroupId?: string): Promise<void> {
    const currentGroupStorage: GroupStorage = this.storage.groupStorage();
    if (currentGroupStorage.groups.length === 0) {
      this._snackBar.open(this.i18n.t('no_groups_for_bookmark'), this.i18n.t('ok'), {
        duration: 3000,
      });
      return;
    }

    let groupToCreateIn: Group | undefined;
    if (targetGroupId) {
      groupToCreateIn = currentGroupStorage.groupById(targetGroupId);
    } else {
      groupToCreateIn = currentGroupStorage.groupAt(this.activeGroupIndex());
    }

    if (!groupToCreateIn) {
      this._snackBar.open(this.i18n.t('no_groups_for_bookmark'), this.i18n.t('ok'), {
        duration: 3000,
      });
      return;
    }

    const dialogRef: MatDialogRef<BookmarkEditorComponent, BookmarkEditorResult | undefined> = this._dialog.open(
      BookmarkEditorComponent,
      {
        width: '95vw',
        maxWidth: '450px',
        data: {
          mode: 'create',
          groupTitles: this.storage.getGroupTitles(),
          selectedGroupTitle: groupToCreateIn.title,
        } as BookmarkEditorData,
      }
    );
    const result: BookmarkEditorResult | undefined = await firstValueFrom(dialogRef.afterClosed());
    if (result) {
      const targetGroup: Group | undefined = this.storage
        .groupStorage()
        .groups.find((g: Group) => g.title === result.groupTitle);
      if (targetGroup) {
        await this.storage.addBookmark(targetGroup.id, result.address, result.title, result.iconUrl);
        this._snackBar.open(this.i18n.t('bookmark_created'), this.i18n.t('ok'), {
          duration: 3000,
        });
        const newActiveGroupIndex: number = this.storage
          .groupStorage()
          .groups.findIndex((g: Group) => g.id === targetGroup.id);
        if (newActiveGroupIndex !== -1) {
          this.activeGroupIndex.set(newActiveGroupIndex);
        }
      }
    }
  }

  public async openGroupManagement(): Promise<void> {
    const currentGroups: readonly Group[] = this.storage.groupStorage().clone().groups;
    const dialogRef: MatDialogRef<GroupsManagerComponent, Group[] | undefined> = this._dialog.open(
      GroupsManagerComponent,
      {
        width: '95vw',
        maxWidth: '500px',
        data: { groups: currentGroups } as GroupsManagerDialogData,
      }
    );
    const resultGroups: Group[] | undefined = await firstValueFrom(dialogRef.afterClosed());
    if (resultGroups) {
      const newGroupStorage: GroupStorage = new GroupStorage(resultGroups);
      await this.storage.setStorage(newGroupStorage);
      this._snackBar.open(this.i18n.t('groups_saved'), this.i18n.t('ok'), { duration: 3000 });
      const currentActiveGroup: Group | undefined = this.storage.groupStorage().groupAt(this.activeGroupIndex());
      if (currentActiveGroup) {
        const newIndex: number = resultGroups.findIndex((g: Group) => g.id === currentActiveGroup.id);
        if (newIndex !== -1) {
          this.activeGroupIndex.set(newIndex);
        } else {
          this.activeGroupIndex.set(0);
        }
      } else {
        this.activeGroupIndex.set(0);
      }
    }
  }

  public async exportToFile(): Promise<void> {
    const dialogRef: MatDialogRef<ConfirmationDialogComponent, boolean | undefined> = this._dialog.open(
      ConfirmationDialogComponent,
      {
        data: {
          title: this.i18n.t('export_to_file_dlg_title'),
          content: this.i18n.t('export_to_file_dlg_content'),
          confirmText: this.i18n.t('save'),
          cancelText: this.i18n.t('cancel'),
        } as ConfirmationDialogData,
      }
    );
    const result: boolean | undefined = await firstValueFrom(dialogRef.afterClosed());
    if (result === true) {
      const jsonString: string = JSON.stringify(this.storage.groupStorage().toJson());
      downloadFile(jsonString, `bookmarks.onhand`, 'application/json');
      this._snackBar.open(this.i18n.t('data_exported'), this.i18n.t('ok'), { duration: 3000 });
    }
  }

  public async importFromFile(): Promise<void> {
    const dialogRef: MatDialogRef<FileUploaderComponent, void> = this._dialog.open(FileUploaderComponent, {
      width: '95vw',
      maxWidth: '450px',
      data: {
        title: this.i18n.t('import_from_file_dlg_title'),
      } as FileUploaderDialogData,
    });
    const fileContentObs = dialogRef.componentInstance?.fileContent;
    if (!fileContentObs) {
      await firstValueFrom(dialogRef.afterClosed());
      return;
    }
    const fileJson: string = await firstValueFrom(fileContentObs);
    const importSuccessful = await this.storage.importDataFromJson(fileJson);
    if (importSuccessful) {
      this.activeGroupIndex.set(0);
    }
  }

  private readonly _preventMiddleClickScroll = (event: MouseEvent): void => {
    if (event.button === 1) {
      event.preventDefault();
    }
  };

  private readonly _preventContextMenu = (event: MouseEvent): void => {
    const target = event.target as HTMLElement;
    if (target.closest('input, textarea, [contenteditable="true"]')) {
      return;
    }
    event.preventDefault();
  };
}
