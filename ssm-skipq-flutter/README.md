
# SSM SkipQ — Flutter App

> **New to Flutter? Open [START_HERE.md](./START_HERE.md) and follow it step by step.**

Native **Android + iOS** client for SSM SkipQ. Uses the **existing Express + MongoDB backend** — no backend changes required.

**Quick run (emulator already open):** double-click **`run_app.bat`** in this folder.

**Full walkthrough:** [START_HERE.md](./START_HERE.md) · [FLUTTER_SIMPLE.md](./FLUTTER_SIMPLE.md) · [FLUTTER_SETUP_AND_APK.md](./FLUTTER_SETUP_AND_APK.md)

## Build without installing Flutter (recommended if low disk space)

You do **not** need Flutter on your laptop. GitHub builds the APK for free in the cloud.

### Steps

1. **Push this repo to GitHub** (if not already):
   ```bash
   git add .
   git commit -m "Add Flutter app"
   git push origin main
   ```

2. Open your repo on GitHub → **Actions** tab.

3. Click **Build Flutter APK** → **Run workflow** → **Run workflow**.

4. Wait ~5–10 minutes for the job to finish (green checkmark).

5. Open the completed run → scroll to **Artifacts** → download **`skipq-flutter-apk`**.

6. Send the `.apk` file to your client. They install it on Android (enable “Install unknown apps” if prompted).

The APK is built against your live API:
`https://ssmskipq-1-s1dg.onrender.com/api`

To change the API URL, edit `.github/workflows/flutter-apk.yml` (the `--dart-define=API_BASE_URL=...` line) and run the workflow again.

---

## Features (parity with web PWA)

### Student
- Splash → Register / Login (mobile only)
- Browse menu (categories, search, veg filter)
- Cart, checkout (mock online / pay at counter)
- Order confirmation with live token + status timeline
- Order history, reorder, post-collection feedback
- Profile & logout

### Manager
- Login (Manager ID + password)
- Dashboard stats + ordering window
- Live orders (accept → preparing → ready → collected)
- Mark payment received, call student
- Menu CRUD with image upload
- Feedback dashboard
- Profile & logout

### Real-time
- Socket.io order updates
- Ordering window sync

---

## Local development (optional — needs ~5 GB for Flutter + Android SDK)

Only do this if you have enough storage and want to run on an emulator/device locally.

1. [Install Flutter SDK](https://docs.flutter.dev/get-started/install)
2. From this folder:
   ```bash
   flutter create . --org com.ssm.skipq --project-name ssm_skipq
   flutter pub get
   flutter run --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
   ```

---

## Configure API URL

Default API (Render):

```
https://ssmskipq-1-s1dg.onrender.com/api
```

Override when building or running locally:

```bash
flutter build apk --dart-define=API_BASE_URL=https://ssmskipq-1-s1dg.onrender.com/api
```

> **Android emulator + local backend:** use `http://10.0.2.2:5000/api` instead of `localhost`.

---

## Delivering to the client

| What to send | How |
|--------------|-----|
| **APK (Android)** | Download from GitHub Actions artifact (see above) |
| **Source code** | This `ssm-skipq-flutter/` folder in the repo |
| **Backend** | Already on Render — share API health URL |

Tell the client: the Flutter app is the **Android client**; the same backend powers the web app too.

**iOS:** Building for iPhone requires a Mac + Apple Developer account. For demos, Android APK is usually enough. iOS can be added later via Codemagic or a Mac CI machine.

---

## Backend

Mobile apps call the API directly — **no browser CORS** issues.

Ensure Render has `MONGODB_URI` and other env vars set. See [DEPLOYMENT.md](../DEPLOYMENT.md).

---

## Project structure

```
lib/
├── config/          API URL, theme, services
├── models/          User, menu, order, feedback
├── services/        REST + Socket.io clients
├── providers/       Auth, cart, ordering window
├── router/          go_router routes
├── screens/         Student + manager UI
└── widgets/         Shared components + shells
```

---

## Default credentials

| Role | Credentials |
|------|-------------|
| Manager | `SSM001` / `manager123` (after backend seed) |
| Student | Register with name + mobile |

---

## Notes

- The **React web app** remains in `ssm-skipq-frontend/` — Flutter is the mobile client the client requested.
- Payment is still **mock online** until Razorpay integration (see `PROJECT_OVERVIEW.md` roadmap).
