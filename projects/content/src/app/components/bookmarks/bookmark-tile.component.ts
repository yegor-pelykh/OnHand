import { CommonModule } from '@angular/common';
import { Component, computed, inject, input, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatDialog, MatDialogRef } from '@angular/material/dialog';
import { MatIconModule } from '@angular/material/icon';
import { MatMenuModule } from '@angular/material/menu';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { firstValueFrom } from 'rxjs';
import { getUriString } from '@shared/helpers/utils';
import { Bookmark } from '@shared/models/bookmark.model';
import { Group } from '@shared/models/group.model';
import { I18nService } from '@shared/services/i18n.service';
import { MetadataService } from '@shared/services/metadata.service';
import { StorageService } from '@shared/services/storage.service';
import { ChromeService } from '../../services/chrome.service';
import { BookmarkEditorComponent, BookmarkEditorData, BookmarkEditorResult } from './bookmark-editor.component';
import { CardComponent } from '../shared/card.component';
import { ConfirmationDialogComponent, ConfirmationDialogData } from '../shared/confirmation-dialog.component';

@Component({
  selector: 'app-content-bookmark-tile',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule, MatMenuModule, CardComponent, MatProgressSpinnerModule],
  template: `
    @if (bookmark() && currentGroup()) {
      <app-content-card
        class="bookmark-card"
        [title]="bookmark()!.title"
        [subtitle]="getUriString(bookmark()!.url)"
        (click)="launchUrl($event)"
        (auxclick)="launchUrl($event)"
        (mouseenter)="onMouseEnter()"
        (mouseleave)="onMouseLeave()"
        (focusin)="onFocusIn()"
        (focusout)="onFocusOut()"
        [hasTrailingContent]="showActions()">
        <div leading>
          @if (isRefreshingIcon()) {
            <mat-progress-spinner mode="indeterminate" diameter="24" strokeWidth="2"></mat-progress-spinner>
          } @else if (bookmark()!.iconUrl) {
            <img [src]="bookmark()!.iconUrl" alt="icon" width="24" height="24" />
          } @else {
            <mat-icon color="primary">link</mat-icon>
          }
        </div>
        <div trailing>
          <button
            mat-icon-button
            [matMenuTriggerFor]="bookmarkMenu"
            [attr.aria-label]="i18n.t('aria_label_bookmark_actions_menu')"
            (click)="$event.stopPropagation()"
            (menuOpened)="onMenuOpened()"
            (menuClosed)="onMenuClosed()"
            class="action-button"
            [class.visible]="showActions()">
            <mat-icon>more_vert</mat-icon>
          </button>
          <mat-menu #bookmarkMenu="matMenu" yPosition="below" xPosition="before">
            <button mat-menu-item (click)="editBookmark()">
              <mat-icon>edit</mat-icon>
              <span>{{ i18n.t('edit') }}</span>
            </button>
            <button mat-menu-item (click)="refreshBookmarkIcon()">
              <mat-icon>refresh</mat-icon>
              <span>{{ i18n.t('refresh_bookmark_icon') }}</span>
            </button>
            <button mat-menu-item (click)="deleteBookmark()" class="delete-button">
              <mat-icon>delete</mat-icon>
              <span>{{ i18n.t('delete') }}</span>
            </button>
          </mat-menu>
        </div>
      </app-content-card>
    }
  `,
  styles: [
    `
      .bookmark-card {
      }
      .bookmark-card ::ng-deep .card {
        cursor: pointer;
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
export class BookmarkTileComponent {
  public readonly getUriString = getUriString;
  public readonly isRefreshingIcon = signal<boolean>(false);
  public readonly hovered = signal<boolean>(false);
  public readonly menuOpen = signal<boolean>(false);
  public readonly focused = signal<boolean>(false);
  public readonly bookmark = computed<Bookmark | undefined>(() => {
    const group = this._storageService.groupStorage().groupById(this.currentGroupId());
    return group?.bookmarks.find((b: Bookmark) => b.id === this.bookmarkId());
  });
  public readonly currentGroup = computed<Group | undefined>(() =>
    this._storageService.groupStorage().groupById(this.currentGroupId())
  );
  public readonly showActions = computed<boolean>(() => this.hovered() || this.menuOpen() || this.focused());
  public readonly bookmarkId = input.required<string>();
  public readonly currentGroupId = input.required<string>();
  public readonly isDraggingParent = input<boolean>(false);
  public readonly i18n = inject(I18nService);
  private readonly _chromeService = inject(ChromeService);
  private readonly _dialog = inject(MatDialog);
  private readonly _storageService = inject(StorageService);
  private readonly _metadataService = inject(MetadataService);

  public onMouseEnter(): void {
    this.hovered.set(true);
  }

  public onMouseLeave(): void {
    this.hovered.set(false);
  }

  public onMenuOpened(): void {
    this.menuOpen.set(true);
  }

  public onMenuClosed(): void {
    this.menuOpen.set(false);
  }

  public onFocusIn(): void {
    this.focused.set(true);
  }

  public onFocusOut(): void {
    setTimeout((): void => {
      if (!this.menuOpen()) {
        this.focused.set(false);
      }
    }, 0);
  }

  public async launchUrl(event: MouseEvent): Promise<void> {
    if (this.isDraggingParent()) {
      event.stopPropagation();
      event.preventDefault();
      return;
    }
    if (event.button === 2) {
      event.stopPropagation();
      event.preventDefault();
      return;
    }
    const bookmark: Bookmark | undefined = this.bookmark();
    if (!bookmark) {
      event.stopPropagation();
      return;
    }
    const openInNewTab: boolean = event.ctrlKey || event.metaKey || event.button === 1;
    await this._chromeService.launch(bookmark.url, openInNewTab);
    event.stopPropagation();
  }

  public async editBookmark(): Promise<void> {
    const bookmark: Bookmark | undefined = this.bookmark();
    const group: Group | undefined = this.currentGroup();
    if (!bookmark || !group) {
      return;
    }
    const originalGroupId: string = group.id;
    const originalBookmarkId: string = bookmark.id;
    const dialogRef: MatDialogRef<BookmarkEditorComponent, BookmarkEditorResult | undefined> = this._dialog.open(
      BookmarkEditorComponent,
      {
        width: '95vw',
        maxWidth: '450px',
        data: {
          mode: 'edit',
          groupTitles: this._storageService.getGroupTitles(),
          selectedGroupTitle: group.title,
          initialAddress: bookmark.url,
          initialTitle: bookmark.title,
          initialIconUrl: bookmark.iconUrl,
        } as BookmarkEditorData,
      }
    );
    const result: BookmarkEditorResult | undefined = await firstValueFrom(dialogRef.afterClosed());
    if (result) {
      const targetGroup: Group | undefined = this._storageService
        .groupStorage()
        .groups.find((g: Group) => g.title === result.groupTitle);
      if (!targetGroup) {
        return;
      }
      if (targetGroup.id === originalGroupId) {
        await this._storageService.updateBookmark(
          targetGroup.id,
          originalBookmarkId,
          result.address,
          result.title,
          result.iconUrl
        );
      } else {
        await this._storageService.moveBookmarkToGroup(originalBookmarkId, originalGroupId, targetGroup.id);
        await this._storageService.updateBookmark(
          targetGroup.id,
          originalBookmarkId,
          result.address,
          result.title,
          result.iconUrl
        );
      }
    }
  }

  public async refreshBookmarkIcon(): Promise<void> {
    const bookmark: Bookmark | undefined = this.bookmark();
    const group: Group | undefined = this.currentGroup();
    if (!bookmark || !group) {
      return;
    }
    this.isRefreshingIcon.set(true);
    try {
      const metadata = await this._metadataService.getMetadata(bookmark.url);
      const newIconUrl: string | undefined = metadata?.icon?.url;
      await this._storageService.updateBookmark(group.id, bookmark.id, bookmark.url, bookmark.title, newIconUrl);
    } finally {
      this.isRefreshingIcon.set(false);
    }
  }

  public async deleteBookmark(): Promise<void> {
    const bookmark: Bookmark | undefined = this.bookmark();
    const group: Group | undefined = this.currentGroup();
    if (!bookmark || !group) {
      return;
    }
    const result: boolean | undefined = await firstValueFrom(
      this._dialog
        .open<ConfirmationDialogComponent, ConfirmationDialogData, boolean | undefined>(ConfirmationDialogComponent, {
          data: {
            title: this.i18n.t('bookmark_deleting_dlg_title'),
            content: this.i18n.t('bookmark_deleting_dlg_content'),
            confirmText: this.i18n.t('yes'),
            cancelText: this.i18n.t('no'),
          } as ConfirmationDialogData,
        })
        .afterClosed()
    );
    if (result === true) {
      await this._storageService.removeBookmark(group.id, bookmark.id);
    }
  }
}
