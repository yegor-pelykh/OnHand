call npx tsc -p web_ts
call flutter clean
call flutter pub get
call flutter build web --web-renderer canvaskit --dart-define=FLUTTER_WEB_CANVASKIT_URL=/canvaskit/ --pwa-strategy=none --csp
call npm install
call node build_post_pkg.js