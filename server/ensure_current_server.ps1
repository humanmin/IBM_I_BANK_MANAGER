param(
  [int]$Port = 8080
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$healthUri = "http://127.0.0.1:$Port/health"

function Test-CurrentApi {
  try {
    $health = Invoke-RestMethod -Uri $healthUri -TimeoutSec 2
    return (
      $health.ok -eq $true -and
      $health.service -eq 'ibank-manager-api' -and
      [int]$health.apiVersion -ge 2 -and
      $health.routes.spendingInsights -eq $true
    )
  } catch {
    return $false
  }
}

if (Test-CurrentApi) {
  Write-Host '[OK] Current IBM I Bank Manager API is already running.'
  exit 0
}

$listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
  Select-Object -First 1

if ($listener) {
  $serverProcessId = [int]$listener.OwningProcess
  $process = Get-Process -Id $serverProcessId -ErrorAction Stop
  $processInfo = Get-CimInstance Win32_Process -Filter "ProcessId = $serverProcessId"
  $isIbankNodeServer =
    $process.ProcessName -eq 'node' -and
    $processInfo.CommandLine -match 'server[\\/]server\.mjs'

  if (-not $isIbankNodeServer) {
    Write-Error "Port $Port is being used by another program ($($process.ProcessName), PID $serverProcessId)."
    exit 1
  }

  Write-Host "[INFO] Replacing an old IBM I Bank Manager API process (PID $serverProcessId)."
  Stop-Process -Id $serverProcessId -Force
  $process.WaitForExit()
}

$node = (Get-Command node -ErrorAction Stop).Source
$stdout = Join-Path $env:TEMP 'ibank-manager-api.out.log'
$stderr = Join-Path $env:TEMP 'ibank-manager-api.err.log'
Remove-Item -LiteralPath $stdout, $stderr -Force -ErrorAction SilentlyContinue

$server = Start-Process `
  -FilePath $node `
  -ArgumentList @('--env-file=server\.env', 'server\server.mjs') `
  -WorkingDirectory $projectRoot `
  -WindowStyle Hidden `
  -RedirectStandardOutput $stdout `
  -RedirectStandardError $stderr `
  -PassThru

for ($attempt = 0; $attempt -lt 40; $attempt++) {
  Start-Sleep -Milliseconds 250
  if (Test-CurrentApi) {
    Write-Host "[OK] IBM I Bank Manager API started (PID $($server.Id))."
    exit 0
  }
  if ($server.HasExited) { break }
}

if (Test-Path -LiteralPath $stderr) {
  Get-Content -LiteralPath $stderr | Write-Error
}
Write-Error 'The IBM I Bank Manager API did not become ready.'
exit 1
