---
name: notebooklm-content
description: "Create branded infographics and slide decks from CryptoFlex LLC blog posts using Google NotebookLM"
user_invocable: true
---

# NotebookLM Content Skill

Create high-quality infographics and slide decks from your blog posts using Google NotebookLM, branded to CryptoFlex LLC standards.

## When This Skill Activates

- User says `/notebooklm-content`
- User asks to "create an infographic from a blog post"
- User asks to "make slides from a blog post"
- User asks to "generate NotebookLM content"
- User mentions creating visual assets from blog content

## Prerequisites

- NotebookLM MCP server (`notebooklm-mcp-cli`) configured in `~/.claude.json`
- Authenticated via `nlm login` with `chrisjohnson@cryptoflexllc.com`
- First-time setup: run `nlm login` in your terminal to authenticate

## Usage

```
/notebooklm-content <blog-post-slug-or-path> [options]
```

### Arguments

- `<blog-post-slug-or-path>`: The blog post to create content from. Can be:
  - A slug (e.g., `my-first-24-hours-with-claude-code`)
  - A full path to an MDX file
  - "latest" to use the most recent published post

### Options

- `--type infographic` (default): Generate a branded infographic (PNG)
- `--type slides`: Generate a branded slide deck (PDF + PPTX)
- `--type both`: Generate both infographic and slide deck

> **Video Overviews (new in notebooklm-mcp-cli 0.7.0)** are also available, including the `cinematic` format driven by a full creative brief. This skill's brand-QA pipeline is tuned for static assets (infographics, slides), so video generation is not wired into `--type` here. To produce a Video Overview from a notebook, use the general `notebooklm-assistant` agent (`studio_create` with `artifact_type="video"`, `video_format="cinematic"`, brief via `focus_prompt`).
- `--orientation landscape|portrait|square`: Infographic orientation (default: landscape)
- `--detail concise|standard|detailed`: Infographic detail level (default: detailed)
- `--style professional|editorial|scientific`: Infographic visual style (default: professional)
- `--slide-format detailed|presenter`: Slide deck format (default: detailed)

### Examples

```
/notebooklm-content my-first-24-hours-with-claude-code --type both
/notebooklm-content latest --type infographic --style editorial
/notebooklm-content ~/GitProjects/cryptoflexllc/src/content/blog/building-blog-with-ai.mdx --type slides
```

## What Happens

1. Reads the specified blog post from the cryptoflexllc repo
2. Uses NotebookLM MCP tools to create a notebook and add the post content as a source
3. Primes the notebook with CryptoFlex LLC branding guidelines via MCP query
4. Generates the requested content type(s) via MCP studio tools (5-15 min per asset)
5. Downloads output to `~/GitProjects/cryptoflexllc/content-assets/notebooklm/`
6. Runs QA review: spelling, accuracy, brand compliance, DLP scanning
7. Revises if needed (max 2 cycles)
8. Reports results with file paths and QA summary

## Output Location

Generation output lands in the gitignored working area:

```
~/GitProjects/cryptoflexllc/content-assets/notebooklm/
  <post-slug>/
    infographic.png
    slides.pdf
    slides.pptx
    slides/
      slide-01.png
      slide-02.png
      ...
```

Curated, embed-ready assets are then copied into the published tree under `public/blog/<slug>/`. See "Embedding Slides Into the Post" below.

## Implementation

This skill delegates to the `notebooklm-content` agent:

```
Agent(
  prompt="Follow the instructions in ~/.claude/agents/notebooklm-content.md.
         Blog post: <resolved-path>
         Content type: <type>
         Options: <options>",
  subagent_type="general-purpose",
  model="sonnet",
  name="notebooklm-content"
)
```

## Authentication

If not yet logged in or cookies have expired, run in your terminal:
```bash
nlm login
```

This opens a Chromium browser window for Google sign-in with `chrisjohnson@cryptoflexllc.com`. Cookie sessions expire every 2-4 weeks and require re-authentication.

## Relationship to Blog Post Pipeline

This skill is **separate from** the `/blog-post` command. It does not run as part of the blog production pipeline. You invoke it independently after a blog post is drafted or published.

The slide deck is **first-class article content**, not external-only collateral. The primary use is to curate select slides and embed them directly into the post (see "Embedding Slides Into the Post" below). Social and presentation reuse is secondary:
- **Primary:** Embed curated slides into the blog post as in-line article visuals, and link the full deck near the end of the post.
- **Secondary:** LinkedIn posts and social media, presentation materials, internal documentation.

The blog-post captain does not call this skill. You invoke it independently when you want visual content derived from a post. When a post has a companion deck, the captain incorporates the curated slides per this skill's convention rather than treating them as external-only.

## Embedding Slides Into the Post

After generation and QA, curate select slides into the article. Slides are primary article content: choose the few that add visual value beyond the prose and callouts.

1. **Select, do not dump.** Embed only the 4-6 strongest slides, each mapping to a distinct article section. Skip the title slide (the infographic is already the cover), any before/after slide when the post already has an equivalent custom SVG diagram or comparison table, and pure-takeaway or summary slides that merely restate existing callouts. Quality over completeness.
2. **Semantic filenames in public/.** Copy each chosen slide from `content-assets/notebooklm/<slug>/slides/slide-NN.png` to `public/blog/<slug>/<semantic-name>.png` using a descriptive kebab-case name, not `slide-NN`. The infographic remains the cover image at `public/blog/<slug>/infographic.png`.
3. **Embed with a lead-in.** In the post `.mdx`, place each slide as a plain markdown image `![rich descriptive alt text](/blog/<slug>/<semantic-name>.png)` in its relevant section, preceded by a one-sentence in-voice prose lead-in that sets up what the reader is about to see. Alt text must be genuinely descriptive for accessibility and SEO, matching the pattern in existing posts like `notebooklm-content-pipeline` and `home-network-mission-control-dashboard-log-lake-panel`.
4. **Link the full deck.** Copy `slides.pdf` to `public/blog/<slug>/slides.pdf` and link it once near the end of the post: "If you'd rather skim this as slides, the deck is here: [<Post> slide deck (PDF)](/blog/<slug>/slides.pdf)."

## Limitations

- NotebookLM generation takes 5-15 minutes per asset
- Infographic style is influenced but not fully controlled by instructions (NotebookLM makes its own design choices)
- Cookie auth expires every 2-4 weeks (run `nlm login` to refresh; `nlm login --check` verifies the current session). If the MCP reports `auth_status: stale`, re-auth; `unverified` is a transient network error, not an auth failure.
- Uses reverse-engineered Google APIs via notebooklm-mcp-cli (may break without notice). Keep current with `uv tool upgrade notebooklm-mcp-cli`, then reconnect the `notebooklm` MCP server.
- Maximum 50 sources per notebook
- Free tier rate limit: approximately 50 queries per day

## Known stall patterns

- **Slide decks can appear stuck at `in_progress` for 25+ minutes** before completing. This is the expected pattern, not a failure. Do not cancel or retry. Keep polling. Most common on first-time or large notebook runs; subsequent requests tend to complete faster.
- **`download_artifact` can succeed while `studio_status` still reports `in_progress`.** Observed on a 71+ minute wait (and a separate 75 minute case). Do not gate the download on a completed status. Call `download_artifact` periodically; if it returns bytes, accept the artifact and move on. If it errors, keep polling and retry. Have a manual fallback (custom SVG diagram component) ready so a post can ship even without the NotebookLM asset.
