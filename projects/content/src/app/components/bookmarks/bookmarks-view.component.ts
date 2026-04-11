import { CommonModule } from '@angular/common';
import { CdkDragDrop, DragDropModule } from '@angular/cdk/drag-drop';
import { Component, EventEmitter, Output, computed, inject, input, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { Bookmark } from '@shared/models/bookmark.model';
import { Group } from '@shared/models/group.model';
import { I18nService } from '@shared/services/i18n.service';
import { StorageService } from '@shared/services/storage.service';
import { EmptyStateComponent } from '../shared/empty-state.component';
import { BookmarkTileComponent } from './bookmark-tile.component';

@Component({
  selector: 'app-content-bookmarks-view',
  standalone: true,
  imports: [CommonModule, BookmarkTileComponent, DragDropModule, MatIconModule, MatButtonModule, EmptyStateComponent],
  template: `
    <div class="bookmarks-container">
      @if (group() && group()!.bookmarks.length; as hasBookmarks) {
        <div
          class="bookmark-grid-layout"
          cdkDropListOrientation="mixed"
          cdkDropList
          [cdkDropListData]="group()!.bookmarks"
          (cdkDropListDropped)="drop($event)">
          @for (bookmark of group()!.bookmarks; track bookmark.id) {
            <div
              class="bookmark-item"
              cdkDrag
              [cdkDragData]="bookmark"
              (cdkDragStarted)="onDragStarted()"
              (cdkDragEnded)="onDragEnded()">
              <app-content-bookmark-tile
                class="bookmark-tile"
                [bookmarkId]="bookmark.id"
                [currentGroupId]="group()!.id"
                [isDraggingParent]="isAnyBookmarkBeingDragged()"></app-content-bookmark-tile>
              <app-content-bookmark-tile
                *cdkDragPlaceholder
                class="bookmark-placeholder"
                [bookmarkId]="bookmark.id"
                [currentGroupId]="group()!.id"
                [isDraggingParent]="isAnyBookmarkBeingDragged()"></app-content-bookmark-tile>
            </div>
          }
        </div>
      } @else {
        <app-empty-state
          [icon]="'bookmark'"
          [title]="i18n.t('group_no_bookmarks_title')"
          [subtitle]="i18n.t('group_no_bookmarks_subtitle')"
          [buttonText]="i18n.t('create_bookmark')"
          [buttonIcon]="'add_circle'"
          (buttonClick)="createBookmarkRequested.emit(this.groupId())"></app-empty-state>
      }
    </div>
  `,
  styles: [
    `
      $min-bookmark-base-width: 300px;
      $grid-gap: 16px;
      $container-padding-x: 88px;
      $calculated-min-viewport-5-cols: (5 * $min-bookmark-base-width) + (4 * $grid-gap) + (2 * $container-padding-x);
      $calculated-min-viewport-4-cols: (4 * $min-bookmark-base-width) + (3 * $grid-gap) + (2 * $container-padding-x);
      $calculated-min-viewport-3-cols: (3 * $min-bookmark-base-width) + (2 * $grid-gap) + (2 * $container-padding-x);
      $calculated-min-viewport-2-cols: (2 * $min-bookmark-base-width) + (1 * $grid-gap) + (2 * $container-padding-x);

      .bookmarks-container {
        padding: 48px #{$container-padding-x};
        display: flex;
        justify-content: center;
        overflow-y: auto;
      }
      .bookmark-grid-layout {
        display: grid;
        gap: #{$grid-gap};
        width: 100%;
        max-width: 100%;
        align-content: flex-start;
        grid-template-columns: repeat(5, 1fr);
        @media (max-width: #{$calculated-min-viewport-5-cols - 1px}) {
          grid-template-columns: repeat(4, 1fr);
        }
        @media (max-width: #{$calculated-min-viewport-4-cols - 1px}) {
          grid-template-columns: repeat(3, 1fr);
        }
        @media (max-width: #{$calculated-min-viewport-3-cols - 1px}) {
          grid-template-columns: repeat(2, 1fr);
        }
        @media (max-width: #{$calculated-min-viewport-2-cols - 1px}) {
          grid-template-columns: repeat(1, 1fr);
        }
      }
      .bookmark-item {
        display: flex;
        height: 56px;
        min-width: 0;
      }
      .bookmark-tile {
        width: 100%;
      }
      .bookmark-placeholder {
        width: 100%;
        opacity: 0.4;
      }
      .bookmark-placeholder ::ng-deep .card {
        box-shadow: none !important;
      }
      .cdk-drag-preview {
        box-sizing: border-box;
        border-radius: var(--mat-sys-corner-medium);
        box-shadow:
          0 5px 5px -3px rgba(0, 0, 0, 0.2),
          0 8px 10px 1px rgba(0, 0, 0, 0.14),
          0 3px 14px 2px rgba(0, 0, 0, 0.12);
        background: var(--mat-sys-surface);
      }
      .cdk-drag-animating {
        transition: transform 250ms cubic-bezier(0, 0, 0.2, 1);
      }
      .cdk-drop-list-dragging .cdk-drag:not(.cdk-drag-placeholder) {
        transition: transform 250ms cubic-bezier(0, 0, 0.2, 1);
      }
    `,
  ],
})
export class BookmarksViewComponent {
  @Output() public readonly createBookmarkRequested = new EventEmitter<string>();
  public readonly groupId = input.required<string>();
  public readonly i18n = inject(I18nService);
  public readonly isAnyBookmarkBeingDragged = signal<boolean>(false);
  public readonly group = computed<Group | undefined>(() =>
    this._storageService.groupStorage().groupById(this.groupId())
  );
  private readonly _storageService = inject(StorageService);

  public async drop(event: CdkDragDrop<Bookmark[]>): Promise<void> {
    const currentGroup: Group | undefined = this.group();
    if (!currentGroup) {
      return;
    }
    await this._storageService.moveBookmark(currentGroup.id, event.previousIndex, event.currentIndex);
  }

  public onDragStarted(): void {
    this.isAnyBookmarkBeingDragged.set(true);
  }

  public onDragEnded(): void {
    this.isAnyBookmarkBeingDragged.set(false);
  }
}
