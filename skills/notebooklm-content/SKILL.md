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

This skill is **separate from** the `/blog-post` command. It does not run as part of the blog production pipeline. Instead, invoke it after a blog post is published (or drafted) to create supplementary visual assets for:
- Embedding in the blog post as images
- LinkedIn posts and social media
- Presentation materials
- Internal documentation

The blog-post captain does not call this skill. You invoke it independently when you want visual content derived from a post.

## Limitations

- NotebookLM generation takes 5-15 minutes per asset
- Infographic style is influenced but not fully controlled by instructions (NotebookLM makes its own design choices)
- Cookie auth expires every 2-4 weeks (run `nlm login` to refresh)
- Uses reverse-engineered Google APIs via notebooklm-mcp-cli (may break without notice)
- Maximum 50 sources per notebook
- Free tier rate limit: approximately 50 queries per day

## Known stall patterns

- **Slide decks can appear stuck at `in_progress` for 25+ minutes** before completing. This is the expected pattern, not a failure. Do not cancel or retry. Keep polling. Most common on first-time or large notebook runs; subsequent requests tend to complete faster.
- **`download_artifact` can succeed while `studio_status` still reports `in_progress`.** Observed on a 71+ minute wait (and a separate 75 minute case). Do not gate the download on a completed status. Call `download_artifact` periodically; if it returns bytes, accept the artifact and move on. If it errors, keep polling and retry. Have a manual fallback (custom SVG diagram component) ready so a post can ship even without the NotebookLM asset.
