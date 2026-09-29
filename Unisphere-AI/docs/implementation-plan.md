# UniSphere AI implementation plan

## Source inspection (Phase 1)

The workspace initially contained only `UniHub_Report.pdf` (57 PDF pages) and `New unisphere project ppt.pptx` (10 slides). It had no application code, Git history, Firebase configuration, Flutter SDK on `PATH`, or Android build setup. Java 17 and Maven 3.9.16 are available. The report is the baseline; the presentation adds doubt resolution, document integrity review, study planning, summarization, and flashcards. The detailed user brief resolves conflicts in favor of those additions.

The report describes four roles, event registration, clubs, notes, assignments, weighted lost and found matching, recommendations, SGPA/CGPA, faculty contact, and notifications. It reports failures in validation of empty login fields, immediate event list refresh, partial notes search, claim notifications, empty SGPA input, profile photo refresh, and delayed event notifications. These become regression cases.

## Architecture decisions

- Flutter owns presentation, local grade calculations, cached read models, and Firebase Auth session handling. Feature repositories isolate UI from REST and Firebase SDK calls.
- Spring Boot owns privileged writes, atomic enrollment and membership operations, moderation, notifications, and intelligence services. Every protected endpoint verifies a Firebase ID token and reads the canonical role from Firestore. The client never sets its own role.
- Firestore stores documents and query projections; Cloud Storage stores files. Server processes cross-document invariants. Firestore and Storage rules deny privileged direct writes. FCM delivery is triggered by committed server operations; notification history persists before sending.
- No institution or Firebase project is configured yet. Credentials and university email domains must be supplied through environment configuration. Development can use Firebase emulators.
- CGPA follows the report's equal-weight average of semester SGPAs, while SGPA is credit-weighted by subject. This choice is documented in the calculator UI and tests.
- The requested role hierarchy is authorization inheritance, but club ownership is an additional resource-scoped check. A faculty user does not gain control of every club just because faculty precedes club admin in the stated hierarchy.

## Build sequence and acceptance gates

| Phase | Deliverable | Verification gate |
| --- | --- | --- |
| 1 | Repository and document audit | Source requirements and missing configuration recorded |
| 2 | Flutter and Spring Boot structure, contracts, emulator configuration | Both projects compile; health endpoint; analysis clean |
| 3 | Firebase Auth, profile, role requests, four role shells, theme | Register, verify, login, reset, logout; role tests |
| 4 | Firebase Admin token verification, Firestore/Storage rules, common errors and pagination | Unauthorized writes rejected by API and rules tests |
| 5 | Events and clubs with atomic registration and scoped administration | Capacity, duplicate, membership, immediate list refresh tests |
| 6 | Notes and Cloud Storage, metadata search, recommendations | Upload validation, partial search, download and fallback tests |
| 7 | Assignments, submissions, faculty review | Due date and target audience tests |
| 8 | Doubts, answers, routing and moderation | Relevance and accepted-answer authorization tests |
| 9 | Lost and found matching | Exact 30/25/25/20 weights, own-post exclusion, claim notification tests |
| 10 | Offline SGPA and CGPA | Empty and zero-credit validation; history persistence tests |
| 11 | PDF/DOCX extraction, Jaccard integrity checks, faculty decisions | Configurable threshold and non-verdict review tests |
| 12 | Study planning | Event conflicts, overlapping blocks, deadline change tests |
| 13 | Summaries and flashcards behind provider interfaces | Deterministic local fallback and source attribution tests |
| 14 | FCM, history, preferences, deep links | Category opt-out, retry, delivery record tests |
| 15 | Admin moderation, users, analytics, audit | Role and resource authorization tests |
| 16 | Offline caches and safe sync | Stale data and pending write visibility tests |
| 17 | Accessibility, performance, security and integration audit | Emulator end-to-end workflows; no dead primary navigation |
| 18 | Documentation and Android build | Flutter analyze/test/build and Maven test/package pass |

Each phase ends with available unit/integration tests, static analysis, build, navigation and role checks. A phase is recorded as incomplete if an external credential, SDK, emulator, or device prevents verification.

## Initial data model

`users/{uid}`, `role_requests/{id}`, `events/{id}`, `event_registrations/{eventId_uid}`, `clubs/{id}`, `club_members/{clubId_uid}`, `club_join_requests/{clubId_uid}`, `notes/{id}`, `note_interactions/{id}`, `assignments/{id}`, `submissions/{assignmentId_uid}`, `doubts/{id}`, `doubt_answers/{id}`, `lost_found/{id}`, `faculty/{uid}`, `notifications/{uid}/items/{id}`, `study_plans/{uid}`, `flashcards/{uid}/items/{id}`, `summaries/{id}`, `integrity_checks/{id}`, `reports/{id}`, and `audit_logs/{id}`. Queries must be scoped, ordered, and cursor paginated. Collection ownership, required fields, and composite indexes will be documented as each phase ships.

## External setup needed before end-to-end verification

Firebase project and Android app registration; authorized university email domain(s); Firebase Auth email/password, Firestore, Storage and FCM enabled; service account available only to the backend runtime; Android SDK and Flutter SDK; one emulator or Android device. A first super admin must be provisioned through a guarded server-side bootstrap operation, not a client write.
