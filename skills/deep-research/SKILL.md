---
platform: portable
description: "Multi-source deep research using Exa, Firecrawl, and WebSearch/WebFetch. Searches the web with semantic and keyword search, scrapes JS-rendered pages, and delivers cited reports with source attribution. Use when the user wants thorough research on any topic with evidence and citations."
---

# /deep-research - Deep Research

Produce thorough, cited research reports from multiple web sources using a three-tier search and scrape stack.

## When to Activate

- User asks to research any topic in depth
- Competitive analysis, technology evaluation, or market sizing
- Due diligence on companies, investors, or technologies
- Any question requiring synthesis from multiple sources
- User says "research", "deep dive", "investigate", or "what's the current state of"

## Tool Stack (Three Tiers)

### Tier 1: Exa (MCP, semantic search)
Best for: complex queries, date-filtered results, LinkedIn, domain-scoped search.
- `web_search_exa` for semantic web search
- `web_search_advanced_exa` for date-filtered, domain-filtered search
- `crawling_exa` for full page content extraction (markdown)
- `linkedin_search` for people/company search on LinkedIn
- `get_code_context_exa` for GitHub, Stack Overflow, official docs

### Tier 2: Firecrawl (MCP, JS-rendered scraping)
Best for: JavaScript-heavy sites, full-site crawls, anti-bot bypass, structured extraction.
- `firecrawl_search` for web search with content extraction
- `firecrawl_scrape` for single URL scraping (renders JS, returns markdown)
- `firecrawl_crawl` for multi-page site crawling
- `firecrawl_map` for mapping site structure

### Tier 3: WebSearch + WebFetch (built-in, fallback)
Best for: quick lookups, simple pages, when MCP tools are unavailable.
- `WebSearch` for keyword search
- `WebFetch` for basic page fetching (no JS rendering)

### Tool Selection Strategy

1. **Start with Exa** for search queries (semantic search returns better results for research)
2. **Use Firecrawl** to scrape pages that need JS rendering or are behind light anti-bot protection
3. **Fall back to WebFetch** for simple static pages or if MCP tools error
4. **Use Exa's linkedin_search** specifically for LinkedIn content (WebFetch is blocked)
5. If an MCP tool is unavailable (server not running), fall back to the next tier silently

## Workflow

### Step 1: Understand the Goal

Ask 1-2 quick clarifying questions:
- "What's your goal: learning, making a decision, or writing something?"
- "Any specific angle or depth you want?"

If the user says "just research it," skip ahead with reasonable defaults.

### Step 2: Plan the Research

Break the topic into 3-5 research sub-questions. Example:
- Topic: "Impact of AI on healthcare"
  - What are the main AI applications in healthcare today?
  - What clinical outcomes have been measured?
  - What are the regulatory challenges?
  - What companies are leading this space?
  - What's the market size and growth trajectory?

### Step 3: Execute Multi-Source Search (Parallel)

Launch **parallel research agents** (model: haiku) for each sub-question cluster. Each agent:

1. Uses `web_search_exa` or `web_search_advanced_exa` with 2-3 keyword variations per sub-question
2. For date-sensitive topics, uses `startPublishedDate` to filter recent results
3. For domain-specific research, uses `includeDomains` to target authoritative sources
4. Collects 15-30 unique source URLs total across all agents
5. Prioritizes: academic, official, reputable news > blogs > forums

```
Launch 2-3 research agents in parallel:
  Agent 1 (haiku): Sub-questions 1-2 — Exa search + Firecrawl/Exa scrape key sources
  Agent 2 (haiku): Sub-questions 3-4 — Exa search + Firecrawl/Exa scrape key sources
  Agent 3 (haiku): Sub-question 5 + cross-cutting themes — Exa search + Firecrawl/Exa scrape
```

Each agent returns structured findings with source URLs and key excerpts.

### Step 4: Deep-Read Key Sources

For the most promising URLs from Step 3, fetch full content:

- **JS-heavy sites** (SPAs, dashboards, interactive pages): use `firecrawl_scrape(url: "<url>")`
- **Articles, blogs, docs**: use `crawling_exa(urls: ["<url>"], tokensNum: 5000)`
- **Simple static pages**: use `WebFetch` as fallback
- Read 3-5 key sources in full for depth
- Do not rely only on search snippets
- Extract specific data points, quotes, and statistics

### Step 5: Synthesize and Write Report

Structure the report:

```markdown
# [Topic]: Research Report
*Generated: [date] | Sources: [N] | Confidence: [High/Medium/Low]*

## Executive Summary
[3-5 sentence overview of key findings]

## 1. [First Major Theme]
[Findings with inline citations]
- Key point ([Source Name](url))
- Supporting data ([Source Name](url))

## 2. [Second Major Theme]
...

## 3. [Third Major Theme]
...

## Key Takeaways
- [Actionable insight 1]
- [Actionable insight 2]
- [Actionable insight 3]

## Sources
1. [Title](url) — [one-line summary]
2. ...

## Methodology
Searched [N] queries across Exa, Firecrawl, and web sources. Analyzed [M] sources in depth.
Tools used: [list which tiers were used]
Sub-questions investigated: [list]
```

### Step 6: Deliver

- **Short topics** (under 500 words): Post the full report in chat
- **Long reports**: Post executive summary + key takeaways in chat, save full report to `docs/research/[topic-slug]-[date].md`

### Step 7: Store to Vector Memory

After delivering the report, save a summary to vector memory:

```
memory_store:
  content: "[Topic] research completed. Key findings: [2-3 sentences]. [N] sources analyzed. Report saved to [path]."
  tags: ["deep-research", "[topic-keyword]", "[project-name]"]
```

## Quality Rules

1. **Every claim needs a source.** No unsourced assertions.
2. **Cross-reference.** If only one source says it, flag it as unverified.
3. **Recency matters.** Prefer sources from the last 12 months. Use Exa's date filtering.
4. **Acknowledge gaps.** If you could not find good info on a sub-question, say so.
5. **No hallucination.** If you do not know, say "insufficient data found."
6. **Separate fact from inference.** Label estimates, projections, and opinions clearly.

## Examples

```
"Research the current state of nuclear fusion energy"
"Deep dive into Rust vs Go for backend services in 2026"
"Research the best strategies for bootstrapping a SaaS business"
"What's happening with the US housing market right now?"
"Investigate the competitive landscape for AI code editors"
```
