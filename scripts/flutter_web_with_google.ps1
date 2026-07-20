$clientId = $env:GOOGLE_WEB_CLIENT_ID
$webPort = if ($env:FLUTTER_WEB_PORT) { $env:FLUTTER_WEB_PORT } else { '' }
# Prefer explicit env, then frontend .env, then local backend.
$apiBaseUrl = if ($env:API_BASE_URL) { $env:API_BASE_URL } else { '' }

if (-not $clientId -or -not $webPort -or -not $apiBaseUrl) {
  $frontendEnvFiles = @(
    (Join-Path $PSScriptRoot "..\frontend\.env"),
    (Join-Path $PSScriptRoot "..\frontend\.env.local")
  ) | ForEach-Object { [System.IO.Path]::GetFullPath($_) }

  foreach ($envFile in $frontendEnvFiles) {
    if (-not (Test-Path -LiteralPath $envFile)) {
      continue
    }

    $lines = Get-Content -LiteralPath $envFile

    if (-not $clientId) {
      $line = $lines |
        Where-Object { $_ -match '^GOOGLE_WEB_CLIENT_ID=' } |
        Select-Object -First 1
      if ($line) {
        $clientId = ($line -split '=', 2)[1].Trim().Trim('"')
      }
    }

    if (-not $webPort) {
      $portLine = $lines |
        Where-Object { $_ -match '^FLUTTER_WEB_PORT=' } |
        Select-Object -First 1
      if ($portLine) {
        $webPort = ($portLine -split '=', 2)[1].Trim().Trim('"')
      }
    }

    if (-not $apiBaseUrl) {
      $apiLine = $lines |
        Where-Object { $_ -match '^API_BASE_URL=' } |
        Select-Object -First 1
      if ($apiLine) {
        $apiBaseUrl = ($apiLine -split '=', 2)[1].Trim().Trim('"')
      }
    }

    if ($clientId -and $webPort -and $apiBaseUrl) {
      break
    }
  }
}

if (-not $apiBaseUrl) {
  $apiBaseUrl = 'http://localhost:3000/api'
}

if (-not $clientId) {
  $backendEnvFile = Join-Path $PSScriptRoot "..\backend\.env"
  $backendEnvFile = [System.IO.Path]::GetFullPath($backendEnvFile)

  if (Test-Path -LiteralPath $backendEnvFile) {
    $line = Get-Content -LiteralPath $backendEnvFile |
      Where-Object { $_ -match '^GOOGLE_CLIENT_ID=' } |
      Select-Object -First 1

    if ($line) {
      $clientId = ($line -split '=', 2)[1].Trim().Trim('"')
    }
  }
}

function Get-FlutterCommand {
  $candidates = @()

  if ($env:FLUTTER_HOME) {
    $candidates += (Join-Path $env:FLUTTER_HOME "bin\flutter.bat")
  }

  $candidates += @(
    "$env:USERPROFILE\flutter\bin\flutter.bat",
    "$env:USERPROFILE\development\flutter\bin\flutter.bat",
    "$env:LOCALAPPDATA\Programs\flutter\bin\flutter.bat",
    "C:\src\flutter\bin\flutter.bat"
  )

  foreach ($candidate in $candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate)) {
      return $candidate
    }
  }

  $cmd = Get-Command flutter -ErrorAction SilentlyContinue
  if ($cmd) {
    return "flutter"
  }

  return $null
}

$flutterCmd = Get-FlutterCommand
if (-not $flutterCmd) {
  Write-Error "Flutter não encontrado. Defina FLUTTER_HOME ou adicione flutter ao PATH."
  exit 1
}

if (-not $webPort) {
  $webPort = '5173'
}

if (-not $clientId) {
  Write-Error "Defina GOOGLE_WEB_CLIENT_ID no ambiente, em frontend/.env, frontend/.env.local, ou GOOGLE_CLIENT_ID em backend/.env."
  exit 1
}

$frontendDir = Join-Path $PSScriptRoot "..\frontend"
$frontendDir = [System.IO.Path]::GetFullPath($frontendDir)

Write-Host "Flutter Web -> API_BASE_URL=$apiBaseUrl (porta $webPort)" -ForegroundColor Cyan

Push-Location $frontendDir
try {
  & $flutterCmd run -d web-server --web-hostname=127.0.0.1 --web-port=$webPort `
    --dart-define="GOOGLE_WEB_CLIENT_ID=$clientId" `
    --dart-define="API_BASE_URL=$apiBaseUrl"
}
finally {
  Pop-Location
}
