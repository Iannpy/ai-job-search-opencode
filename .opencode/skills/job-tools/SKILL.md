---
name: job-tools
description: "Wrapper for job search CLI tools (linkedin-search, freehire-search) running via Bun. Trigger: linkedin jobs, freehire jobs, run scraper, job scraper CLI"
---

# Job Search CLI Tools

This skill wraps the Bun-based CLI scrapers in `.agents/skills/`.

## Available Tools

### linkedin-search
Location: `.agents/skills/linkedin-search/`
- Built on LinkedIn's public jobs-guest endpoints
- Zero runtime dependencies (runs with `bun`)
- Usage: `bun run .agents/skills/linkedin-search/cli/src/cli.ts search -k "<keywords>" -l "<location>" --format json`
- Country-agnostic via `-l` flag (e.g. `-l "Buenos Aires, Argentina"`, `-l "Remote"`)
- Intended for **personal use only** - automated access is against LinkedIn ToS

### freehire-search
Location: `.agents/skills/freehire-search/`
- Queries freehire.dev public REST API (JSON, no API key)
- Tech-focused: software, data, engineering, DevOps, remote
- Zero runtime dependencies
- Usage: `bun run .agents/skills/freehire-search/cli/src/cli.ts search --keywords "<terms>" --format json`
- Multi-market via facet flags (`--region`, `--country`, `--remote`)

## Running a Search

Each tool's full interface is documented in its own `SKILL.md` under `.agents/skills/<tool-name>/SKILL.md`.
Always read that file before invoking - do not guess flags.

Common pattern:
```bash
bun run .agents/skills/<tool-name>/cli/src/cli.ts search -k "<keywords>" --format json --limit 20
```
