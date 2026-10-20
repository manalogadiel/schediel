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
    4. build the share page (with assetlinks.json from your existing APK signing certificate)
       and deploy it to Vercel

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File tools\deploy_sharing.ps1 -DatabaseCaPath $HOME\Downloads\prod-ca-2021.crt
#>
param(
  [string]$DatabaseCaPath,
  [string]$AndroidCertSha256,
  [ValidateSet('x-real-ip', 'x-forwarded-for', 'cf-connecting-ip')]
  [string]$IpHeader = 'cf-connecting-ip',
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
$appLinkHost = "$($s.SCHEDIEL_APP_LINK_HOST)"

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
    Run { npx --yes supabase link --project-ref $ref --agent no --output-format text }
    Step 'Pushing the sharing migration'
    Run { npx --yes supabase db push --yes --agent no --output-format text }
    Run { npx --yes supabase migration list }
  }

  # --- 2. secrets -------------------------------------------------------------
  if (-not $SkipSecrets) {
    Step 'Setting function secrets'
    $existing = (npx --yes supabase secrets list --project-ref $ref 2>$null) -join "`n"
    $lines = @(
      "SCHEDIEL_ALLOWED_ORIGINS=$((@("https://$shareHost") + $(if ($appLinkHost) { "https://$appLinkHost" })) -join ',')",
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
    Write-Host 'Server secret configuration updated (values hidden).'
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
$probe = @{ shareId = [guid]::NewGuid().ToString(); token = ('A' * 43); supportedSchemaVersions = @('1.0') } | ConvertTo-Json
try {
  Invoke-WebRequest -UseBasicParsing -Method Post -Uri "$url/functions/v1/share-resolve" -Headers $headers -ContentType 'application/json' -Body $probe | Out-Null
  Fail 'share-resolve unexpectedly accepted an unknown link.'
} catch {
  $code = [int]$_.Exception.Response.StatusCode
  if ($code -eq 404) { Write-Host 'share-resolve: 404 for an unknown link (database and client-IP header OK)' }
  elseif ($code -eq 503) {
    Fail 'share-resolve: 503. Verify the database certificate and ingress address policy before changing the trusted header.'
  } else { Fail "share-resolve returned unexpected status $code" }
}

# --- 4. share page ------------------------------------------------------------
if (-not $SkipWeb) {
  Step 'Building the share page'
  $env:SCHEDIEL_API_BASE = "$url/functions/v1"
  $env:SCHEDIEL_SHARE_HOST = "https://$shareHost"
  $env:SCHEDIEL_PUBLISHABLE_KEY = $key
  $env:SCHEDIEL_APP_LINK_ORIGIN = if ($appLinkHost) { "https://$appLinkHost" } else { '' }
  Remove-Item Env:ANDROID_CERT_SHA256 -ErrorAction SilentlyContinue
  # Use the certificate of the actual APK, including this PC's existing debug
  # key. A new release key would prevent updating the user's installed app.
  if (-not $AndroidCertSha256) { Fail 'Pass -AndroidCertSha256 from the APK that will be installed. No new signing key is needed.' }
  if ($AndroidCertSha256 -notmatch '^(?:[0-9A-Fa-f]{2}:){31}[0-9A-Fa-f]{2}$') { Fail 'Invalid signing certificate SHA-256 fingerprint.' }
  $env:ANDROID_CERT_SHA256 = $AndroidCertSha256
  Write-Host 'Using the existing APK signing certificate for Android App Links.'
  Push-Location $web
  try { Run { node scripts/configure.mjs --out $dist } } finally { Pop-Location }

  Step "Deploying to Vercel project $vercelProject"
  Push-Location $dist
  try {
    npx --yes vercel project add $vercelProject 2>$null | Out-Null  # fine if it already exists
    Run { npx --yes vercel link --yes --project $vercelProject }
    Run { npx --yes vercel deploy --prod --yes }
    if ($appLinkHost) {
      # An alias alone remains a protected preview URL. Register it as a
      # production domain so Android can fetch assetlinks without a login.
      Run { npx --yes vercel domains add $appLinkHost $vercelProject }
      Run { npx --yes vercel alias set $shareHost $appLinkHost }
    }
  } finally { Pop-Location }

  Step 'Checking the share page'
  foreach ($hostName in @($shareHost, $appLinkHost) | Where-Object { $_ }) {
  foreach ($path in @('/s/', '/.well-known/assetlinks.json')) {
    try {
      $r = Invoke-WebRequest -UseBasicParsing -Uri "https://$hostName$path" -MaximumRedirection 0
      Write-Host "https://$hostName$path -> $($r.StatusCode)"
    } catch {
      Fail "https://$hostName$path must be public without redirects. Check the production domain assignment."
    }
  }
  }
}

Step 'Done. Build the app with sharing:'
Write-Host '  flutter build apk --release --split-per-abi --dart-define-from-file=env/sharing.json'
Write-Host '  adb install -r build\app\outputs\flutter-apk\app-arm64-v8a-release.apk'
