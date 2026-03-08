#!/usr/bin/env node

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { CallToolRequestSchema, ListToolsRequestSchema } from '@modelcontextprotocol/sdk/types.js';
import fs from 'fs/promises';
import fsSync from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Configuration (macOS defaults)
const projectRoot = process.env.PROJECT_ROOT || '/Users/chris2ao/GitProjects';
const claudeConfig = process.env.CLAUDE_CONFIG || path.join(
  process.env.HOME || '/Users/chris2ao',
  '.claude'
);

const repos = [
  {
    name: 'CJClaude_1',
    path: path.join(projectRoot, 'CJClaude_1')
  },
  {
    name: 'cryptoflexllc',
    path: path.join(projectRoot, 'cryptoflexllc')
  },
  {
    name: 'cryptoflex-ops',
    path: path.join(projectRoot, 'cryptoflex-ops')
  },
  {
    name: 'claude-code-config',
    path: claudeConfig
  },
  {
    name: 'CJClaudin_Mac',
    path: path.join(projectRoot, 'CJClaudin_Mac')
  }
];

// Cache management
const cache = new Map();
const ttlMap = new Map();

// BUG FIX #1: getCached must be async to properly await async computeFn
async function getCached(key, computeFn, ttlMs) {
  const now = Date.now();
  if (cache.has(key) && ttlMap.has(key) && now < ttlMap.get(key)) {
    return { result: cache.get(key), cache_hit: true };
  }

  const result = await computeFn();
  cache.set(key, result);
  if (ttlMs && ttlMs !== Infinity) {
    ttlMap.set(key, now + ttlMs);
  } else if (ttlMs === Infinity) {
    ttlMap.set(key, Infinity);
  } else {
    ttlMap.delete(key);
  }
  return { result, cache_hit: false };
}

function invalidateCache(key) {
  cache.delete(key);
  ttlMap.delete(key);
}

// Watch file system for changes
function watchBlogDirectory() {
  const blogDir = path.join(projectRoot, 'cryptoflexllc/src/content/blog');
  try {
    fsSync.watch(blogDir, (eventType, filename) => {
      if (filename && filename.endsWith('.mdx')) {
        invalidateCache('blog_posts');
      }
    });
  } catch (err) {
    // Directory might not exist, that's okay
  }
}

// Tool implementations

async function toolRepoStatus({ repo, include_diff } = {}) {
  const startTime = Date.now();

  return getCached('repo_status_' + (repo || 'all'), () => {
    const reposToCheck = repo
      ? repos.filter(r => r.name === repo)
      : repos;

    const repoData = reposToCheck
      .filter(r => fsSync.existsSync(path.join(r.path, '.git')))
      .map(r => {
        try {
          const repoPath = r.path;
          const branch = execSync(`git -C "${repoPath}" branch --show-current`, { encoding: 'utf-8' }).trim();

          // BUG FIX #2: Consolidate redundant git status --porcelain calls into one
          const statusOutput = execSync(`git -C "${repoPath}" status --porcelain`, { encoding: 'utf-8' });

          const modifiedFiles = statusOutput
            .split('\n')
            .filter(line => line.startsWith(' M '))
            .map(line => line.substring(3));
          const untrackedFiles = statusOutput
            .split('\n')
            .filter(line => line.startsWith('?? '))
            .map(line => line.substring(3));

          const aheadStr = execSync(`git -C "${repoPath}" rev-list --count @{u}.. 2>/dev/null || echo 0`, { encoding: 'utf-8' }).trim();
          const behindStr = execSync(`git -C "${repoPath}" rev-list --count ..@{u} 2>/dev/null || echo 0`, { encoding: 'utf-8' }).trim();

          const ahead = parseInt(aheadStr, 10) || 0;
          const behind = parseInt(behindStr, 10) || 0;

          const remoteUrl = execSync(`git -C "${repoPath}" config --get remote.origin.url`, { encoding: 'utf-8' }).trim();

          const commitsLog = execSync(`git -C "${repoPath}" log -3 --format=%h|%s|%aN|%aI`, { encoding: 'utf-8' }).trim();
          const recentCommits = commitsLog
            .split('\n')
            .filter(Boolean)
            .map(line => {
              const [hash, message, author, date] = line.split('|');
              return { hash, message, author, date };
            });

          return {
            name: r.name,
            path: repoPath,
            git: {
              branch,
              tracking_remote: `origin/${branch}`,
              clean: modifiedFiles.length === 0 && untrackedFiles.length === 0,
              modified_files: modifiedFiles,
              untracked_files: untrackedFiles,
              ahead,
              behind,
              remote_url: remoteUrl
            },
            recent_commits: recentCommits
          };
        } catch (err) {
          return {
            name: r.name,
            path: r.path,
            error: err.message
          };
        }
      });

    const allClean = repoData.every(r => !r.error && r.git.clean);
    const allUpToDate = repoData.every(r => !r.error && r.git.ahead === 0 && r.git.behind === 0);

    return {
      timestamp: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      repos: repoData,
      summary: {
        all_clean: allClean,
        all_up_to_date: allUpToDate,
        repos_needing_push: repoData.filter(r => !r.error && r.git.ahead > 0).length,
        repos_needing_pull: repoData.filter(r => !r.error && r.git.behind > 0).length,
        total_modified_files: repoData.reduce((sum, r) => sum + (r.git?.modified_files?.length || 0), 0),
        total_untracked_files: repoData.reduce((sum, r) => sum + (r.git?.untracked_files?.length || 0), 0)
      }
    };
  }, 30 * 1000); // 30 second TTL
}

async function toolBlogPosts({ sort_by = 'title', filter_tag } = {}) {
  const startTime = Date.now();

  return getCached('blog_posts', async () => {
    const blogDir = path.join(projectRoot, 'cryptoflexllc/src/content/blog');
    const posts = [];

    try {
      const files = await fs.readdir(blogDir);

      for (const file of files) {
        if (!file.endsWith('.mdx')) continue;

        const filePath = path.join(blogDir, file);
        const content = await fs.readFile(filePath, 'utf-8');

        // Extract frontmatter
        const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
        if (!frontmatterMatch) continue;

        const frontmatterText = frontmatterMatch[1];
        const title = (frontmatterText.match(/title:\s*['"](.*?)['"]/) || [])[1] || null;
        const date = (frontmatterText.match(/date:\s*['"](.*?)['"]/) || [])[1] || null;
        const description = (frontmatterText.match(/description:\s*['"](.*?)['"]/) || [])[1] || null;
        const tagsMatch = frontmatterText.match(/tags:\s*\[(.*?)\]/);
        const tags = tagsMatch
          ? tagsMatch[1]
              .split(',')
              .map(t => t.trim().replace(/['"]/g, ''))
              .filter(Boolean)
          : [];

        // Count words
        const bodyContent = content.replace(/^---\n[\s\S]*?\n---/, '');
        const wordCount = (bodyContent.match(/([\w'-]+)/g) || []).length;

        const post = {
          filename: file,
          title,
          date,
          description,
          tags,
          word_count: wordCount,
          published: true
        };

        if (!filter_tag || tags.includes(filter_tag)) {
          posts.push(post);
        }
      }
    } catch (err) {
      // Directory doesn't exist or can't be read
    }

    // Sort
    if (sort_by === 'date') {
      posts.sort((a, b) => new Date(b.date) - new Date(a.date));
    } else {
      posts.sort((a, b) => (a.title || '').localeCompare(b.title || ''));
    }

    const allTags = [...new Set(posts.flatMap(p => p.tags))].sort();
    const totalWords = posts.reduce((sum, p) => sum + p.word_count, 0);

    return {
      timestamp: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      cache_hit: false,
      posts,
      metadata: {
        total_posts: posts.length,
        total_words: totalWords,
        latest_post: posts[0] ? { filename: posts[0].filename, date: posts[0].date } : null,
        all_tags: allTags,
        avg_post_length: posts.length > 0 ? Math.round(totalWords / posts.length) : 0,
        oldest_post: posts[posts.length - 1] ? { filename: posts[posts.length - 1].filename, date: posts[posts.length - 1].date } : null
      }
    };
  }, Infinity); // Infinite TTL with file watcher invalidation
}

async function toolStyleGuide() {
  const startTime = Date.now();

  return getCached('style_guide', async () => {
    const styleGuidePath = path.join(claudeConfig, 'skills/blog-style-guide.md');
    const mdxRefPath = path.join(claudeConfig, 'skills/blog-mdx-reference.md');

    let styleGuideContent = '';
    let mdxRefContent = '';

    try {
      styleGuideContent = await fs.readFile(styleGuidePath, 'utf-8');
    } catch (err) {
      // File doesn't exist
    }

    try {
      mdxRefContent = await fs.readFile(mdxRefPath, 'utf-8');
    } catch (err) {
      // File doesn't exist
    }

    return {
      timestamp: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      cache_hit: false,
      style_guide: {
        title: 'CryptoFlex Blog Style Guide',
        content: styleGuideContent
      },
      mdx_reference: {
        title: 'MDX Syntax Reference',
        content: mdxRefContent
      },
      combined: styleGuideContent + '\n\n' + mdxRefContent
    };
  }, 5 * 60 * 1000); // 5 minute TTL
}

async function toolValidateBlogPost({ path: filePath } = {}) {
  const startTime = Date.now();

  if (!filePath) {
    return {
      timestamp: new Date().toISOString(),
      valid: false,
      errors: ['path parameter is required']
    };
  }

  const fullPath = path.join(projectRoot, 'cryptoflexllc', filePath);
  let content = '';

  try {
    content = await fs.readFile(fullPath, 'utf-8');
  } catch (err) {
    return {
      timestamp: new Date().toISOString(),
      path: filePath,
      valid: false,
      errors: [`File not found: ${filePath}`]
    };
  }

  const checks = [];

  // Check 1: Frontmatter complete
  const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---/);
  let frontmatterValid = true;
  if (frontmatterMatch) {
    const fm = frontmatterMatch[1];
    const hasTitle = /title:/.test(fm);
    const hasDate = /date:/.test(fm);
    const hasDescription = /description:/.test(fm);
    const hasTags = /tags:/.test(fm);

    frontmatterValid = hasTitle && hasDate && hasDescription && hasTags;
    checks.push({
      name: 'frontmatter_complete',
      passed: frontmatterValid,
      details: frontmatterValid
        ? 'All required fields present'
        : `Missing: ${!hasTitle ? 'title ' : ''}${!hasDate ? 'date ' : ''}${!hasDescription ? 'description ' : ''}${!hasTags ? 'tags' : ''}`
    });
  } else {
    frontmatterValid = false;
    checks.push({
      name: 'frontmatter_complete',
      passed: false,
      details: 'No frontmatter found'
    });
  }

  // Check 2: No em-dashes
  const emDashMatches = [...content.matchAll(/\s\u2014\s/g)];
  const noEmDashes = emDashMatches.length === 0;
  if (!noEmDashes) {
    checks.push({
      name: 'no_em_dashes',
      passed: false,
      details: `Found ${emDashMatches.length} em-dashes, use commas or parentheses instead`,
      locations: emDashMatches.map((match) => {
        const line = content.substring(0, match.index).split('\n').length;
        const lineStart = content.lastIndexOf('\n', match.index) + 1;
        const lineEnd = content.indexOf('\n', match.index);
        const text = content.substring(lineStart, lineEnd).trim();
        return { line, text };
      })
    });
  } else {
    checks.push({
      name: 'no_em_dashes',
      passed: true,
      details: 'No em-dashes found'
    });
  }

  // Check 3: Word count
  const wordCount = (content.match(/([\w'-]+)/g) || []).length;
  const wordCountOk = wordCount >= 2000 && wordCount <= 5000;
  checks.push({
    name: 'word_count',
    passed: wordCountOk,
    details: `${wordCount.toLocaleString()} words (recommended: 2,000-5,000)`,
    metrics: { actual: wordCount, minimum: 2000, maximum: 5000 }
  });

  // Check 4: Alt text on images
  const imageMatches = [...content.matchAll(/!\[(.*?)\]\((.*?)\)/g)];
  const imagesWithAlt = imageMatches.filter(m => m[1] && m[1].trim().length > 0);
  checks.push({
    name: 'alt_text_on_images',
    passed: imagesWithAlt.length === imageMatches.length,
    details: `${imagesWithAlt.length}/${imageMatches.length} images have alt text`
  });

  // Check 5: Callout titles
  const calloutMatches = [...content.matchAll(/<Callout[^>]*>/g)];
  const calloutWithTitle = calloutMatches.filter(m => /title=/.test(m[0]));
  checks.push({
    name: 'callout_titles',
    passed: calloutWithTitle.length === calloutMatches.length,
    details: `${calloutWithTitle.length}/${calloutMatches.length} callouts have titles`
  });

  // Check 6: No duplicate images
  const imageUrls = imageMatches.map(m => m[2]);
  const uniqueUrls = new Set(imageUrls);
  checks.push({
    name: 'duplicate_images',
    passed: imageUrls.length === uniqueUrls.size,
    details: imageUrls.length === uniqueUrls.size
      ? 'No duplicate images'
      : `Found ${imageUrls.length - uniqueUrls.size} duplicate image references`
  });

  // Check 7: Code blocks with language
  const codeMatches = [...content.matchAll(/```(\w+)?/g)];
  const codeWithLanguage = codeMatches.filter(m => m[1] && m[1].trim().length > 0);
  checks.push({
    name: 'code_blocks',
    passed: codeWithLanguage.length === codeMatches.length,
    details: `${codeWithLanguage.length}/${codeMatches.length} code blocks have language specified`,
    count: codeMatches.length
  });

  // Summary
  const passed = checks.filter(c => c.passed).length;
  const failed = checks.filter(c => !c.passed).length;

  return {
    timestamp: new Date().toISOString(),
    duration_ms: Date.now() - startTime,
    path: filePath,
    valid: failed === 0,
    checks,
    summary: {
      total_checks: checks.length,
      passed,
      failed,
      errors: failed > 0 ? checks.filter(c => !c.passed).map(c => c.name) : [],
      warnings: []
    }
  };
}

async function toolSessionArtifacts() {
  const startTime = Date.now();

  return getCached('session_artifacts', async () => {
    const userHome = process.env.HOME || '/Users/chris2ao';
    const transcriptDir = path.join(userHome, '.claude/projects');
    const todosDir = path.join(userHome, '.claude/todos');
    const activityLogPath = path.join(projectRoot, 'CJClaude_1/activity_log.txt');
    const settingsLocalPath = path.join(projectRoot, 'CJClaude_1/.claude/settings.local.json');

    let transcriptCount = 0;
    let transcriptSize = 0;
    let transcriptLatest = null;

    try {
      const projects = await fs.readdir(transcriptDir);
      for (const proj of projects) {
        const projPath = path.join(transcriptDir, proj);
        try {
          const files = await fs.readdir(projPath);
          const jsonlFiles = files.filter(f => f.endsWith('.jsonl'));
          transcriptCount += jsonlFiles.length;

          for (const file of jsonlFiles) {
            const stat = fsSync.statSync(path.join(projPath, file));
            transcriptSize += stat.size;
            if (!transcriptLatest || stat.mtime > transcriptLatest.mtime) {
              transcriptLatest = { file, mtime: stat.mtime, size: stat.size };
            }
          }
        } catch (err) {
          // Skip
        }
      }
    } catch (err) {
      // Directory doesn't exist
    }

    let todoCount = 0;
    let todoPending = 0;
    let todoInProgress = 0;
    let todoCompleted = 0;
    let todoSize = 0;

    try {
      const todos = await fs.readdir(todosDir);
      const jsonFiles = todos.filter(f => f.endsWith('.json'));
      todoCount = jsonFiles.length;

      for (const file of jsonFiles) {
        const filePath = path.join(todosDir, file);
        try {
          const stat = fsSync.statSync(filePath);
          todoSize += stat.size;

          const content = await fs.readFile(filePath, 'utf-8');
          const json = JSON.parse(content);
          // BUG FIX #3: Increment todoPending (not todoCount) for pending status
          if (json.status === 'pending') todoPending++;
          else if (json.status === 'in_progress') todoInProgress++;
          else if (json.status === 'completed') todoCompleted++;
        } catch (err) {
          // Skip
        }
      }
    } catch (err) {
      // Directory doesn't exist
    }

    let activityLogLines = 0;
    let activityLogSize = 0;

    try {
      const stat = fsSync.statSync(activityLogPath);
      activityLogSize = stat.size;
      const content = await fs.readFile(activityLogPath, 'utf-8');
      activityLogLines = content.split('\n').length;
    } catch (err) {
      // File doesn't exist
    }

    let permissionsCount = 0;
    try {
      const content = await fs.readFile(settingsLocalPath, 'utf-8');
      const json = JSON.parse(content);
      permissionsCount = Object.keys(json.permissions || {}).length;
    } catch (err) {
      // File doesn't exist
    }

    return {
      timestamp: new Date().toISOString(),
      duration_ms: Date.now() - startTime,
      cache_hit: false,
      artifacts: {
        transcripts: {
          count: transcriptCount,
          total_size_mb: (transcriptSize / 1024 / 1024).toFixed(1),
          location: transcriptDir,
          latest: transcriptLatest ? {
            file: transcriptLatest.file,
            size_mb: (transcriptLatest.size / 1024 / 1024).toFixed(2),
            created: transcriptLatest.mtime.toISOString()
          } : null
        },
        todos: {
          count: todoCount,
          total_size_kb: (todoSize / 1024).toFixed(0),
          location: todosDir,
          pending: todoPending,
          in_progress: todoInProgress,
          completed: todoCompleted
        },
        activity_log: {
          lines: activityLogLines,
          size_mb: (activityLogSize / 1024 / 1024).toFixed(2),
          location: activityLogPath,
          archives: []
        },
        settings_local: {
          permissions_count: permissionsCount,
          file: settingsLocalPath
        }
      },
      cleanup_recommendations: {
        archivable_transcripts: {
          count: Math.max(0, transcriptCount - 10),
          recommendation: 'Archive transcripts older than 7 days to save space'
        },
        removable_todos: {
          count: todoCompleted,
          recommendation: 'Delete completed todos older than 3 days'
        }
      }
    };
  }, 60 * 1000); // 60 second TTL
}

// MCP Server setup
const server = new Server(
  { name: 'project-tools', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

// Register tools
server.setRequestHandler(ListToolsRequestSchema, async () => {
  return {
    tools: [
      {
        name: 'repo_status',
        description: 'Get cached git status across all project repos',
        inputSchema: {
          type: 'object',
          properties: {
            repo: {
              type: 'string',
              description: 'Filter to specific repo (CJClaude_1, cryptoflexllc, cryptoflex-ops, claude-code-config, CJClaudin_Mac)',
              enum: ['CJClaude_1', 'cryptoflexllc', 'cryptoflex-ops', 'claude-code-config', 'CJClaudin_Mac']
            },
            include_diff: {
              type: 'boolean',
              description: 'Include full git diff output'
            }
          }
        }
      },
      {
        name: 'blog_posts',
        description: 'Get cached blog post inventory with frontmatter metadata',
        inputSchema: {
          type: 'object',
          properties: {
            sort_by: {
              type: 'string',
              description: 'Sort order: date (newest first) or title (alphabetical)',
              enum: ['date', 'title']
            },
            filter_tag: {
              type: 'string',
              description: 'Filter to posts with specific tag'
            }
          }
        }
      },
      {
        name: 'style_guide',
        description: 'Get cached blog reference documentation',
        inputSchema: { type: 'object', properties: {} }
      },
      {
        name: 'validate_blog_post',
        description: 'Validate blog post content against style rules',
        inputSchema: {
          type: 'object',
          properties: {
            path: {
              type: 'string',
              description: 'Relative path to .mdx file in cryptoflexllc repo'
            }
          },
          required: ['path']
        }
      },
      {
        name: 'session_artifacts',
        description: 'Count and summarize session artifacts',
        inputSchema: { type: 'object', properties: {} }
      }
    ]
  };
});

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name, arguments: args } = request.params;

  try {
    let result;
    switch (name) {
      case 'repo_status':
        result = await toolRepoStatus(args);
        break;
      case 'blog_posts':
        result = await toolBlogPosts(args);
        break;
      case 'style_guide':
        result = await toolStyleGuide();
        break;
      case 'validate_blog_post':
        result = await toolValidateBlogPost(args);
        break;
      case 'session_artifacts':
        result = await toolSessionArtifacts();
        break;
      default:
        return { isError: true, content: [{ type: 'text', text: `Unknown tool: ${name}` }] };
    }

    return {
      content: [{ type: 'text', text: JSON.stringify(result, null, 2) }],
      isError: false
    };
  } catch (err) {
    return {
      isError: true,
      content: [{ type: 'text', text: `Tool error: ${err.message}` }]
    };
  }
});

// Start server
async function main() {
  watchBlogDirectory();

  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
