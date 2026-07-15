#!/usr/bin/env bash
# AI Job Search OpenCode - Unix Installer
# Copies commands and skills to ~/.config/opencode/
# Run from the repo root: bash install.sh

set -euo pipefail

OPENCODE_CONFIG="${HOME}/.config/opencode"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo " AI Job Search OpenCode - Installer"
echo "========================================"
echo ""

# 1. Verify dependencies
echo "[1/4] Checking dependencies..."

DEPS_OK=true

command -v bun >/dev/null 2>&1 || { echo "  [WARN] bun not found - job scrapers won't work"; DEPS_OK=false; }
command -v python3 >/dev/null 2>&1 || command -v python >/dev/null 2>&1 || { echo "  [WARN] python not found - salary lookup won't work"; DEPS_OK=false; }
command -v lualatex >/dev/null 2>&1 || { echo "  [WARN] lualatex not found - CV compilation won't work. Install TeX Live or MacTeX."; DEPS_OK=false; }
command -v xelatex >/dev/null 2>&1 || { echo "  [WARN] xelatex not found - cover letter compilation won't work"; }
command -v pdftotext >/dev/null 2>&1 || { echo "  [INFO] pdftotext not found - ATS text verification will use degraded mode (install poppler for full support)"; }

if $DEPS_OK; then echo "  All core dependencies found."; fi
echo ""

# 2. Install Bun dependencies for CLI scrapers
echo "[2/4] Installing Bun dependencies for scrapers..."

for dir in linkedin-search freehire-search; do
    cli_path="${REPO_ROOT}/.agents/skills/${dir}/cli"
    if [ -f "${cli_path}/package.json" ]; then
        (cd "$cli_path" && bun install --silent)
        echo "  $dir - OK"
    else
        echo "  $dir - no deps (runs with plain bun)"
    fi
done
echo ""

# 3. Copy commands and skills
echo "[3/4] Copying commands and skills to ${OPENCODE_CONFIG}..."

mkdir -p "${OPENCODE_CONFIG}/commands"
mkdir -p "${OPENCODE_CONFIG}/skills"

for cmd in "${REPO_ROOT}/.opencode/commands"/*.md; do
    cp "$cmd" "${OPENCODE_CONFIG}/commands/"
    echo "  Command: $(basename "$cmd")"
done

for dir in job-search job-scraper job-tools; do
    rm -rf "${OPENCODE_CONFIG}/skills/${dir}"
    cp -r "${REPO_ROOT}/.opencode/skills/${dir}" "${OPENCODE_CONFIG}/skills/${dir}"
    echo "  Skill: ${dir}"
done
echo ""

# 4. Agent registration instructions
echo "[4/4] Agent registration"
echo ""
echo "  Add the job-* agents to your opencode.json manually,"
echo "  or run this repo with opencode and the skill will self-register via AGENTS.md."
echo ""
echo "========================================"
echo " Installation complete!"
echo "========================================"
echo ""
echo "  Next steps:"
echo "  1. Run /job-setup to build your profile"
echo "  2. Run /job-scrape to search for jobs"
echo "  3. Run /job-apply <url> to apply"
echo ""
