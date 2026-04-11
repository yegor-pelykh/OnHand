import { CommonModule } from '@angular/common';
import { Component, EventEmitter, Input, Output } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';

@Component({
  selector: 'app-empty-state',
  standalone: true,
  imports: [CommonModule, MatIconModule, MatButtonModule],
  template: `
    <div class="empty-state-container">
      <mat-icon class="empty-state-icon">{{ icon }}</mat-icon>
      <div class="empty-state-title">{{ title }}</div>
      @if (subtitle) {
        <div class="empty-state-subtitle">{{ subtitle }}</div>
      }
      @if (buttonText) {
        <button mat-raised-button color="primary" (click)="buttonClick.emit()">
          <mat-icon>{{ buttonIcon }}</mat-icon>
          {{ buttonText }}
        </button>
      }
    </div>
  `,
  styles: [
    `
      .empty-state-container {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        width: 100%;
        height: 100%;
        text-align: center;
        padding: 24px;
        color: var(--mat-sys-on-surface-variant);
      }

      .empty-state-icon {
        font-size: 96px;
        height: 96px;
        width: 96px;
        margin-bottom: 24px;
        color: var(--mat-sys-outline);
      }

      .empty-state-title {
        font: var(--mat-sys-title-large);
        margin-bottom: 12px;
      }

      .empty-state-subtitle {
        font: var(--mat-sys-body-large);
        max-width: 400px;
        margin-bottom: 24px;
      }
    `,
  ],
})
export class EmptyStateComponent {
  @Input({ required: true }) public icon!: string;
  @Input({ required: true }) public title!: string;
  @Input() public subtitle?: string;
  @Input() public buttonText?: string;
  @Input() public buttonIcon?: string;
  @Output() public readonly buttonClick = new EventEmitter<void>();
}
