---
description: Analyze skill gaps between your profile and tracked job postings, generate learning plan
agent: job-assistant
---

# /job-upskill - Skill Gap Analysis

You are orchestrating a skill gap analysis. The user may optionally provide a job posting URL.

Read `.opencode/skills/job-search/01-candidate-profile.md` for the candidate's current skills.
Read `.opencode/skills/job-search/04-job-evaluation.md` for the evaluation framework.

If a URL is provided ($ARGUMENTS), fetch it and analyze gaps against that single posting.
Otherwise, scan `documents/applications/` for tracked postings and `job_scraper/seen_jobs.json` for scraped jobs.

Dispatch the job-upskill sub-agent via the Task tool for deep analysis.
Produce a prioritized heatmap of skill gaps and a learning plan with web-searched study resources and time estimates.
Save the report to `upskill/report_YYYY-MM-DD.md`.
