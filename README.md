# PLANO — Personal Productivity and Activity-Tracking Hub

Plano is a minimal, fast productivity and activity-tracking hub for Android and responsive web built with Flutter (Material 3).

## 1. Feature Implementation & Verification Status

| Feature / Domain | Verification Status | Notes |
| :--- | :--- | :--- |
| **Plano Brand & Assets** | **Implemented; not independently verified** | SVG logos, app icons, PWA icons, and favicons are present. |
| **Material 3 App Shell** | **Implemented; build not verified** | Responsive mobile and desktop/web layouts, light & dark themes, empty and error states. |
| **Dashboard** | **Implemented; not end-to-end verified** | UI reads dashboard summaries from the signed-in user's loaded records. |
| **Flexible Activity Logging** | **Implemented; not end-to-end verified** | Activity forms, category filters, and search are present. |
| **Tasks & Projects** | **Implemented; not end-to-end verified** | Task and project screens and data models are present. |
| **Habits & Learning** | **Implemented; not end-to-end verified** | Habit, check-in, and learning screens and data models are present. |
| **Deterministic Reports** | **Implemented; tests pending** | Report calculations and CSV export are implemented in application logic. |
| **Authentication** | **Implemented but not end-to-end verified** | Email/password sign-up and sign-in require client configuration. |
| **Natural-Language Assistant** | **Not operational** | Remote Flutter invocation and safe verified persistence must be completed before claiming assistant mutations work. |
| **Android Health Connect** | **Implemented but unverified** | Native channel and aggregate queries exist. Permission grant flow and physical-device verification remain outstanding. |
| **Database & RLS Isolation** | **Implemented but not deployed or verified** | Migration and RLS test script are in the repository. Run the reviewed migration in the intended Supabase project and execute the isolation test before relying on it. |

---

## 2. Architecture & Request Flow

```
[Flutter Client (Android / Web)]
       │
       ▼ (Bearer JWT via Supabase Auth)
[Supabase Edge Function: assistant_action]
       │ (Validates JWT claims, derives verified user ID)
       ▼ (Signs with X-Plano-Webhook-Secret)
[Protected n8n Webhook]
       │
       ▼
[Groq LLM Inference (llama-3.3-70b-versatile)]
       │ (Strict Typed JSON Schema Output)
       ▼
[Client Confirmation → Edge Function user-JWT RLS write → read-back verification]
```

---

## 3. Setup & Environment Variables

Flutter does not load `.env` files. Enter only your project URL and **publishable** key in `config/supabase.dev.json`, replacing the two placeholder values. This file is ignored by Git. The tracked `config/supabase.dev.example.json` is a template, not a runtime config.

```powershell
flutter run --dart-define-from-file=config/supabase.dev.json
```

For web and Android builds, pass the same option to `flutter build web --release` or `flutter build apk --release`. The app reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` via `String.fromEnvironment` in `lib/main.dart`. Missing or placeholder values show a configuration screen; they do not load seeded demo records. Sign-in and sign-up use Supabase Auth.

**Never put `SUPABASE_SECRET_KEY` in this file.** The current Edge Function uses the caller's verified JWT and user-scoped database access; it does not need the Supabase secret key or `SUPABASE_JWKS_URL`. Do not add either to the client. After n8n exists, store `GROQ_API_KEY` as an n8n Groq credential, and store `N8N_WEBHOOK_URL` and `N8N_WEBHOOK_SECRET` in Supabase Edge Function secrets. Keep the Supabase secret key unused unless a reviewed server-only operation specifically requires it.

### Database Migration
The migration at `supabase/migrations/20261030000001_initial_plano_schema.sql` has not been applied. Review it before running it in the Supabase SQL Editor or with the Supabase CLI against the intended project.

### n8n Automation Setup
1. In n8n, go to **Workflows > Import from File** and import `n8n/workflows/plano_assistant_workflow.json`.
2. Connect your Groq API credentials.
3. Configure `PLANO_WEBHOOK_SECRET` in n8n environment variables.
4. Set the webhook URL and secret in Supabase Edge Function secrets:
   ```bash
   supabase secrets set N8N_WEBHOOK_URL="https://your-n8n.example.com/webhook/plano-assistant"
   supabase secrets set N8N_WEBHOOK_SECRET="your-32-char-random-secret"
   ```

---

## 4. Running & Testing

### Running Tests
All targeted unit, analytics, and schema tests run via Flutter test:
```powershell
flutter test --dart-define-from-file=config/supabase.dev.json
```

### Building for Responsive Web
```powershell
flutter build web --release --dart-define-from-file=config/supabase.dev.json
```
The compiled output is located in `build/web/`.

### Building for Android
```powershell
flutter build apk --release --dart-define-from-file=config/supabase.dev.json
```

---

## 5. Health Connect Permissions & Samsung Health Guidance
- **Android Permissions**:
  - `android.permission.health.READ_STEPS`
  - `android.permission.health.READ_EXERCISE`
- **Samsung Health Sync**:
  Samsung Health synchronizes supported records (steps, workouts) to Android Health Connect when enabled in Samsung Health > Settings > Connected services > Health Connect. Plano reads solely from Health Connect via AndroidX client.
- **Privacy & Retention**:
  - Health records are strictly owner-only and cannot be viewed by other workspace members.
  - Raw health records are never sent to Groq.
  - Users can delete all imported health records from within Plano Settings at any time.

---

## 6. Brand Asset Locations
- Vector SVGs: `assets/branding/plano_logo.svg`, `plano_logo_dark.svg`, `plano_logo_light.svg`, `plano_icon.svg`
- Web Icons: `web/favicon.png`, `web/icons/Icon-192.png`, `web/icons/Icon-512.png`
- Android Adaptive Icons: `android/app/src/main/res/drawable/ic_launcher_foreground.xml`, `ic_launcher_background.xml`
- Regeneration Script: `python generate_brand_assets.py`
