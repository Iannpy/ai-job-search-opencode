---
description: Search job portals for positions matching your profile using installed portal CLIs
agent: job-assistant
---

# /job-scrape - Search for Jobs

You are orchestrating a job search. Read `.opencode/skills/job-scraper/SKILL.md` and follow its execution steps exactly.

The user's optional argument ($ARGUMENTS) may be:
- A focus area, e.g. "data science" or "backend"
- "broad" to run all search categories

Read the search queries from `.opencode/skills/job-scraper/search-queries.md`.

Dispatch the job-scraper sub-agent via the Task tool to execute the searches in parallel, then present results to the user.
