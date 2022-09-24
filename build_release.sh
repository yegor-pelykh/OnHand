#!/bin/bash
npm install
npm run sw-build-release
npm run popup-build-release
flutter clean
flutter pub get
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp
npm run pack