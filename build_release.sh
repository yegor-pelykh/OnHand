#!/bin/bash
npm install
npm run build
flutter clean
flutter pub get
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp
npm run pack