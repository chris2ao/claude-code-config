# Parallel Agent Decomposition Pattern

**Extracted:** 2026-02-13
**Context:** Feb 13 agentic-first workflow, em dash removal (11 files, 5 parallel agents, 2 hours vs estimated 4+)

## Pattern
When facing tasks with multiple independent subtasks, decompose into parallel agents BEFORE starting work:

### Step 1: Planning Phase (5 Questions)
**Ask yourself:**
1. What are the independent subtasks?
2. Which subtasks can run in parallel?
3. Which agents are best for each subtask?
4. What's the expected time savings vs serial execution?
5. What's the integration strategy (how do results combine)?

### Step 2: Agent Selection
**Route by task type:**
- **File exploration:** Explore agent (Haiku)
- **Code writing:** general-purpose agent (Sonnet)
- **Code review:** code-reviewer agent (inherit model)
- **Security analysis:** security-reviewer agent (inherit model)
- **Documentation:** doc-updater agent (Haiku)
- **Research/web search:** general-purpose agent (Haiku)
- **Architecture decisions:** architect agent (Opus)

### Step 3: Parallel Execution
**Launch all independent agents in a SINGLE message:**
```
Task 1: Explore agent — Find all blog post files
Task 2: Explore agent — Find all documentation files
Task 3: general-purpose agent — Remove em dashes from posts 1-5
Task 4: general-purpose agent — Remove em dashes from posts 6-10
Task 5: general-purpose agent — Remove em dashes from docs
```

**NOT:**
```
Task 1: Explore agent (wait for result)
(result arrives)
Task 2: Explore agent (wait for result)
(result arrives)
... (serial execution, 5x slower)
```

### Step 4: Integration
**After all agents complete:**
- Review all changes for consistency
- Run build verification across all modified files
- Commit as a single logical unit

## Example: Em Dash Removal (Feb 13)
**Without parallel decomposition (estimated):**
- Read 11 blog posts serially: 11 × 5 min = 55 min
- Edit each post: 11 × 10 min = 110 min
- Review edits: 11 × 5 min = 55 min
- **Total: ~220 min (3.7 hours)**

**With parallel decomposition (actual):**
- Planning phase: 15 min
- Launch 5 agents in parallel: 5 min
- Agents execute simultaneously: 60 min (longest agent)
- Review + build verification: 30 min
- Commit: 10 min
- **Total: 120 min (2 hours), 45% time savings**

## When NOT to Use Parallel Agents
**Skip parallelization if:**
1. Subtasks depend on each other (Task B needs Task A's output)
2. Task is simple enough for main session (< 3 independent steps)
3. Agent sandboxing prevents access (e.g., global config in `~/.claude/`)
4. Coordination overhead exceeds execution time (very small tasks)

## Quality Indicators
**Parallel decomposition is working well when:**
- Time savings > 30% vs serial execution
- Zero integration conflicts (agents didn't edit overlapping code)
- Build passes on first try after integration
- No duplicate work (agents had clear boundaries)

**Red flags (don't parallelize):**
- Agents editing the same files (coordination needed)
- Unclear task boundaries (need more planning first)
- Dependencies between tasks (must run serially)

## Anti-pattern
```
# DON'T: Parallelize dependent tasks
Task 1 (agent): Write API endpoint
Task 2 (agent): Write tests for endpoint
(Task 2 starts before Task 1 finishes, writes tests for wrong API)

# DO: Chain dependent tasks
Task 1 (agent): Write API endpoint (WAIT for completion)
Task 2 (agent): Write tests for the endpoint (starts after Task 1)

# OR: Parallelize independent work
Task 1 (agent): Write API endpoint
Task 2 (agent): Write documentation for existing feature (independent)
(both run in parallel safely)
```

## When to Use
- Large-scale refactoring (5+ files, independent changes)
- Multi-repo operations (sync config across repos)
- Content creation (multiple blog posts, documentation pages)
- Testing (unit tests for independent modules)
- Research (multiple documentation sources, API exploration)
- Code review (split large PR into logical sections)
