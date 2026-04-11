import { CommonModule } from '@angular/common';
import { Component, Input } from '@angular/core';
import { MatCardModule } from '@angular/material/card';

@Component({
  selector: 'app-content-card',
  standalone: true,
  imports: [CommonModule, MatCardModule],
  template: `
    <mat-card class="card">
      <div class="leading-area">
        <ng-content select="[leading]"></ng-content>
      </div>
      <div class="text-content-area">
        <div class="title">{{ title }}</div>
        @if (subtitle) {
          <div class="subtitle">{{ subtitle }}</div>
        }
      </div>
      <div class="trailing-area" [class.has-content]="hasTrailingContent">
        <ng-content select="[trailing]"></ng-content>
      </div>
    </mat-card>
  `,
  styles: [
    `
      .card {
        display: flex;
        flex-direction: row;
        align-items: stretch;
        padding: 8px 16px;
        background-color: var(--mat-sys-surface-container-high);
        border-color: var(--mat-sys-surface-container-high);
        box-shadow: var(--mat-sys-level2);
        color: var(--mat-sys-on-surface);
        transition:
          background-color 0.2s ease-in-out,
          box-shadow 0.2s ease-in-out,
          transform 0.2s ease-in-out;
      }
      .card:hover {
        background-color: var(--mat-sys-surface-container-highest);
        box-shadow: var(--mat-sys-level4);
        transform: translateY(-2px);
      }
      .leading-area,
      .trailing-area {
        flex: 0 0 auto;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        & ::ng-deep > * {
          display: flex;
        }
      }
      .leading-area:not(:empty) {
        margin-right: 16px;
      }
      .trailing-area {
        width: 0;
        overflow: hidden;
        margin-left: 0;
        opacity: 0;
        transition:
          width 0.2s ease-in-out,
          margin-left 0.2s ease-in-out,
          opacity 0.2s ease-in-out;
        pointer-events: none;
      }
      .trailing-area.has-content {
        width: 48px;
        margin-left: 16px;
        opacity: 1;
        pointer-events: auto;
      }
      .text-content-area {
        flex-grow: 1;
        display: flex;
        flex-direction: column;
        justify-content: center;
        overflow: hidden;
        transition: flex-grow 0.2s ease-in-out;
      }
      .title {
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        font: var(--mat-sys-title-small);
        letter-spacing: var(--mat-sys-title-small-tracking);
      }
      .subtitle {
        opacity: 0.7;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        margin-top: 4px;
        font: var(--mat-sys-body-small);
        letter-spacing: var(--mat-sys-body-small-tracking);
      }
    `,
  ],
})
export class CardComponent {
  @Input({ required: true }) public title!: string;
  @Input() public subtitle?: string;
  @Input() public hasTrailingContent = false;
}
