---
name: brand-graphics
description: Use when a cryptoflexllc.com blog post needs a cover infographic or inline branded graphic, when a cover placeholder ("COVER / slug") shows on the site, or when replacing a garbled NotebookLM image. Default image pipeline; NotebookLM is used only when the user explicitly asks for it.
---

# Brand Graphics

Create branded blog graphics (cover infographics, inline panels) as hand-authored HTML rendered to PNG with headless Chrome. Deterministic output: exact text, exact CryptoFlex brand tokens, exact 2752x1536 cover dimensions.

## Usage

```
/brand-graphics <blog-post-slug-or-path> [options]
```

- `--type cover` (default): 2752x1536 cover infographic, wired into frontmatter
- `--type inline`: article-body graphic at a size fitting the content
- `--no-frontmatter`: produce the image only, skip the MDX edit
- `latest`: use the most recent published post

## What Happens

Delegate to the brand-graphics agent:

```
Agent(
  prompt="Follow the instructions in ~/.claude/agents/brand-graphics.md.
         Blog post: <resolved-path>
         Type: <cover|inline>
         Output mode: repo",
  subagent_type="general-purpose",
  model="sonnet",
  name="brand-graphics"
)
```

The agent reads the post, pulls live brand tokens from `src/app/globals.css`, authors HTML, renders with headless Chrome, runs its verification loop (view render, proofread, dimension and crop-safe checks), and writes:

- `public/blog/<slug>/infographic.png` (the deliverable)
- `content-assets/covers/<slug>/cover.html` (editable source, gitignored)
- `coverImage` + `coverImageAlt` frontmatter (cover type, unless `--no-frontmatter`)

Review the returned render before committing. Edits go to the HTML source followed by a re-render; never regenerate from scratch.

## Relationship to Other Pipelines

- `/blog-post` calls this pipeline by default for covers (its Cover Graphic phase).
- `/notebooklm-content` is the backup generator, used ONLY when the user explicitly asks for NotebookLM. Its known failure mode: garbled small text (URLs, labels, mockup copy) and ignored orientation instructions.
