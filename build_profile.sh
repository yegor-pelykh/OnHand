#!/bin/bash
npm install
npm run sw-build
flutter clean
flutter pub get
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp --profile --dart-define=Dart2jsOptimization=O0
npm run pack