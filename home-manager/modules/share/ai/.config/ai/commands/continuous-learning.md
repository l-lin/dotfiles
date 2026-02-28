---
description: "Process for continuous learning from interactions, creating reusable skills for future tasks."
---

# Continuous Learning

Two-stage learning process: reflection and skill creation.

## 1. Run Reflection (Stage 1)

### 1.1 Gather Context

Review the conversation to identify:

```markdown
## Task Summary
- What was the original goal?
- What approach was taken?
- What was the outcome (success/partial/failure)?

## Key Decisions
- What choices were made and why?
- What alternatives were considered?

## Challenges Encountered
- What obstacles appeared?
- How were they resolved?
- Any dead ends explored?

## Patterns Identified
- Repetitive operations that could be abstracted
- Domain-specific knowledge acquired
- Tool usage patterns that worked well
```

### 1.2 Evaluate Learning Potential

Ask these questions (internally, don't spam the user):

1. **Novelty**: Is this something Claude doesn't already know?
2. **Reusability**: Will this apply to future tasks?
3. **Specificity**: Is this concrete enough to be actionable?
4. **Correctness**: Was the approach actually correct?

**Skip skill creation if:**
- The solution was trivial or well-known
- It's too specific to one codebase/situation
- The approach was suboptimal or wrong

### 1.3 Classify the Learning

Determine the type:

| Type | Description | Example |
|------|-------------|---------|
| `pattern` | Reusable code/workflow pattern | "How to set up X in this codebase" |
| `pitfall` | Common mistake to avoid | "Don't use X because Y" |
| `debugging` | Troubleshooting approach | "When you see error X, check Y" |
| `tool-usage` | Effective tool combination | "Use grep + glob for X type searches" |
| `domain` | Domain-specific knowledge | "In this system, X means Y" |

## 2. Stage 2: Skill Creation

Generate a skill file capturing the learning.

### 2.1 Skill File Structure

Skills are stored in `.ai/skills/<skill_name>/SKILL.md` as markdown files.

File naming: `<type>-<short-description>.md` (kebab-case)

Example: `debugging-postgres-connection-pool.md`

### 2.2 Create the skill

Use the `writting-skill` skill to generate the content of the skill and any relevant files (e.g. `reference.md`, some scripts, ...).

### 2.3 Quality Gates

Before saving, verify:

- [ ] Title clearly describes the skill
- [ ] Context is specific enough to match future situations
- [ ] Learning is actionable, not just descriptive
- [ ] Approach has concrete steps
- [ ] No sensitive data (secrets, internal URLs, PII)

### 2.4 Save the Skill

```bash
# Write to learned-skills directory
.ai/skills/<type>-<description>/SKILL.md
```

### 2.5 Report to User

After creation, output:

```markdown
📚 Skill learned: `<filename>`

**Type**: <type>
**Summary**: <one-line summary>
**Confidence**: <confidence level>

Stored in: .ai/learned-skills/
```

## Example: Learning from a Debugging Session

**Session**: User asked to fix a flaky test. After investigation, found it was a race condition in async code.

### Reflection Output

```markdown
## Task Summary
- Goal: Fix flaky test in payment processing
- Approach: Added logging, identified race condition, added proper await
- Outcome: Success

## Key Decisions
- Chose to add explicit awaits rather than mutex (simpler)

## Patterns Identified
- Flaky tests often indicate async issues
- Adding timestamps to logs reveals race conditions
```

### Generated Skill

```markdown
---
name: debug-flaky-tests
description: "Use when user says 'flaky' or when tests pass intermittently, fail randomly in CI, or exhibit non-deterministic behavior."
---

# Debugging Flaky Tests: Race Condition Pattern

## Context
When a test passes sometimes and fails others, especially in async code.

## The Learning
Flaky tests in async codebases are usually race conditions. Add timestamp logging to identify ordering issues, then ensure proper await/synchronization.

## Approach
1. Add console.log with timestamps at key async boundaries
2. Run test multiple times, compare logs between pass/fail
3. Identify out-of-order operations
4. Add explicit await or synchronization primitives
5. Remove debug logging after fix

## Pitfalls to Avoid
- Don't just add random sleeps/delays
- Don't increase timeouts as a "fix"
- Don't ignore: flaky tests indicate real bugs

## Verification
Run test 10+ times consecutively; should pass 100%

## Source Session
Fixed flaky payment processing test - race condition between webhook handler and response
```

## Key Principles

- **Actionable knowledge**: Capture what to DO, not just what happened
- **Failure modes**: Document pitfalls and how to avoid them
- **Verification**: Include concrete checks to confirm success
- **Generalizability**: Make it applicable to similar future tasks

## Process Flow

```
TRIGGER → REFLECTION → DECISION → SKILL CREATION
                           ↓
                    [Worth a skill?]
                     Yes → Create
                     No  → Done
```

