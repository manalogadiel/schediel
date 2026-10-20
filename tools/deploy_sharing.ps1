<#
.SYNOPSIS
  Deploys Schediel online sharing: Supabase database + edge functions, and
  the Vercel share page. See README "Online sharing" for the account steps
  that must happen first.

.DESCRIPTION
  Reads env/sharing.json (copy env/sharing.example.json). Prompts for the
  database password itself (Supabase CLI); no secret is printed, passed on
  a command line or written into the repository.

  Steps (each can be skipped):
    1. link the Supabase project and push the migration
    2. set function secrets (rate-limit key generated here, never shown)
    3. deploy the five edge functions and probe them
    4. build the share page (with assetlinks.json from your release key)
       and deploy it to Vercel

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1 -DatabaseCaPath $HOME\Downloads\prod-ca-2021.crt
#>
param(
  [string]$DatabaseCaPath,
  [ValidateSet('x-real-ip', 'x-forwarded-for', 'cf-connecting-ip')]
  [string]$IpHeader = 'x-real-ip',
  [switch]$RotateRateSecret,
  [switch]$SkipDatabase,
  [switch]$SkipSecrets,
  [switch]$SkipFunctions,
  [switch]$SkipWeb
)

$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$backend = Join-Path $repo 'backend'
$web = Join-Path $repo 'web-preview'
$dist = Join-Path $web 'dist'

function Step($text) { Write-Host "`n== $text" -ForegroundColor Cyan }
function Fail($text) { Write-Host "ERROR: $text" -ForegroundColor Red; exit 1 }
function Run($what) {
  # Runs a native command (scriptblock) and stops on a non-zero exit code.
  & $what
  if ($LASTEXITCODE -ne 0) { Fail "command failed ($LASTEXITCODE): $what" }
}

# --- settings ---------------------------------------------------------------
$settingsPath = Join-Path $repo 'env\sharing.json'
if (-not (Test-Path $settingsPath)) { Fail "env\sharing.json not found. Copy env\sharing.example.json and fill it in." }
$s = Get-Content $settingsPath -Raw | ConvertFrom-Json
$url = "$($s.SCHEDIEL_SUPABASE_URL)".TrimEnd('/')
$key = "$($s.SCHEDIEL_SUPABASE_KEY)"
$shareHost = "$($s.SCHEDIEL_SHARE_HOST)"
$ref = "$($s.SCHEDIEL_SUPABASE_PROJECT_REF)"
$vercelProject = "$($s.SCHEDIEL_VERCEL_PROJECT)"

if ((Get-Content $settingsPath -Raw) -match 'YOUR-|REPLACE_ME') { Fail 'env\sharing.json still has placeholders.' }
if ((Get-Content $settingsPath -Raw) -match 'sb_secret_|service_role|postgres(ql)?://') { Fail 'env\sharing.json must hold only public values (no secret key, service key or database URL).' }
if ($url -notmatch '^https://[a-z0-9]+\.supabase\.co$') { Fail "SCHEDIEL_SUPABASE_URL should look like https://<ref>.supabase.co (got '$url')." }
if ($url -ne "https://$ref.supabase.co") { Fail "SCHEDIEL_SUPABASE_PROJECT_REF '$ref' does not match SCHEDIEL_SUPABASE_URL." }
if ($key -notmatch '^sb_publishable_') { Fail 'SCHEDIEL_SUPABASE_KEY must be the publishable key (sb_publishable_...).' }
if ($shareHost -notmatch '^[a-z0-9-]+(\.[a-z0-9-]+)+$') { Fail "SCHEDIEL_SHARE_HOST must be a bare host name like name.vercel.app (got '$shareHost')." }
if (-not $vercelProject) { Fail 'SCHEDIEL_VERCEL_PROJECT is empty.' }

# --- 1. database --------------------------------------------------------------
Push-Location $backend
try {
  if (-not $SkipDatabase) {
    Step "Linking Supabase project $ref (enter the database password when asked)"
    Run { npx --yes supabase link --project-ref $ref }
    Step 'Pushing the sharing migration'
    Run { npx --yes supabase db push }
    Run { npx --yes supabase migration list }
  }

  # --- 2. secrets -------------------------------------------------------------
  if (-not $SkipSecrets) {
    Step 'Setting function secrets'
    $existing = (npx --yes supabase secrets list --project-ref $ref 2>$null) -join "`n"
    $lines = @(
      "SCHEDIEL_ALLOWED_ORIGINS=https://$shareHost",
      "SCHEDIEL_TRUSTED_IP_HEADER=$IpHeader",
      'SCHEDIEL_TRUST_PROXY_HEADERS=true'
    )
    if ($RotateRateSecret -or $existing -notmatch 'SCHEDIEL_RATE_HASH_SECRET') {
      $bytes = New-Object byte[] 48
      [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
      $lines += 'SCHEDIEL_RATE_HASH_SECRET=' + [Convert]::ToBase64String($bytes)
    } else {
      Write-Host 'SCHEDIEL_RATE_HASH_SECRET already set; keeping it (use -RotateRateSecret to replace).'
    }
    if ($DatabaseCaPath) {
      if (-not (Test-Path $DatabaseCaPath)) { Fail "Certificate not found: $DatabaseCaPath" }
      $pem = (Get-Content $DatabaseCaPath -Raw).Trim() -replace "`r", ''
      if ($pem -notmatch '^-----BEGIN CERTIFICATE-----') { Fail 'The database certificate must be a PEM file (-----BEGIN CERTIFICATE-----).' }
      $lines += 'SCHEDIEL_DATABASE_CA="' + ($pem -replace "`n", '\n') + '"'
    } elseif ($existing -notmatch 'SCHEDIEL_DATABASE_CA') {
      Write-Host 'WARNING: no -DatabaseCaPath given and SCHEDIEL_DATABASE_CA is not set; functions may fail to reach the database (503).' -ForegroundColor Yellow
    }
    # A temporary env file keeps values off the command line; removed right after.
    $tmp = [System.IO.Path]::GetTempFileName()
    try {
      [System.IO.File]::WriteAllText($tmp, ($lines -join "`n") + "`n")
      Run { npx --yes supabase secrets set --project-ref $ref --env-file $tmp }
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    Run { npx --yes supabase secrets list --project-ref $ref }
  }

  # --- 3. functions -----------------------------------------------------------
  if (-not $SkipFunctions) {
    Step 'Deploying edge functions'
    Run { npx --yes supabase functions deploy share-links share-resolve privacy health scan --project-ref $ref --use-api }
  }
} finally { Pop-Location }

Step 'Probing the backend'
$headers = @{ apikey = $key }
try {
  $health = Invoke-WebRequest -UseBasicParsing -Uri "$url/functions/v1/health" -Headers $headers
  Write-Host "health: $($health.StatusCode) $($health.Content)"
} catch { Fail "GET /functions/v1/health failed: $($_.Exception.Message)" }
# An unknown link must give 404. 503 means the database or the client-IP header is wrong.
$probe = @{ shareId = [guid]::NewGuid().ToString(); token = ('A' * 43); supportedSchemaVersions = @('1') } | ConvertTo-Json
try {
  Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$url/functions/v1/share-resolve" -Headers $headers -ContentType 'application/json' -Body $probe | Out-Null
  Write-Host 'share-resolve: unexpected success for an unknown link' -ForegroundColor Yellow
} catch {
  $code = [int]$_.Exception.Response.StatusCode
  if ($code -eq 404) { Write-Host 'share-resolve: 404 for an unknown link (database and client-IP header OK)' }
  elseif ($code -eq 503) {
    Write-Host 'share-resolve: 503. Either the database connection failed (pass -DatabaseCaPath with the certificate from Dashboard > Database > Settings > SSL Configuration) or the client-IP header is wrong (re-run with -SkipDatabase -SkipFunctions -IpHeader x-forwarded-for).' -ForegroundColor Yellow
  } else { Write-Host "share-resolve: unexpected status $code" -ForegroundColor Yellow }
}

# --- 4. share page ------------------------------------------------------------
if (-not $SkipWeb) {
  Step 'Building the share page'
  $env:SCHEDIEL_API_BASE = "$url/functions/v1"
  $env:SCHEDIEL_SHARE_HOST = "https://$shareHost"
  $env:SCHEDIEL_PUBLISHABLE_KEY = $key
  Remove-Item Env:ANDROID_CERT_SHA256 -ErrorAction SilentlyContinue
  $keyProps = Join-Path $repo 'android\key.properties'
  if (Test-Path $keyProps) {
    $props = @{}
    foreach ($line in Get-Content $keyProps) { if ($line -match '^\s*([^#=]+?)\s*=\s*(.*)$') { $props[$matches[1]] = $matches[2] } }
    $store = $props['storeFile']
    if (-not [System.IO.Path]::IsPathRooted($store)) { $store = Join-Path (Join-Path $repo 'android') $store }
    $keytool = (Get-Command keytool -ErrorAction SilentlyContinue).Source
    if (-not $keytool) { $keytool = 'C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe' }
    if (-not (Test-Path $keytool)) { Fail 'keytool not found: add Java (or Android Studio\jbr\bin) to PATH.' }
    $env:SCHEDIEL_STOREPASS = $props['storePassword']
    try {
      $listing = (& $keytool -list -v -keystore $store -alias $props['keyAlias'] -storepass:env SCHEDIEL_STOREPASS) -join "`n"
    } finally { Remove-Item Env:SCHEDIEL_STOREPASS -ErrorAction SilentlyContinue }
    if ($listing -match 'SHA256:\s*([0-9A-F:]{95})') {
      $env:ANDROID_CERT_SHA256 = $matches[1]
      Write-Host "Release key fingerprint: $($matches[1])"
    } else { Fail 'Could not read the SHA-256 fingerprint from the release keystore.' }
  } else {
    Write-Host 'WARNING: android\key.properties not found, so no assetlinks.json: shared links will open the browser page, not the app. Create the release key first (README "Release signing").' -ForegroundColor Yellow
  }
  Push-Location $web
  try { Run { node scripts/configure.mjs --out $dist } } finally { Pop-Location }

  Step "Deploying to Vercel project $vercelProject"
  Push-Location $dist
  try {
    npx --yes vercel project add $vercelProject 2>$null | Out-Null  # fine if it already exists
    Run { npx --yes vercel link --yes --project $vercelProject }
    Run { npx --yes vercel deploy --prod --yes }
  } finally { Pop-Location }

  Step 'Checking the share page'
  foreach ($path in @('/s/', '/.well-known/assetlinks.json')) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri "https://$shareHost$path"
      Write-Host "https://$shareHost$path -> $($r.StatusCode)"
    } catch {
      Write-Host "https://$shareHost$path -> $($_.Exception.Message). If Vercel gave the project a different domain, put that domain in SCHEDIEL_SHARE_HOST and run again with -SkipDatabase -SkipFunctions." -ForegroundColor Yellow
    }
  }
}

Step 'Done. Build the app with sharing:'
Write-Host '  flutter build apk --release --split-per-abi --dart-define-from-file=env/sharing.json'
Write-Host '  adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
