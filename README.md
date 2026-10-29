# PLANO — Personal Productivity and Activity-Tracking Hub

Plano is a minimal, fast productivity and activity-tracking hub for Android and responsive web built with Flutter (Material 3).

## 1. Feature Implementation & Verification Status

| Feature / Domain | Verification Status | Notes |
| :--- | :--- | :--- |
| **Plano Brand & Assets** | **Implemented & Verified** | Original geometric monogram "P" vector SVGs, light/dark/monochrome variants, adaptive Android icon XMLs, PWA icons, web favicons generated via `generate_brand_assets.py`. |
| **Material 3 App Shell** | **Implemented & Verified** | Responsive layout supporting mobile (`NavigationBar`) and desktop/web (`NavigationRail`), light & dark themes, accessible contrast, empty & error states. Verified via 6 automated unit & smoke tests and release web compilation. |
| **Dashboard** | **Implemented & Verified** | Today's scheduled tasks, completed tasks, time logged, habit check-in circles, available health summaries, weekly category breakdown. Distinguishes unavailable health data from zero. |
| **Flexible Activity Logging** | **Implemented & Verified** | Log work, personal projects, learning, workouts, habits, errands, creative, and rest. Duration, tags, notes, dates, timezone preservation, and project associations. Search and category filtering. |
| **Tasks & Projects** | **Implemented & Verified** | Task status (todo, completed, overdue), priority flags (low, medium, high, urgent), due dates, estimates, project grouping, and progress indicators. |
| **Habits & Learning** | **Implemented & Verified** | Frequency schedules (daily, weekdays, weekends), visual 7-day check-in history, timezone-aware streak tracking. Study sessions with duration, resource links, and certification/skill goals. |
| **Deterministic Reports** | **Implemented & Verified** | Date-range filters (7 days, 30 days, month, custom), category time breakdowns, completion percentages, habit consistency %, and one-click CSV export. Totals calculated via deterministic logic. |
| **Natural-Language Assistant** | **Implemented & Verified** (Local parser) / **Implemented but not externally configured** (Remote n8n+Groq) | Parsed into typed, validated actions (`log_activity`, `create_task`, `checkin_habit`, `query_summary`). Ambiguous inputs prompt for clarification. Destructive mutations require explicit confirmation preview. Trusted Supabase Edge Function (`assistant_action`) and n8n workflow definition (`plano_assistant_workflow.json`) included in repo. |
| **Android Health Connect** | **Implemented & Verified** (Adapter & Manifest) / **Partially implemented** (Physical Samsung device end-to-end sync) | Method channel integration (`com.plano.app/health_connect`) with SDK availability checks, permission rationale intents, and aggregate queries for steps and workout durations. Deletion of imported data supported. Full end-to-end synchronization requires testing on a physical Android device with Health Connect installed. |
| **Database & RLS Isolation** | **Implemented & Verified** | Full PostgreSQL migration (`20261030000001_initial_plano_schema.sql`) covering profiles, workspaces, projects, tasks, activity logs, habits, checkins, learning, health summaries, and audit logs. All tables have RLS enabled. Health data is strictly owner-only. Isolation verification test provided in `supabase/tests/rls_isolation_test.sql`. |

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
[Client Approval & Tenant-Scoped RLS Mutation]
```

---

## 3. Setup & Environment Variables

Copy `.env.example` to `.env` and provide your credentials:

```bash
# Supabase Configuration
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_ANON_KEY=your-supabase-publishable-key
SUPABASE_SERVICE_ROLE_KEY=your-supabase-service-role-key

# Trusted Backend & n8n Bridge
N8N_WEBHOOK_URL=https://your-n8n.example.com/webhook/plano-assistant
N8N_WEBHOOK_SECRET=your-32-char-random-secret

# Groq LLM Inference
GROQ_API_KEY=gsk_your_groq_api_key
```

### Database Migrations
Apply the PostgreSQL migration using the Supabase CLI:
```bash
supabase db push
# Or run supabase/migrations/20261030000001_initial_plano_schema.sql directly in the Supabase SQL Editor
```

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
```bash
flutter test
```

### Building for Responsive Web
```bash
flutter build web --release
```
The compiled output is located in `build/web/`.

### Building for Android
```bash
flutter build apk --debug
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
