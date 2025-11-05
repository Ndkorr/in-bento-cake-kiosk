@echo off
flutter clean
flutter pub get
flutter build apk --release
flutter build ipa
copy build\app\outputs\flutter-apk\app-release.apk build\app\outputs\flutter-apk\inbento-kiosk-v1.0.0.apk
echo APK built and renamed to: build\app\outputs\flutter-apk\inbento-kiosk-v1.0.0.apk
pause
copy build\app\outputs\flutter-ios\ipa\Runner.ipa build\app\outputs\flutter-ios\inbento-kiosk-v1.0.0.ipa
echo IPA built and renamed to: build\app\outputs\flutter-ios\inbento-kiosk-v1.0.0.ipa
pause