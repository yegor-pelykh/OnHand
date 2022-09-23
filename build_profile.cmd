call npm install
call npm run sw-build
call flutter clean
call flutter pub get
call flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp --profile --dart-define=Dart2jsOptimization=O0
call npm run pack