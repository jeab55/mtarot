#!/usr/bin/env bash
set -e
npm install
npx cap add android
sdkmanager "platforms;android-36" "build-tools;36.0.0" >/dev/null || true
yes | sdkmanager --licenses || true
cd android
chmod +x gradlew
./gradlew assembleDebug --no-daemon
mv app/build/outputs/apk/debug/app-debug.apk ../mtarot.apk
