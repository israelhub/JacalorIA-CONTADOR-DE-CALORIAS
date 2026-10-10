---
name: run-dev-android
description: >-
  Sobe o ambiente de desenvolvimento Android do Jacaloria (NestJS backend +
  Flutter no emulador ou device). Use when the user asks to run/start Android,
  emulador, celular, dispositivo físico, ambiente mobile, ou similar.
---

# Run Dev Android (Jacaloria)

## Objetivo

Subir backend + app Flutter em dispositivo/emulador Android.

## Pré-checks

1. Confirme `backend/.env` e Flutter no PATH (ou `FLUTTER_HOME`).
2. Liste dispositivos:

```powershell
adb devices -l
flutter devices
flutter emulators
```

3. Se não houver device/emulador:
   - Preferir device USB com debugging ligado; ou
   - Iniciar um AVD existente: `flutter emulators --launch <id>`
   - Só criar AVD novo se o usuário autorizar.

## Fluxo padrão com device físico (preferido no repo)

O script sobe backend (se necessário), ngrok e o Flutter com `API_BASE_URL` público:

```powershell
pwsh -ExecutionPolicy Bypass -File ./scripts/flutter_mobile_with_ngrok.ps1
```

Opcional: force o device com `FLUTTER_DEVICE_ID`:

```powershell
$env:FLUTTER_DEVICE_ID = '<device-id>'
pwsh -ExecutionPolicy Bypass -File ./scripts/flutter_mobile_with_ngrok.ps1
```

Requisitos do script: `NGROK_AUTHTOKEN` (ou config ngrok já autenticada). Ele também ajusta `JAVA_HOME`/Gradle se precisar.

Rode em background (`block_until_ms: 0`) e monitore até o app instalar/abrir.

## Fluxo emulador (API local sem ngrok)

No emulador, `ApiConfig` já usa `http://10.0.2.2:3000/api`.

1. Backend (background):

```powershell
cd backend
npm run start:dev
```

2. Flutter no emulador:

```powershell
cd frontend
flutter run -d <emulator-id>
```

Não precisa de `--dart-define=API_BASE_URL` no emulador local.

## Fluxo device físico sem ngrok (mesma Wi‑Fi)

1. Suba o backend.
2. Descubra o IPv4 LAN do PC (ignore Loopback/`169.*`).
3. Garanta firewall liberando TCP `3000` (regra "Jacaloria Backend 3000" se já existir).
4. Rode:

```powershell
cd frontend
flutter run -d <device-id> --dart-define=API_BASE_URL=http://<IP_LAN>:3000/api
```

Backup via USB:

```powershell
adb -s <device-id> reverse tcp:3000 tcp:3000
```

Com reverse, também funciona `API_BASE_URL=http://127.0.0.1:3000/api`.

## Fluxo apontando para AWS (produção)

```powershell
cd frontend
flutter run -d <device-id> --dart-define=API_BASE_URL=https://jacaloria.online/api
```

## Verificação

- `adb devices` mostra o target como `device`.
- Backend escutando na porta configurada (default 3000), **ou** túnel ngrok ativo (`http://127.0.0.1:4040`).
- App instalado e aberto no device; informe `device-id` e `API_BASE_URL` usados.

## Troubleshooting

| Sintoma | Ação |
|---------|------|
| Nenhum device | Pedir USB debugging / iniciar emulador. |
| `No route to host` | IP LAN mudou; recalcular IP e reinstalar com novo `API_BASE_URL`. |
| Gradle/Java | Script mobile já tenta setar JBR do Android Studio; se falhar, configurar `JAVA_HOME` (JDK 17+). |
| ngrok sem token | Pedir `NGROK_AUTHTOKEN` ou usar fluxo LAN/emulador. |
| Backend DB down | Avisar; app sobe mas API falha até corrigir Supabase/`backend/.env`. |

## Não fazer

- Não assumir IP LAN antigo de sessões anteriores — sempre resolver de novo.
- Não criar AVD/instalar system images sem pedido explícito (demorado).
- Não commitar `.env`, tokens ngrok, nem alterar `gradle.properties` além do que o script já faz.
