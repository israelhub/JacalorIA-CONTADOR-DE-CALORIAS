$clientId = $env:GOOGLE_WEB_CLIENT_ID
$webPort = if ($env:FLUTTER_WEB_PORT) { $env:FLUTTER_WEB_PORT } else { '' }

if (-not $clientId) {
  $envFile = Join-Path $PSScriptRoot "..\frontend\.env.local"
  $envFile = [System.IO.Path]::GetFullPath($envFile)

  if (Test-Path -LiteralPath $envFile) {
    $line = Get-Content -LiteralPath $envFile |
      Where-Object { $_ -match '^GOOGLE_WEB_CLIENT_ID=' } |
      Select-Object -First 1

    if ($line) {
      $clientId = ($line -split '=', 2)[1].Trim().Trim('"')
    }

    if (-not $webPort) {
      $portLine = Get-Content -LiteralPath $envFile |
        Where-Object { $_ -match '^FLUTTER_WEB_PORT=' } |
        Select-Object -First 1
      if ($portLine) {
        $webPort = ($portLine -split '=', 2)[1].Trim().Trim('"')
      }
    }
  }
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

if (-not $webPort) {
  $webPort = '5173'
}

if (-not $clientId) {
  Write-Error "Defina GOOGLE_WEB_CLIENT_ID no ambiente, em frontend/.env.local, ou GOOGLE_CLIENT_ID em backend/.env."
  exit 1
}

flutter run -d chrome --web-port=$webPort --dart-define="GOOGLE_WEB_CLIENT_ID=$clientId"
