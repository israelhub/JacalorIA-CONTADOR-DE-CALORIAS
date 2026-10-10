---
name: run-dev-web
description: >-
  Sobe o ambiente de desenvolvimento web do Jacaloria (NestJS backend + Flutter
  Web). Use when the user asks to run/start web, Chrome, localhost, frontend web,
  ambiente de desenvolvimento web, or similar.
---

# Run Dev Web (Jacaloria)

## Objetivo

Subir backend + Flutter Web em desenvolvimento neste repositório.

## Pré-checks

1. Confirme que existem:
   - `backend/.env` (DB/JWT/PORT)
   - `frontend/.env` ou `frontend/.env.local` com `GOOGLE_WEB_CLIENT_ID` (e opcional `FLUTTER_WEB_PORT`)
2. Se faltar `GOOGLE_WEB_CLIENT_ID`, pare e peça ao usuário preencher `frontend/.env` a partir de `frontend/.env.local.example`.
3. Verifique terminais já ativos para não duplicar backend (porta 3000) ou web (porta 5173).

## Fluxo padrão (preferido)

Use os scripts do repo (PowerShell):

1. **Backend** (background, `block_until_ms: 0`):

```powershell
cd backend
npm run start:dev
```

2. **Frontend Web** (background, `block_until_ms: 0`):

```powershell
pwsh -ExecutionPolicy Bypass -File ./scripts/flutter_web_with_google.ps1
```

O script lê `GOOGLE_WEB_CLIENT_ID` / `FLUTTER_WEB_PORT` / `API_BASE_URL` de `frontend/.env` (default port `5173`) e passa `--dart-define`s. API padrão: `http://localhost:3000/api`. Produção AWS: `https://jacaloria.online/api`.

## Fluxo local (backend local + Chrome)

Quando o usuário pedir API local (`localhost:3000`):

1. Suba o backend como acima.
2. Aguarde a porta `3000` (ou `PORT` do `backend/.env`).
3. Rode o Flutter apontando para o backend local:

```powershell
cd frontend
flutter run -d chrome --web-port=5173 --dart-define=GOOGLE_WEB_CLIENT_ID=<id> --dart-define=API_BASE_URL=http://localhost:3000/api
```

Sem `--dart-define=API_BASE_URL`, o app web já usa `http://localhost:3000/api` via `ApiConfig`.

Alternativa rápida sem Google define (só UI):

```powershell
cd frontend
flutter run -d chrome --web-port=5173
```

## Verificação

- Backend: `http://localhost:3000` respondendo (health/API).
- Frontend: `http://localhost:5173` (ou `FLUTTER_WEB_PORT`).
- Informe ao usuário as URLs e se o backend falhou (ex.: Supabase inacessível).

## Troubleshooting

| Sintoma | Ação |
|---------|------|
| Porta 3000 ocupada | O `start:dev` já chama `scripts/start_backend_clean.ps1` (mata processos na porta). Se falhar, inspecione o log do terminal. |
| `GOOGLE_WEB_CLIENT_ID` missing | Preencher `frontend/.env`. |
| Flutter não encontrado | Pedir `FLUTTER_HOME` ou Flutter no PATH. |
| DB/Supabase erro no boot | Avisar; frontend ainda pode subir, mas login/API falham até corrigir `backend/.env`. |

## Não fazer

- Não commitar `.env`.
- Não usar `flutter run -d web-server` sem o script, a menos que o usuário peça explicitamente (o script já cobre Google + port).
- Não matar processos alheios fora da porta do backend do projeto.
