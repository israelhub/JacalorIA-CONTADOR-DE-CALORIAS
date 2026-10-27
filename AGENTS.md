# AGENTS.md

## Cursor Cloud specific instructions

This is a monorepo for **Jacaloria / JacalorIA**, an AI calorie/nutrition tracker (pt-BR):

- `backend/` — NestJS 11 + TypeScript REST API (Node 22), Sequelize ORM over PostgreSQL. Entry `src/main.ts`, global prefix `/api`, port `3000`.
- `frontend/` — Flutter (Dart) cross-platform client. Entry `lib/main.dart`.

### Services and how to run them

| Service | Dir | Run command | Notes |
|---|---|---|---|
| Backend API | `backend/` | `npm run start` (or `npx nest start --watch` for hot reload) | Serves `http://localhost:3000/api`; health at `/api/health`. |
| Frontend (web) | `frontend/` | `flutter run -d web-server --web-hostname 0.0.0.0 --web-port 5173 --dart-define=API_BASE_URL=http://localhost:3000/api` | First load compiles for 30–90s (debug/DDC) — a blank page at first is normal. |
| PostgreSQL | — | `sudo pg_ctlcluster 16 main start` | Must be started before the backend on each fresh VM boot (not started automatically). |

Lint/build: backend has no ESLint config; build with `npm run build`. Frontend lint is `flutter analyze` (pre-existing errors live only in `lib/main_showcase.dart` and `test/`, not the main app). Frontend build: `flutter build web`.

### Non-obvious caveats

- The local Postgres DB `jacaloria` and role `postgres` (password `postgres`) already exist in the VM snapshot; `backend/.env` (gitignored) is preconfigured to use them. If the DB is missing, recreate with `sudo -u postgres psql -c "CREATE DATABASE jacaloria;"`.
- In `NODE_ENV=development` Sequelize auto-syncs/alters the schema and seeds store/mission data on boot, so no manual migration step is needed for local dev (raw SQL migrations in `backend/migrations/` are for prod).
- Email is disabled (`MAIL_ENABLED=false`). Registration therefore requires an email verification code that is **printed to the backend console/log** as `[DEV] Código de verificação para <email>: <code>`. Grab it from the backend logs to verify an account, then log in. There is no auto-verify.
- `npm run start:dev`/`start:debug` invoke a PowerShell script (`pwsh`) and do **not** work on Linux — use `npm run start` or `npx nest start --watch` instead.
- The core food-photo AI analysis (and even manual "Digitar" meal entry, which routes through the AI parser) requires a Google Gemini `API_KEY` in `backend/.env`. Without it, meal analysis fails with `API_KEY não configurada`; all other flows (auth, onboarding, home dashboard, missions, social) work without it.
- Flutter SDK lives at `/opt/flutter` (on `PATH` via `~/.bashrc`). `API_BASE_URL` must be passed via `--dart-define` when running the web app against the local backend.
