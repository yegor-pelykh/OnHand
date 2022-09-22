#!/bin/bash
npx tsc -p web_ts
flutter clean
flutter pub get
flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp --profile --dart-define=Dart2jsOptimization=O0
npm install
node build_post_pkg.js