# AI Job Search OpenCode - Windows Installer
# Copies commands and skills to ~/.config/opencode/
# Run from the repo root: .\install.ps1

$ErrorActionPreference = "Stop"
$OpencodeConfig = "$env:USERPROFILE\.config\opencode"
$RepoRoot = $PSScriptRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " AI Job Search OpenCode - Installer" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Verify dependencies
Write-Host "[1/4] Checking dependencies..." -ForegroundColor Yellow

$DepsOk = $true

try { bun --version 2>&1 | Out-Null } catch { Write-Host "  [WARN] bun not found - job scrapers won't work" -ForegroundColor Red; $DepsOk = $false }
try { python --version 2>&1 | Out-Null } catch { Write-Host "  [WARN] python not found - salary lookup won't work" -ForegroundColor Red; $DepsOk = $false }
try { lualatex --version 2>&1 | Out-Null } catch { Write-Host "  [WARN] lualatex not found - CV compilation won't work. Install MiKTeX or TeX Live." -ForegroundColor Red; $DepsOk = $false }
try { xelatex --version 2>&1 | Out-Null } catch { Write-Host "  [WARN] xelatex not found - cover letter compilation won't work" -ForegroundColor Red }
try { pdftotext -v 2>&1 | Out-Null } catch { Write-Host "  [INFO] pdftotext not found - ATS text verification will use degraded mode (install poppler for full support)" -ForegroundColor DarkYellow }

if ($DepsOk) { Write-Host "  All core dependencies found." -ForegroundColor Green }
Write-Host ""

# 2. Install Bun dependencies for CLI scrapers
Write-Host "[2/4] Installing Bun dependencies for scrapers..." -ForegroundColor Yellow

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

# 3. Copy commands and skills to opencode config
Write-Host "[3/4] Copying commands and skills to $OpencodeConfig..." -ForegroundColor Yellow

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

# 4. Register agents in opencode.json automatically
Write-Host "[4/4] Registering agents in opencode.json..." -ForegroundColor Yellow

$ConfigPath = "$OpencodeConfig\opencode.json"

if (-not (Test-Path $ConfigPath)) {
    Write-Host "  [ERROR] opencode.json not found at $ConfigPath" -ForegroundColor Red
    Write-Host "  Make sure OpenCode is installed and has been run at least once." -ForegroundColor Red
    exit 1
}

$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json -AsHashtable

if (-not $config.ContainsKey("agents")) {
    $config["agents"] = @{}
}

$newAgents = @{
    "job-assistant" = @{
        mode = "primary"
        prompt = "You are a job search assistant powered by AI Job Search OpenCode. Read .opencode/skills/job-search/SKILL.md and follow it exactly."
        tools = @{ bash = $true; edit = $true; read = $true; write = $true; delegate = $true }
    }
    "job-reviewer" = @{
        mode = "subagent"
        hidden = $true
        prompt = "{file:.opencode/skills/job-search/SKILL.md}"
        tools = @{ bash = $true; read = $true }
    }
    "job-scraper" = @{
        mode = "subagent"
        hidden = $true
        prompt = "{file:.opencode/skills/job-scraper/SKILL.md}"
        tools = @{ bash = $true; read = $true }
    }
    "job-upskill" = @{
        mode = "subagent"
        hidden = $true
        prompt = "{file:.opencode/skills/job-search/SKILL.md}"
        tools = @{ bash = $true; read = $true }
    }
}

$added = @()
$skipped = @()
foreach ($agentName in $newAgents.Keys) {
    if ($config.agents.ContainsKey($agentName)) {
        $skipped += $agentName
    } else {
        $config.agents[$agentName] = $newAgents[$agentName]
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
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Installation complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Next steps:" -ForegroundColor White
Write-Host "  1. Run /job-setup to build your profile" -ForegroundColor White
Write-Host "  2. Run /job-scrape to search for jobs" -ForegroundColor White
Write-Host "  3. Run /job-apply <url> to apply" -ForegroundColor White
Write-Host ""
