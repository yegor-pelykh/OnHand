flutter clean && flutter pub get && flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --csp && npm install && node post-harmonization.js && node post-packaging.js