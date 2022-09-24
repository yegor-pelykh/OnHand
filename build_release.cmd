call npm install
call npm run sw-build-release
call npm run popup-build-release
call flutter clean
call flutter pub get
call flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp
call npm run pack