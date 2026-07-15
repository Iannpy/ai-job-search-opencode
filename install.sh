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

# 4. Register agents in opencode.json automatically
echo "[4/4] Registering agents in opencode.json..."

CONFIG_PATH="${OPENCODE_CONFIG}/opencode.json"

if [ ! -f "$CONFIG_PATH" ]; then
    echo "  [ERROR] opencode.json not found at $CONFIG_PATH"
    echo "  Make sure OpenCode is installed and has been run at least once."
    exit 1
fi

# Use python to merge agents (available on all platforms)
python3 -c "
import json, sys

with open('$CONFIG_PATH') as f:
    config = json.load(f)

config.setdefault('agents', {})

new_agents = {
    'job-assistant': {
        'mode': 'primary',
        'prompt': 'You are a job search assistant powered by AI Job Search OpenCode. Read .opencode/skills/job-search/SKILL.md and follow it exactly.',
        'tools': {'bash': True, 'edit': True, 'read': True, 'write': True, 'delegate': True}
    },
    'job-reviewer': {
        'mode': 'subagent', 'hidden': True,
        'prompt': '{file:.opencode/skills/job-search/SKILL.md}',
        'tools': {'bash': True, 'read': True}
    },
    'job-scraper': {
        'mode': 'subagent', 'hidden': True,
        'prompt': '{file:.opencode/skills/job-scraper/SKILL.md}',
        'tools': {'bash': True, 'read': True}
    },
    'job-upskill': {
        'mode': 'subagent', 'hidden': True,
        'prompt': '{file:.opencode/skills/job-search/SKILL.md}',
        'tools': {'bash': True, 'read': True}
    }
}

added = []
skipped = []
for name, agent in new_agents.items():
    if name in config['agents']:
        skipped.append(name)
    else:
        config['agents'][name] = agent
        added.append(name)

with open('$CONFIG_PATH', 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

for a in added:
    print(f'  Registered: {a}')
for s in skipped:
    print(f'  Skipped (already exists): {s}')
"

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
