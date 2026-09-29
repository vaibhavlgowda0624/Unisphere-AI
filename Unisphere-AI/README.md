# UniSphere AI (UniHub)

Android-first campus application built with Flutter, Spring Boot and Firebase. Original requirements: [`UniHub_Report.pdf`](UniHub_Report.pdf) and [`New unisphere project ppt.pptx`](New%20unisphere%20project%20ppt.pptx). See [`docs/implementation-plan.md`](docs/implementation-plan.md) for architecture and acceptance gates.

## Delivery status

This is a **development foundation, not a completed production application**. It runs against local Firebase emulators without a Firebase account. A real Firebase project and university email domain have not yet been supplied.

Implemented: Flutter registration, sign-in, email verification gate, password reset, profile editing and role requests; published event browsing, creation, publishing and atomic registration; note search, PDF/DOCX upload and download, admin moderation; super admin role decisions and audit records; offline SGPA/CGPA with local history; Firebase ID token and canonical Firestore role checks in Spring; Firestore and Storage rules; weighted lost-and-found matching and Jaccard integrity scoring in the backend.

Still required for the full brief: club membership and management, assignments and submissions, doubts and answers, lost-and-found posting/claims UI, study planner, summaries/flashcards, FCM notifications, recommendations, document extraction and full integrity review, analytics, pagination/offline sync hardening, accessibility, end-to-end tests and production release. Treat the current app as a development build.

## Repository layout

| Path | Purpose |
| --- | --- |
| `mobile/` | Flutter Android/iOS client |
| `backend/` | Java 17 Spring Boot API |
| `firestore.rules`, `storage.rules` | Firebase security policies |
| `firestore.indexes.json` | Composite indexes |
| `tests/` | Firebase rules tests |
| `docs/implementation-plan.md` | Scope and acceptance gates |

## Prerequisites

Flutter SDK, Android SDK and an Android emulator/device; Java 17 and Maven 3.9.x for the backend; Node.js 20+ and npm; Java 21 for the current Firebase CLI emulator. Use separate terminals for Java 17 and Java 21. The Android emulator reaches the host as `10.0.2.2`; physical devices need your computer's reachable LAN IP.

## Run without a Firebase account

Terminal 1, repository root, with Java 21:

```powershell
npm ci
$env:JAVA_HOME = 'C:\path\to\jdk-21'
$env:Path = "$env:JAVA_HOME\bin;$env:Path"
npx firebase emulators:start --project demo-unisphere
```

Emulator UI: `http://localhost:4000`; Auth: 9099; Firestore: 8081; Storage: 9199.

Terminal 2, with Java 17:

```powershell
cd backend
$env:FIREBASE_PROJECT_ID = 'demo-unisphere'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081'
mvn spring-boot:run
```

Terminal 3:

```powershell
cd mobile
flutter pub get
flutter run --dart-define=USE_FIREBASE_EMULATORS=true --dart-define=EMULATOR_HOST=10.0.2.2 --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

Register and sign in against the Auth emulator. Verification links are available through the emulator UI. Emulator data is temporary unless exported.

## First administrator

New accounts start as `STUDENT`. After registering and verifying an account, get its UID from the Auth emulator UI. In a trusted backend shell set `ALLOW_ADMIN_BOOTSTRAP=true` and `BOOTSTRAP_SUPER_ADMIN_UID=<uid>`, then execute `edu.unisphere.api.admin.BootstrapSuperAdmin` with the backend runtime classpath. It refuses an unverified account or missing profile. Disable the bootstrap flag afterward. The Admin screen can then review faculty/club admin requests. This bootstrap command has not yet been packaged as a convenience script.

## Test and build

```powershell
cd backend
mvn clean test
mvn package
```

```powershell
cd mobile
flutter analyze
flutter test
flutter build apk --debug
```

```powershell
# Repository root, with Java 21 active
npm ci
npm run test:rules
```

Debug APK output: `mobile/build/app/outputs/flutter-apk/app-debug.apk`. A build does not substitute for connected emulator flow tests.

## Configure a production Firebase project

1. Create a Firebase project and register an Android app with package `edu.unisphere.ai` (and an iOS app if needed). Enable Email/Password Authentication, Firestore and Storage. Configure Messaging when implementing notifications.
2. Choose the university email domain. Pass `--dart-define=ALLOWED_EMAIL_DOMAIN=example.edu` to Flutter. This is currently client validation only; enforce the institution policy server-side and in Auth before launch.
3. Review and deploy `firestore.rules`, `storage.rules` and `firestore.indexes.json` to the intended project with the Firebase CLI.
4. Give a service account to the **backend runtime only** through `GOOGLE_APPLICATION_CREDENTIALS`; set `FIREBASE_PROJECT_ID`. Never commit credential JSON, signing keys or `.env` files.
5. Run Flutter with `USE_FIREBASE_EMULATORS=false` and real `FIREBASE_PROJECT_ID`, `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_SENDER_ID`, `FIREBASE_STORAGE_BUCKET` and HTTPS `BACKEND_URL` as `--dart-define` values (or `--dart-define-from-file`). See `mobile/lib/core/app_config.dart`.
6. Configure release signing, HTTPS hosting and staging tests for every role before publishing. `.env.example` lists backend settings, but `.env` is not automatically loaded.

## API and data rules

`/api/events` supports create/publish/delete and registration changes. `/api/admin` handles role and note decisions. `/api/intelligence/integrity` exposes faculty-only text similarity review. Each `/api/*` request needs `Authorization: Bearer <Firebase ID token>`; Spring reads the canonical role from Firestore. The client acquires the token from Firebase Auth.

Only trusted server operations should change roles, moderation status and registration counts. Some client queries currently cap results at 50 and need cursor pagination for large data sets.

SGPA is credit weighted within a semester; CGPA is the equal-weight mean of saved semester SGPAs, per the report. Lost-and-found weights are category 30%, color 25%, description 25% and location 20%; same-owner, same-type and inactive posts are excluded. Integrity similarity is a human review indicator, never an automatic misconduct verdict.
