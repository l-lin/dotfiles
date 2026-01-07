---
name: create-skill
description: Create new skills with proper structure and best practices. Use when user says "create skill", "new skill", "make a skill", or wants to scaffold a reusable agent capability.
---

# Skill Creation Guide

This skill creates a new skill with the proper directory structure.

## Understanding Skills vs Commands

**IMPORTANT**: The agent autonomously decides when to use them based on context. This differs from slash commands, which users explicitly trigger with `/command-name`.

This means:

- **Descriptions must be discoverable**: Include keywords users would naturally say
- **Agent matches intent**: Write descriptions that help the agent recognize when the skill applies
- **No explicit invocation**: Users don't type a command; agent activates skills automatically

## Step 1: Gather Requirements

Extract skill details from the user's message:

- **Skill name**: Look for kebab-case identifiers (e.g., `code-reviewer`, `test-runner`)
- **Skill description**: Look for description of what the skill does and when to use it
- **Trigger phrases**: When should this skill activate?

If any required information is missing, ask the user to complete it.

## Step 2: Create Directory Structure

```
~/.config/ai/skills/<skill-name>/
├── SKILL.md          (required - main instructions)
├── reference.md      (optional - detailed documentation)
├── examples.md       (optional - usage examples)
├── scripts/          (optional - utility scripts)
└── templates/        (optional - file templates)
```

## Step 3: Write SKILL.md

### Required YAML Frontmatter

```yaml
---
name: <skill-name>
description: <what-it-does>. <when-to-use-it>.
---
```

### Frontmatter Rules

- **name**: Max 64 chars, lowercase letters/numbers/hyphens only
- **description**: Max 1024 chars, MUST include:
  - What the skill does (functionality)
  - When to use it (trigger conditions/keywords)
  - **IMPORTANT** The description is critical for skill activation. Since skills are model-invoked, the agent uses the description to decide when to activate a skill. Poor descriptions = skills that never get used.
- **allowed-tools**: Comma-separated list (optional)

**Pattern for good descriptions:**

1. **What it does**: Concrete actions (extract, generate, analyze, create)
2. **Scope**: What types of inputs/outputs (PDF files, API logs, database schemas)
3. **Trigger keywords**: Phrases users would naturally say ("when the user mentions...", "when working with...")

### Content Section

After the frontmatter, write clear instructions for the agent:

- Step-by-step workflow
- Expected inputs/outputs
- Error handling guidance
- Quality criteria

## Best Practices Checklist

- [ ] **Single focus**: One skill = one capability. Don't bundle unrelated features.
- [ ] **Clear triggers**: Description includes specific keywords users would say
- [ ] **Discoverable**: Use terminology that matches user intent
- [ ] **Tested**: Verify the skill activates correctly
- [ ] **Versioned**: Include version history for team transparency

## Anti-Patterns to Avoid

- Vague descriptions like "Helps with code" - be specific
- Overly broad scope - split into multiple focused skills
- Missing trigger phrases - the agent won't know when to use it
- Tool restrictions without reason - only restrict when necessary

## Example SKILL.md

```yaml
---
name: api-tester
description: Test REST API endpoints with curl, validate responses, and generate test reports. Use when user says "test API", "check endpoint", or "validate response".
---

# API Testing Workflow

## Usage
User provides an API endpoint. You will:
1. Execute the request with curl
2. Validate the response status and body
3. Report results in a structured format

## Steps
1. Parse the endpoint URL and method
2. Execute: `curl -s -w "\n%{http_code}" <url>`
3. Check status code (2xx = pass)
4. Validate JSON structure if applicable
5. Report: endpoint, status, response time, issues

## Error Handling
- Connection timeout: Report as FAIL with retry suggestion
- 4xx/5xx: Report status with response body excerpt
- Invalid JSON: Report parsing error with raw response
```

## Step 4: Register in skill-rules.json

After creating the skill, add an entry to `~/.config/ai/skills/skill-rules.json` (or `.ai/skills/skill-rules.json` for project-specific):

```json
"<skill-name>": {
  "type": "<domain|workflow|utility|meta>",
  "enforcement": "suggest",
  "priority": "<critical|high|medium|low>",
  "promptTriggers": {
    "keywords": ["trigger phrase 1", "trigger phrase 2"],
    "intentPatterns": ["regex pattern for user intent"]
  },
  "fileTriggers": {
    "pathPatterns": ["**/relevant/paths/**"],
    "contentPatterns": ["regex for file content"]
  }
}
```

### Type Selection Guide

- **domain**: Subject-matter expertise (writing, security, accessibility)
- **workflow**: Multi-step processes (planning, deployment, review)
- **utility**: Tools and helpers (testing, scaffolding, formatting)
- **meta**: Self-referential (learning, skill creation)

### Priority Selection

- **critical**: Security, compliance - always trigger
- **high**: Core workflows - trigger for most matches
- **medium**: Helpful utilities - trigger for clear matches
- **low**: Optional enhancements - explicit matches only

## Output Location

Create skills in: `~/.config/ai/skills/<skill-name>/SKILL.md`

For project-specific skills: `.ai/skills/<skill-name>/SKILL.md`
