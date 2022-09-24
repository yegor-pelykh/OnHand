call npm run sw-build
call npm run popup-build
call flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp --profile --dart-define=Dart2jsOptimization=O0