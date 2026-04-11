import { bootstrapApplication } from '@angular/platform-browser';
import { appConfig } from './app/app.config';
import { AppComponent } from './app/components/app.component';

// eslint-disable-next-line no-console
bootstrapApplication(AppComponent, appConfig).catch(err => console.error(err));
