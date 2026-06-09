# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LeadBridge is a multi-tenant lead management SaaS platform. It has two top-level components:
- **`backend/`** — Node.js/Express REST API (TypeScript)
- **`flutter_app/`** — Flutter cross-platform client (Android, iOS, Web)

## Commands

### Backend (`backend/`)

```bash
npm run dev          # Start dev server with hot reload (tsx watch src/app.ts)
npm run build        # Compile TypeScript → dist/
npm start            # Run compiled app (node dist/app.js)
npm run start:prod   # build + db:migrate + start (used in production)
npm run db:migrate   # Run SQL migrations (tsx src/scripts/migrate.ts)
```

No test runner is currently configured.

### Flutter (`flutter_app/`)

```bash
flutter pub get                   # Install dependencies
flutter analyze                   # Static analysis (flutter_lints)
flutter build apk --release       # Build Android APK
flutter build web --release       # Build web version
flutter run                       # Run on connected device/emulator
```

## Backend Architecture

The Express server (`src/app.ts`, port 3000) is organized into feature modules under `src/modules/`. Each module exports a router that is mounted in `app.ts`.

**Modules:**
- `auth/` — registration, login, JWT refresh, logout
- `leads/` — lead CRUD, filtering, stats
- `delivery/` — delivery companies, routing rules, dispatch orders
- `webhooks/` — inbound lead ingestion from Facebook, TikTok, Google
- `notifications/` — FCM push notifications
- `settings/` — organization profile, team members, lead sources, subscriptions

**Database layer** (`src/config/database.ts`): a single PostgreSQL pool with a `query()` helper used directly in service files — no ORM. All queries are parameterized SQL.

**Redis** (`src/config/redis.ts`): used for caching; imported by services as needed.

**Auth middleware** (`src/middleware/auth.ts`): JWT verification (15-min access tokens, 30-day refresh tokens stored in `refresh_tokens` table). Role-based access (`admin` vs standard user) is enforced per route.

**Multi-tenancy**: every table that holds tenant data has an `org_id` foreign key. All queries must filter by `org_id` — never query across tenants.

**Schema**: single source of truth is `src/models/schema.sql`. Changes are applied via `src/scripts/migrate.ts`.

**Rate limiting**: auth endpoints → 20 req/15 min; global → 200 req/60 s.

### Module file conventions

Each module directory contains:
- `{name}.routes.ts` — Express Router, mounts middleware + handlers
- `{name}.service.ts` — Business logic and direct SQL queries

## Flutter Architecture

### State management

All state is managed with **Riverpod**. The key providers are:
- `authStateProvider` (`AsyncNotifierProvider`) — session & user object
- `leadsProvider` (`NotifierProvider`) — paginated lead list with filters
- `apiClientProvider` (`Provider`) — singleton `ApiClient` (Dio-based)

### Feature structure

Each feature under `lib/features/{name}/` follows:
```
presentation/   ← Screens and widgets
providers/      ← Riverpod notifiers
data/           ← Repository classes that call ApiClient
```

### HTTP client (`lib/core/network/api_client.dart`)

Dio client with an interceptor that automatically refreshes the JWT on 401 responses and retries the original request. Tokens are stored in `flutter_secure_storage`.

### Navigation (`lib/core/router/router.dart`)

GoRouter with auth guards — unauthenticated users are redirected to `/login`. The shell (`lib/core/shell/app_shell.dart`) renders a navigation rail on desktop (>1200 px), compact rail on tablet, and bottom nav bar on mobile.

### Responsive breakpoints

| Width | Layout |
|-------|--------|
| > 1200 px | Extended navigation rail |
| 800–1200 px | Compact navigation rail |
| < 800 px | Bottom navigation bar |

## Deployment

- **Backend**: Render.com (`render.yaml`), region Singapore, PostgreSQL managed database
- **CI/CD**: GitHub Actions (`.github/workflows/build.yml`) — builds Android APK and deploys Flutter Web to GitHub Pages on push to `main`
- **Environment variables**: defined at runtime via `.env` (not committed); Render injects them in production

## Key Constraints

- Subscription plan limits are enforced server-side: Free (100 leads, 2 users), Pro (5000 leads, 10 users), Enterprise (unlimited).
- Webhook endpoints verify signatures via a per-source `webhook_secret` stored in `lead_sources`.
- UUID primary keys everywhere (`uuid_generate_v4()`); JSONB used for flexible metadata fields.
- `bcryptjs` with 12 rounds for password hashing.
