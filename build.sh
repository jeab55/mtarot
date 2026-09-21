#!/usr/bin/env bash
set -e
exec > >(tee build.log) 2>&1
npm install
npx cap add android
python3 - <<'PY'
p = 'android/app/src/main/AndroidManifest.xml'
s = open(p, encoding='utf-8').read()
if 'mtarot' not in s:
    filt = ('<intent-filter><action android:name="android.intent.action.VIEW"/>'
            '<category android:name="android.intent.category.DEFAULT"/>'
            '<category android:name="android.intent.category.BROWSABLE"/>'
            '<data android:scheme="mtarot"/></intent-filter>')
    s = s.replace('</intent-filter>', '</intent-filter>' + filt, 1)
    open(p, 'w', encoding='utf-8').write(s)
    print('manifest patched with mtarot scheme')
else:
    print('manifest already has mtarot')
PY
sdkmanager "platforms;android-36" "build-tools;36.0.0" >/dev/null || true
yes | sdkmanager --licenses || true
cd android
chmod +x gradlew
./gradlew assembleDebug --no-daemon
BT="$ANDROID_SDK_ROOT/build-tools/36.0.0"
if [ ! -f "$BT/apksigner" ]; then
  BT="$(dirname "$(dirname "$(find "$ANDROID_SDK_ROOT/build-tools" -maxdepth 2 -name apksigner | head -1)")")"
fi
echo "build-tools: $BT"
echo "$B55_KEYSTORE" | base64 -d > /tmp/ks.p12
"$BT/zipalign" -f -p 4 app/build/outputs/apk/debug/app-debug.apk /tmp/aligned.apk
"$BT/apksigner" sign --ks /tmp/ks.p12 --ks-type PKCS12 \
  --ks-pass "pass:$B55_KS_PASS" --key-pass "pass:$B55_KS_PASS" \
  --out ../mtarot.apk /tmp/aligned.apk
"$BT/apksigner" verify --print-certs ../mtarot.apk | head -3
