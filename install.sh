#!/usr/bin/env bash
# AI Job Search OpenCode - Unix Installer
# Run from the repo root: bash install.sh
# Installs all dependencies (except OpenCode), copies skills, registers agents.

set -euo pipefail

OPENCODE_CONFIG="${HOME}/.config/opencode"
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo " AI Job Search OpenCode - Installer"
echo "========================================"
echo ""

# ------------------------------------------------------------------
# 1. Install global dependencies
# ------------------------------------------------------------------
echo "[1/5] Installing dependencies..."

DETECTED_OS="$(uname -s)"

# Bun
if ! command -v bun >/dev/null 2>&1; then
    echo "  Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    export PATH="$HOME/.bun/bin:$PATH"
    echo "  Bun installed"
else
    echo "  bun: found"
fi

# Python
if ! command -v python3 >/dev/null 2>&1 && ! command -v python >/dev/null 2>&1; then
    echo "  Installing Python..."
    case "$DETECTED_OS" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then
                brew install python@3.12
            fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update -qq && sudo apt-get install -y -qq python3 python3-pip
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y python3 python3-pip
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm python python-pip
            fi
            ;;
    esac
    echo "  Python installed"
else
    echo "  python: found"
fi

# LaTeX
if ! command -v lualatex >/dev/null 2>&1; then
    echo "  Installing LaTeX..."
    case "$DETECTED_OS" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then
                brew install --cask mactex
            fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update -qq && sudo apt-get install -y -qq texlive-full
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y texlive-scheme-full
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm texlive-most
            fi
            ;;
    esac
    echo "  LaTeX installed (restart terminal if lualatex is not found)"
else
    echo "  lualatex: found"
fi

if ! command -v xelatex >/dev/null 2>&1; then
    echo "  [WARN] xelatex not found - cover letter compilation may fail"
else
    echo "  xelatex: found"
fi

# poppler (pdftotext) - optional
if ! command -v pdftotext >/dev/null 2>&1; then
    echo "  Installing poppler..."
    case "$DETECTED_OS" in
        Darwin)
            if command -v brew >/dev/null 2>&1; then
                brew install poppler
            fi
            ;;
        Linux)
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update -qq && sudo apt-get install -y -qq poppler-utils
            elif command -v dnf >/dev/null 2>&1; then
                sudo dnf install -y poppler-utils
            elif command -v pacman >/dev/null 2>&1; then
                sudo pacman -S --noconfirm poppler
            fi
            ;;
    esac
    echo "  poppler installed"
else
    echo "  pdftotext: found"
fi

echo ""

# ------------------------------------------------------------------
# 2. Install Bun dependencies for CLI scrapers
# ------------------------------------------------------------------
echo "[2/5] Installing Bun dependencies for scrapers..."

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

# ------------------------------------------------------------------
# 3. Copy commands and skills
# ------------------------------------------------------------------
echo "[3/5] Copying commands and skills to ${OPENCODE_CONFIG}..."

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

# ------------------------------------------------------------------
# 4. Register agents in opencode.json
# ------------------------------------------------------------------
echo "[4/5] Registering agents in opencode.json..."

CONFIG_PATH="${OPENCODE_CONFIG}/opencode.json"

if [ ! -f "$CONFIG_PATH" ]; then
    echo "  [ERROR] opencode.json not found at $CONFIG_PATH"
    echo "  Make sure OpenCode is installed (npm i -g opencode) and has been run at least once."
    exit 1
fi

python3 -c "
import json, sys

with open('$CONFIG_PATH') as f:
    config = json.load(f)

config.setdefault('agent', {})

new_agents = {
    'job-assistant': {
        'mode': 'primary',
        'prompt': 'You are a job search assistant powered by AI Job Search OpenCode. Read .opencode/skills/job-search/SKILL.md and follow it exactly.',
        'tools': {'bash': True, 'edit': True, 'read': True, 'write': True, 'delegate': True}
    },
    'job-reviewer': {
        'mode': 'subagent', 'hidden': True,
        'prompt': '{file:skills/job-search/SKILL.md}',
        'tools': {'bash': True, 'read': True}
    },
    'job-scraper': {
        'mode': 'subagent', 'hidden': True,
        'prompt': '{file:skills/job-scraper/SKILL.md}',
        'tools': {'bash': True, 'read': True}
    },
    'job-upskill': {
        'mode': 'subagent', 'hidden': True,
        'prompt': '{file:skills/job-search/SKILL.md}',
        'tools': {'bash': True, 'read': True}
    }
}

added = []
skipped = []
for name, agent in new_agents.items():
    if name in config['agent']:
        skipped.append(name)
    else:
        config['agent'][name] = agent
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

# ------------------------------------------------------------------
# 5. Done
# ------------------------------------------------------------------
echo "[5/5] Checking OpenCode..."

if ! command -v opencode >/dev/null 2>&1; then
    echo "  [ACTION REQUIRED] OpenCode CLI not found."
    echo "  Install it with: npm i -g opencode"
else
    echo "  opencode: found"
fi

echo ""
echo "========================================"
echo " All done!"
echo "========================================"
echo ""
echo "  Open a terminal here and run:"
echo "    opencode"
echo ""
echo "  Then:"
echo "    /job-setup"
echo ""
