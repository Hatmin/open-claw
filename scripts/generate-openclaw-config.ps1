# Genera config/openclaw.json desde .env
# Uso: .\scripts\generate-openclaw-config.ps1
# Requiere: .env en la raíz del proyecto (copiar desde .env.example)

$ErrorActionPreference = "Stop"
$root = Split-Path $PSScriptRoot -Parent
$envPath = Join-Path $root ".env"
$templatePath = Join-Path $root "config\openclaw.json.template"
$outPath = Join-Path $root "config\openclaw.json"

if (-not (Test-Path $envPath)) {
    Write-Error "No existe .env. Copia .env.example a .env y rellena los valores."
    exit 1
}
if (-not (Test-Path $templatePath)) {
    Write-Error "No existe config\openclaw.json.template"
    exit 1
}

# Parse .env (líneas KEY=VALUE, sin comentarios)
$vars = @{}
Get-Content $envPath -Encoding UTF8 | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith("#")) {
        $idx = $line.IndexOf("=")
        if ($idx -gt 0) {
            $key = $line.Substring(0, $idx).Trim()
            $val = $line.Substring($idx + 1).Trim().Trim('"').Trim("'")
            $vars[$key] = $val
        }
    }
}

# Escapar para JSON: \ -> \\, " -> \"
function Escape-JsonString { param([string]$s); ($s -replace '\\', '\\\\' -replace '"', '\"') }
$telegramToken = if ($vars["TELEGRAM_BOT_TOKEN"]) { Escape-JsonString $vars["TELEGRAM_BOT_TOKEN"] } else { "" }
$gatewayToken = if ($vars["OPENCLAW_GATEWAY_TOKEN"]) { $vars["OPENCLAW_GATEWAY_TOKEN"] } else { (New-Guid).Guid }
$allowFromRaw = if ($vars["OPENCLAW_ALLOW_FROM"]) { $vars["OPENCLAW_ALLOW_FROM"] } else { "" }
# Convertir "123,456" -> ["123","456"]
$allowFromJson = if ($allowFromRaw) {
    $ids = $allowFromRaw -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    "[" + (($ids | ForEach-Object { "`"$_`"" }) -join ",") + "]"
} else { "[]" }

$template = Get-Content $templatePath -Raw -Encoding UTF8
$template = $template -replace "__TELEGRAM_BOT_TOKEN__", $telegramToken
$template = $template -replace "__OPENCLAW_GATEWAY_TOKEN__", $gatewayToken
$template = $template -replace "__OPENCLAW_ALLOW_FROM_JSON__", $allowFromJson

$configDir = Split-Path $outPath -Parent
if (-not (Test-Path $configDir)) { New-Item -ItemType Directory -Path $configDir -Force | Out-Null }
Set-Content -Path $outPath -Value $template -Encoding UTF8 -NoNewline
Write-Host "Config generado: config\openclaw.json"
