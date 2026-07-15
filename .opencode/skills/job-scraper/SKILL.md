---
name: job-scraper
description: "Search job portals for positions matching your profile using Bun CLI tools. Trigger: job scrape, find jobs, search jobs, new jobs, scrape jobs, /job-scrape"
---

# Job Scraper

## How It Works

This skill searches job portals using the **installed portal-search CLIs** in
`.agents/skills/` (plus WebSearch as a fallback), using queries from your profile.
It deduplicates against previously seen jobs and the application tracker, and
presents new matches with a quick fit assessment.

## Invocation

The user triggers this skill via `/job-scrape` or phrases like:
- "Find new jobs"
- "Scrape for jobs"
- "Any new positions?"

Optional arguments:
- A focus area, e.g. "/job-scrape data science" or "/job-scrape backend"
- "broad" to run all search categories

## Execution Steps

### Step 0: Load State

1. Read `job_scraper/seen_jobs.json` (create if missing - start with `{"seen": {}}`)
2. Read `job_search_tracker.csv` to extract already-applied companies+roles
3. Read `search-queries.md` for the search strategy

### Step 1: Search

Read `search-queries.md` for the search strategy. By default, run the top 3 priority query categories. If the user said "broad", run all categories. If the user specified a focus area (e.g. "data science"), prioritize queries from that category.

**Use the installed CLI tools as the primary search mechanism.** Fall back to `WebSearch` only for portals that do not have a CLI skill, or if `bun` is unavailable.

#### 1a. Check bun availability

```bash
bun --version
```

If this fails, skip to **1c (WebSearch fallback)** and note the fallback in output.

#### 1b. Run CLI tools

Discover installed portal CLI skills under `.agents/skills/*/SKILL.md`. For each enabled portal:
1. Read its SKILL.md for CLI invocation
2. Translate query terms from search-queries.md into that portal's flags
3. Scope to last 14 days using the portal's recency flag
4. Cap at ~20 results per call
5. Use `--format json`

Run portal CLI calls in parallel. Collect all results into a single pool.

If a CLI tool exits with a non-zero code, log the error and continue.

#### 1c. WebSearch fallback

Use WebSearch for portals without CLI skills or when bun is unavailable.

### Step 2: Fetch & Parse

For each promising result, fetch full details. Skip if URL or company+title combo exists in seen_jobs.json or tracker.

### Step 3: Quick Fit Assessment

- **High match**: Role directly involves core skills
- **Medium match**: Role is adjacent to experience
- **Low match**: Role requires significant missing skills

### Step 4: Deduplicate & Store

Add all fetched jobs to `seen_jobs.json`:
```json
{
  "seen": {
    "<url_or_key>": {
      "title": "...",
      "company": "...",
      "url": "...",
      "first_seen": "YYYY-MM-DD",
      "fit": "high/medium/low",
      "status": "new/skipped/evaluated/ranked/expired"
    }
  }
}
```

### Step 4.5: Generate Referral Links (High & Medium Fit)

For each high/medium-fit job, build LinkedIn people-search URLs:
- Recruiters: `https://www.linkedin.com/search/results/people/?keywords=<url-encoded "Company recruiter">`
- Peers: `https://www.linkedin.com/search/results/people/?keywords=<url-encoded "Company role-keyword">`

Never scrape LinkedIn pages - these are search links for the user to open.

### Step 5: Present Results

```
## New Job Matches - YYYY-MM-DD

Found X new positions (Y high, Z medium, W low match).

| # | Fit | Title | Company | Location | Deadline | URL |
|---|-----|-------|---------|----------|----------|-----|

### High-Match Highlights
[2-3 bullets per high-match job]

### Contacts
[LinkedIn search links for high/medium-fit jobs]
```

Suggest `/job-rank` if 8+ new jobs found.

## Important Rules

1. **Never fabricate job postings.** Only present jobs from actual CLI/detail output or WebSearch/WebFetch results.
2. **Respect deduplication.** Always check seen_jobs.json AND tracker before presenting.
3. **Focus on configured geographic area.** Skip jobs requiring relocation or clearly outside commute range.
4. **Only open positions.** Skip postings with expired deadlines.
5. **Parallel searches.** Run portal CLI calls in parallel; use WebSearch only for gaps.
6. **No automated people lookups.** Referral contacts are LinkedIn search links only - never fetch or scrape LinkedIn people-search result pages programmatically.
