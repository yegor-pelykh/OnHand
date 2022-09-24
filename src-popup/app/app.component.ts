import { Component, OnDestroy, OnInit } from '@angular/core';
import { CommunicationService } from './communication.service';

@Component({
  selector: 'popup-root',
  template:
  `
  <mat-form-field>
    <mat-label>Address</mat-label>
    <input matInput>
  </mat-form-field>
  <mat-form-field>
    <mat-label>Title</mat-label>
    <input matInput>
  </mat-form-field>
  <mat-form-field>
    <mat-label>Group</mat-label>
    <input matInput>
  </mat-form-field>
  `,
  styles: [ `` ]
})
export class AppComponent implements OnInit, OnDestroy {
  groups?: string[];

  constructor(
    private communication: CommunicationService,
  ) { }

  ngOnInit(): void {
    this.communication.connect();
    this.getData();
  }

  ngOnDestroy(): void {
    this.communication.disconnect();
  }

  async getData() {
    const response = await this.communication.sendMessage('get-data', null);
    this.groups = Array.isArray(response) ? response : undefined;
  }
}
