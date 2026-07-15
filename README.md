# AI Job Search OpenCode

*The job search that runs on your machine - now for OpenCode.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

An AI-powered job application framework built on [OpenCode](https://opencode.ai). Fork it, fill in your profile, and let OpenCode evaluate job postings, tailor your CV, write cover letters, and prepare you for interviews.

> **This is a community fork** of [MadsLorentzen/ai-job-search](https://github.com/MadsLorentzen/ai-job-search), adapted from Claude Code to OpenCode. All credit for the original framework goes to [Mads Lorentzen](https://github.com/MadsLorentzen).

## What this is

A structured workflow that turns OpenCode into a full-stack job application assistant:

```
/job-setup       /job-scrape           /job-apply <url>
    |                |                      |
    v                v                      v
Fill in         Search job             Evaluate fit
your profile    portals                Score & recommend
    |                |                      |
    v                v                      v
Profile         Present matches        Draft CV + Cover Letter
files ready     with fit ratings       (LaTeX, tailored)
                     |                      |
                     v                      v
                 Pick a match          Reviewer agent critiques
                 -> /job-apply         -> Revise -> Compile PDF
```

## Prerequisites

- [OpenCode](https://opencode.ai) CLI
- Python 3.10+
- [Bun](https://bun.sh) (for job search CLI tools)
- LaTeX distribution: [MiKTeX](https://miktex.org) (Windows), [MacTeX](https://tug.org/mactex/) (macOS), or [TeX Live](https://tug.org/texlive/) (Linux)
- Optional: `pdftotext` from [poppler](https://poppler.freedesktop.org/) for ATS verification

## Quick Start

### 1. Fork and clone

```bash
gh repo fork <your-username>/ai-job-search-opencode --clone
cd ai-job-search-opencode
```

### 2. Install

**Windows (PowerShell):**
```powershell
.\install.ps1
```

**macOS / Linux:**
```bash
bash install.sh
```

Then add the agent block printed at the end to your `~/.config/opencode/opencode.json`.

### 3. Set up your profile

```
/job-setup
```

Three paths: point it at your `documents/` folder, paste a CV, or walk through an interview.

### 4. Search for jobs

```
/job-scrape
```

### 5. Apply to a job

```
/job-apply https://example.com/job-posting
```

## Commands

| Command | Description |
|---------|-------------|
| `/job-setup` | Build your professional profile |
| `/job-scrape` | Search job portals for matches |
| `/job-apply <url\|text>` | Full application workflow (evaluate, draft, review, compile PDF) |
| `/job-rank` | Batch-score scraped postings |
| `/job-interview` | Stage-specific interview prep |
| `/job-outcome` | Track application results |
| `/job-expand` | Enrich profile from public sources |
| `/job-upskill` | Skill gap analysis + learning plan |
| `/job-reset` | Wipe profile or documents |

## Market Support

- **linkedin-search**: Global, any market via `-l` flag
- **freehire-search**: Tech jobs, multi-market
- Add your local portals by contributing CLI scrapers to `.agents/skills/`

## Differences from the Original

This fork adapts the Claude Code framework to OpenCode:
- Claude Code commands replaced with OpenCode slash commands (`/job-*`)
- `.claude/` directory replaced with `.opencode/` directory
- `CLAUDE.md` replaced with `AGENTS.md`
- Danish portal scrapers removed (kept linkedin-search + freehire-search for global use)
- `/add-template` and `/add-portal` deferred to future release

## License

MIT - same as the original.

## Acknowledgements

- [Mads Lorentzen](https://github.com/MadsLorentzen) for the original [ai-job-search](https://github.com/MadsLorentzen/ai-job-search) framework
- [Mikkel Krogholm](https://github.com/mikkelkrogsholm) for the job search CLI skills
- Built with [OpenCode](https://opencode.ai)
