# Firebase + Google Sign-In (Android)

## 1. Firebase Console

1. Open [Firebase Console](https://console.firebase.google.com/) and create/select your project.
2. Add an **Android app** with package name:
   ```
   com.ssm.skipq.ssm_skipq
   ```
3. Download **`google-services.json`** and place it here:
   ```
   android/app/google-services.json
   ```
4. Enable **Authentication → Sign-in method → Google**.

## 2. FlutterFire config

From the `ssm-skipq-flutter` folder:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```

This generates `lib/firebase_options.dart` with your real keys.

## 3. SHA-1 fingerprint (required for Google Sign-In)

```bash
cd android
./gradlew signingReport
```

Copy the **SHA-1** under `Variant: debug` and add it in:
**Firebase Console → Project settings → Your Android app → Add fingerprint**

## 4. Run the app

```bash
flutter pub get
flutter run
```

You do **not** need `--dart-define=GOOGLE_SERVER_CLIENT_ID` on Android when `google-services.json` is present.

## 5. Backend (Render)

In Firebase Console → Project settings → Service accounts → **Generate new private key**.

Add to backend `.env` (or Render env vars):

```
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...full json...}
```

Redeploy the backend so `/auth/google` can verify Firebase ID tokens.

## Troubleshooting

| Error | Fix |
|-------|-----|
| `serverClientId must be provided` | Add `google-services.json` with a Web OAuth client (`client_type: 3`) |
| `Firebase is not configured` | Run `flutterfire configure` |
| `Google Sign-In is not configured on server` | Add `FIREBASE_SERVICE_ACCOUNT_JSON` to backend |
| Sign-in works on debug but not release | Add **release** SHA-1 to Firebase too |
