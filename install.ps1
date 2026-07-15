# AI Job Search OpenCode - Windows Installer
# Run from the repo root: .\install.ps1
# Installs all dependencies (except OpenCode), copies skills, registers agents.

$ErrorActionPreference = "Stop"
$OpencodeConfig = "$env:USERPROFILE\.config\opencode"
$RepoRoot = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " AI Job Search OpenCode - Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

function Test-Command($cmd) {
    try { Get-Command $cmd -ErrorAction Stop 2>&1 | Out-Null; return $true } catch { return $false }
}

# ------------------------------------------------------------------
# 1. Install global dependencies
# ------------------------------------------------------------------
Write-Host "[1/5] Installing dependencies..." -ForegroundColor Yellow

$missing = @()

# Bun
if (-not (Test-Command "bun")) {
    $missing += "bun"
    Write-Host "  Installing Bun..." -ForegroundColor DarkYellow
    irm bun.sh/install.ps1 | iex
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Host "  Bun installed" -ForegroundColor Green
} else {
    Write-Host "  bun: found" -ForegroundColor Green
}

# Python
if (-not (Test-Command "python")) {
    $missing += "python"
    Write-Host "  Installing Python 3.12..." -ForegroundColor DarkYellow
    winget install Python.Python.3.12 --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Host "  Python installed (restart terminal if python is not found)" -ForegroundColor Green
} else {
    Write-Host "  python: found" -ForegroundColor Green
}

# MiKTeX (LaTeX)
if (-not (Test-Command "lualatex")) {
    $missing += "miktex"
    Write-Host "  Installing MiKTeX (~1 GB, this may take a while)..." -ForegroundColor DarkYellow
    winget install MiKTeX.MiKTeX --accept-source-agreements --accept-package-agreements
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Host "  MiKTeX installed (restart terminal if lualatex is not found)" -ForegroundColor Green
} else {
    Write-Host "  lualatex: found" -ForegroundColor Green
}

if (-not (Test-Command "xelatex")) {
    Write-Host "  [WARN] xelatex not found - cover letter compilation may fail" -ForegroundColor Red
} else {
    Write-Host "  xelatex: found" -ForegroundColor Green
}

# poppler (pdftotext) - optional
if (-not (Test-Command "pdftotext")) {
    Write-Host "  Installing poppler (pdftotext)..." -ForegroundColor DarkYellow
    winget install "poppler" --accept-source-agreements --accept-package-agreements --silent
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "User") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    Write-Host "  poppler installed (restart terminal if pdftotext is not found)" -ForegroundColor Green
} else {
    Write-Host "  pdftotext: found" -ForegroundColor Green
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "  Some tools were just installed. If commands are not found," -ForegroundColor Yellow
    Write-Host "  close and reopen your terminal, then re-run this script." -ForegroundColor Yellow
}
Write-Host ""

# ------------------------------------------------------------------
# 2. Install Bun dependencies for CLI scrapers
# ------------------------------------------------------------------
Write-Host "[2/5] Installing Bun dependencies for scrapers..." -ForegroundColor Yellow

$ScraperDirs = @("linkedin-search", "freehire-search")
foreach ($dir in $ScraperDirs) {
    $cliPath = "$RepoRoot\.agents\skills\$dir\cli"
    if (Test-Path "$cliPath\package.json") {
        Push-Location $cliPath
        bun install --silent
        Pop-Location
        Write-Host "  $dir - OK" -ForegroundColor Green
    } else {
        Write-Host "  $dir - no deps (runs with plain bun)" -ForegroundColor DarkYellow
    }
}
Write-Host ""

# ------------------------------------------------------------------
# 3. Copy commands and skills to opencode config
# ------------------------------------------------------------------
Write-Host "[3/5] Copying commands and skills to $OpencodeConfig..." -ForegroundColor Yellow

New-Item -ItemType Directory -Force -Path "$OpencodeConfig\commands" | Out-Null
New-Item -ItemType Directory -Force -Path "$OpencodeConfig\skills" | Out-Null

$CommandSource = "$RepoRoot\.opencode\commands"
Get-ChildItem "$CommandSource\*.md" | ForEach-Object {
    Copy-Item $_.FullName -Destination "$OpencodeConfig\commands\" -Force
    Write-Host "  Command: $($_.Name)" -ForegroundColor Green
}

$SkillDirs = @("job-search", "job-scraper", "job-tools")
foreach ($dir in $SkillDirs) {
    $src = "$RepoRoot\.opencode\skills\$dir"
    $dst = "$OpencodeConfig\skills\$dir"
    if (Test-Path $dst) { Remove-Item -Recurse -Force $dst }
    Copy-Item -Recurse $src -Destination $dst
    Write-Host "  Skill: $dir" -ForegroundColor Green
}
Write-Host ""

# ------------------------------------------------------------------
# 4. Register agents in opencode.json
# ------------------------------------------------------------------
Write-Host "[4/5] Registering agents in opencode.json..." -ForegroundColor Yellow

$ConfigPath = "$OpencodeConfig\opencode.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "  [ERROR] opencode.json not found at $ConfigPath" -ForegroundColor Red
    Write-Host "  Make sure OpenCode is installed (npm i -g opencode) and has been run at least once." -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json

$newAgents = @{
    "job-assistant" = [PSCustomObject]@{
        mode = "primary"
        prompt = "{file:skills/job-search/SKILL.md}"
        tools = [PSCustomObject]@{ bash = $true; edit = $true; read = $true; write = $true; delegate = $true }
    }
    "job-reviewer" = [PSCustomObject]@{
        mode = "subagent"
        hidden = $true
        prompt = "{file:skills/job-search/SKILL.md}"
        tools = [PSCustomObject]@{ bash = $true; read = $true }
    }
    "job-scraper" = [PSCustomObject]@{
        mode = "subagent"
        hidden = $true
        prompt = "{file:skills/job-scraper/SKILL.md}"
        tools = [PSCustomObject]@{ bash = $true; read = $true }
    }
    "job-upskill" = [PSCustomObject]@{
        mode = "subagent"
        hidden = $true
        prompt = "{file:skills/job-search/SKILL.md}"
        tools = [PSCustomObject]@{ bash = $true; read = $true }
    }
}

# Ensure agents property exists
if (-not ($config | Get-Member -Name "agents" -MemberType NoteProperty)) {
    $config | Add-Member -MemberType NoteProperty -Name "agents" -Value ([PSCustomObject]@{})
}

$added = @()
$skipped = @()

foreach ($agentName in $newAgents.Keys) {
    $existing = $config.agents | Get-Member -MemberType NoteProperty -Name $agentName -ErrorAction SilentlyContinue
    if ($existing) {
        $skipped += $agentName
    } else {
        $config.agents | Add-Member -MemberType NoteProperty -Name $agentName -Value $newAgents[$agentName]
        $added += $agentName
    }
}

if ($added.Count -gt 0) {
    $json = $config | ConvertTo-Json -Depth 10
    Set-Content $ConfigPath -Value $json -NoNewline
    foreach ($a in $added) { Write-Host "  Registered: $a" -ForegroundColor Green }
}
if ($skipped.Count -gt 0) {
    foreach ($s in $skipped) { Write-Host "  Skipped (already exists): $s" -ForegroundColor DarkYellow }
}

Write-Host ""

# ------------------------------------------------------------------
# 5. Done
# ------------------------------------------------------------------
Write-Host "[5/5] Checking OpenCode..." -ForegroundColor Yellow

if (-not (Test-Command "opencode")) {
    Write-Host "  [ACTION REQUIRED] OpenCode CLI not found." -ForegroundColor Yellow
    Write-Host "  Install it with: npm i -g opencode" -ForegroundColor White
} else {
    Write-Host "  opencode: found" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " All done!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Open a terminal here and run:" -ForegroundColor White
Write-Host "    opencode" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Then:" -ForegroundColor White
Write-Host "    /job-setup" -ForegroundColor Cyan
Write-Host ""
