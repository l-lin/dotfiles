---
name: ingest-url
description: Ingest a URL into the patient account wiki. Use when the user provides a URL (Atlassian/Confluence, web articles, documentation) and wants to add it to their research wiki. Handles fetching, markdown conversion, asset extraction, and runs the full wiki ingest workflow. Triggers on "ingest <url>", "add this to the wiki", or when user shares a URL in the context of wiki research.
disable-model-invocation: true
---

# Ingest URL

Fetches content from a URL, converts it to markdown, extracts assets, saves to `/raw/`, and runs the wiki ingest workflow.

## Supported URL Types

| URL Pattern | Handler | Notes |
|-------------|---------|-------|
| `*.atlassian.net/wiki/*` | Atlassian MCP | Confluence pages |
| `confluence.*` | Atlassian MCP | Self-hosted Confluence |
| Everything else | `scripts/fetch-url.sh` | Uses defuddle for extraction |

## Workflow

### Step 1: Detect URL Type and Fetch Content

**For Atlassian/Confluence URLs:**
1. Parse the page ID from the URL (format: `/wiki/spaces/SPACE/pages/PAGE_ID/title`)
2. Use `mcp__claude_ai_Atlassian__getConfluencePage` to fetch the page content
3. The response includes HTML body content and metadata
4. Convert HTML to markdown manually (strip Confluence macros, preserve structure)

**For regular web URLs — use the bundled script:**

```bash
./scripts/fetch-url.sh "<url>" "raw/<category>" "<slug>"
```

The script uses `defuddle` to:
- Extract clean content (strips nav, ads, boilerplate)
- Get metadata (title, author, published date, word count)
- Convert to markdown with proper structure
- Download images to `raw/assets/` with prefixed names
- Output markdown with YAML frontmatter

**Script output (JSON):**
```json
{
  "output_file": "raw/specs/example.md",
  "title": "Page Title",
  "assets_downloaded": 3,
  "word_count": 1500,
  "slug": "example"
}
```

### Step 2: Determine Category and Slug

**Ask the user** which category fits best (or infer from URL patterns):

| Category | Use for | URL hints |
|----------|---------|-----------|
| `specs/` | Technical specifications, API docs, architecture | `docs.*`, `developer.*`, `api.*` |
| `papers/` | Research papers, whitepapers, academic articles | `arxiv.org`, `*.edu`, `research.*` |
| `vendor/` | Vendor documentation, product docs | Product/company domains |

**Generate slug** from page title:
- Lowercase, hyphen-separated
- Include date if relevant: `gdpr-guide-2024.md`
- Keep short but descriptive

### Step 3: Run the Fetch Script (for web URLs)

```bash
./scripts/fetch-url.sh "<url>" "raw/<category>" "<slug>"
```

The script automatically:
- Saves markdown with frontmatter to `raw/{category}/{slug}.md`
- Downloads images to `raw/assets/{slug}-*.{ext}`
- Updates image references to local paths

### Step 4: Run Wiki Ingest Workflow

Follow the ingest workflow from AGENTS.md:

1. **Read** the saved markdown file
2. **Discuss** key takeaways with the user
3. **Create** summary page in `wiki/summaries/{slug}.md`
4. **Update/create** entity pages for systems, vendors, standards mentioned
5. **Update/create** concept pages for patterns, principles discussed
6. **Cross-reference** — link related pages
7. **Update** `wiki/index.md` with new pages
8. **Update** `wiki/overview.md` if this changes the big picture
9. **Log** the ingest in `wiki/log.md`

## Example Usage

**User says:**
```
ingest https://confluence.company.com/wiki/spaces/HEALTH/pages/12345/FHIR-Integration-Guide
```

**Claude does:**
1. Detects Atlassian URL → uses MCP tools
2. Fetches page content and metadata
3. Converts Confluence HTML to markdown
4. Downloads embedded diagrams to `raw/assets/`
5. Asks: "This looks like a technical spec. Save to `raw/specs/fhir-integration-guide.md`?"
6. After confirmation, saves the file
7. Creates `wiki/summaries/fhir-integration-guide.md`
8. Creates/updates entity pages (e.g., `wiki/entities/fhir-standard.md`)
9. Creates/updates concept pages (e.g., `wiki/concepts/healthcare-interoperability.md`)
10. Updates index and log

## Handling Edge Cases

**Authentication required:**
- For Atlassian: MCP tools handle auth automatically
- For other sites: inform user, suggest manual copy-paste

**Content too large:**
- If page is very long, ask user if they want the full content or a specific section
- Consider splitting into multiple files if appropriate

**Assets fail to download:**
- Log the failure
- Keep the original URL in markdown as fallback
- Note in summary which assets are missing

**Duplicate source:**
- Check if URL already exists in raw/
- Ask user: update existing or create new version?

## Output Format

After successful ingest, report:

```
🤖 Done:
- Saved: raw/{category}/{slug}.md
- Assets: {N} files to raw/assets/
- Summary: wiki/summaries/{slug}.md
- Entities updated: {list}
- Concepts updated: {list}
- Log entry added
```
