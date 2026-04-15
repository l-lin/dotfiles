local util = require("plugins.first.snacks.gh_pr_story.util")

local STORY_MODEL = "anthropic/claude-sonnet-4-6"
local PI_CACHE_DIR_NAME = "gh_pr_story_pi"
local PI_TIMEOUT_MS = 300000
local DEFAULT_FALLBACK_CHAPTER_ID = "chapter-1"
local UNASSIGNED_CHAPTER_ID = "chapter-unassigned"
local DIRECTORY_MODE = 448
local PROMPT_FILE_TEMPLATE = "gh_pr_story_prompt.XXXXXX"

local M = {}

local function uv_api()
  return assert(vim.uv or vim.loop, "libuv is required for gh_pr_story")
end

local function ensure_pi_cache_dir()
  local uv = uv_api()
  local path = util.join_path(uv.os_tmpdir() or "/tmp", PI_CACHE_DIR_NAME)
  if uv.fs_stat(path) then
    return path, nil
  end

  local ok, error_message = uv.fs_mkdir(path, DIRECTORY_MODE)
  if ok or uv.fs_stat(path) then
    return path, nil
  end

  return nil, error_message or ("Failed to create %s"):format(path)
end

local function write_prompt_file(prompt_text)
  local uv = uv_api()
  local fd, path_or_error = uv.fs_mkstemp(util.join_path(uv.os_tmpdir() or "/tmp", PROMPT_FILE_TEMPLATE))
  if not fd then
    return nil, path_or_error or "Failed to create prompt file"
  end

  local path = path_or_error
  local written, write_error = uv.fs_write(fd, prompt_text, -1)
  local closed, close_error = uv.fs_close(fd)
  if not written or written < #prompt_text then
    pcall(os.remove, path)
    return nil, write_error or "Failed to write prompt file"
  end
  if not closed then
    pcall(os.remove, path)
    return nil, close_error or "Failed to close prompt file"
  end

  return path, nil
end

function M.build_pi_command(prompt_path)
  local pi_bin = vim.fn and vim.fn.exepath and vim.fn.exepath("pi") or ""
  if pi_bin == "" then
    pi_bin = "pi"
  end

  return {
    pi_bin,
    "--models",
    STORY_MODEL,
    "--no-session",
    "-p",
    "@" .. prompt_path,
  }
end

function M.decode_story(story_raw)
  if type(story_raw) ~= "string" or story_raw == "" then
    return nil
  end

  local function decode_json(raw)
    local ok, decoded = pcall(vim.json.decode, raw)
    if ok and type(decoded) == "table" then
      return decoded
    end
  end

  local decoded = decode_json(story_raw)
  if not decoded then
    local fenced = story_raw:match("```json%s*(.-)%s*```") or story_raw:match("```%s*(.-)%s*```")
    decoded = fenced and decode_json(fenced) or nil
  end

  if not decoded then
    local first_brace = story_raw:find("{")
    local last_brace = story_raw:reverse():find("}")
    if first_brace and last_brace then
      last_brace = #story_raw - last_brace + 1
      decoded = decode_json(story_raw:sub(first_brace, last_brace))
    end
  end

  if type(decoded) ~= "table" then
    return nil
  end

  local chapters = {}
  local chapter_index = 0
  for _, chapter in ipairs(type(decoded.chapters) == "table" and decoded.chapters or {}) do
    if type(chapter) == "table" then
      chapter_index = chapter_index + 1
      local files = {}
      for _, file in ipairs(type(chapter.files) == "table" and chapter.files or {}) do
        local path = nil
        if type(file) == "string" then
          path = file
        elseif type(file) == "table" then
          path = file.path or file.file or file.filename
        end

        if type(path) == "string" and path ~= "" then
          table.insert(files, path)
        end
      end

      table.insert(chapters, {
        id = type(chapter.id) == "string" and chapter.id or ("chapter-%d"):format(chapter_index),
        title = type(chapter.title) == "string" and chapter.title or ("Chapter %d"):format(chapter_index),
        narrative = type(chapter.narrative) == "string" and chapter.narrative
          or type(chapter.review) == "string" and chapter.review
          or type(chapter.story) == "string" and chapter.story
          or "",
        files = files,
      })
    end
  end

  return {
    summary = type(decoded.summary) == "string" and decoded.summary or "",
    chapters = chapters,
  }
end

function M.fallback_story(diff_items, reason)
  local files = {}
  for _, diff_item in ipairs(diff_items) do
    table.insert(files, diff_item.file)
  end

  local summary = "Review the full diff in a single pass."
  local narrative = "The full pull request remains in one chapter."
  if reason and reason ~= "" then
    summary = ("Automatic chaptering failed: %s"):format(reason)
    narrative = summary .. " Review the raw file diff directly."
  end

  return {
    summary = summary,
    chapters = {
      {
        id = DEFAULT_FALLBACK_CHAPTER_ID,
        title = "Entire Diff",
        narrative = narrative,
        files = files,
      },
    },
  }
end

function M.normalize_story(story, diff_items)
  local diff_by_file = {}
  local diff_files = {}
  for _, diff_item in ipairs(diff_items) do
    if type(diff_item.file) == "string" and diff_item.file ~= "" and not diff_by_file[diff_item.file] then
      diff_by_file[diff_item.file] = diff_item
      table.insert(diff_files, diff_item.file)
    end
  end

  local normalized_chapters = {}
  local assigned_files = {}
  for index, chapter in ipairs(type(story) == "table" and story.chapters or {}) do
    if type(chapter) == "table" then
      local normalized_files = {}
      for _, file in ipairs(type(chapter.files) == "table" and chapter.files or {}) do
        if diff_by_file[file] and not assigned_files[file] then
          table.insert(normalized_files, file)
          assigned_files[file] = true
        end
      end

      if #normalized_files > 0 then
        table.insert(normalized_chapters, {
          id = type(chapter.id) == "string" and chapter.id or ("chapter-%d"):format(index),
          title = type(chapter.title) == "string" and chapter.title or ("Chapter %d"):format(index),
          narrative = type(chapter.narrative) == "string" and chapter.narrative or "",
          files = normalized_files,
        })
      end
    end
  end

  if #diff_files == 0 then
    for index, chapter in ipairs(type(story) == "table" and story.chapters or {}) do
      if type(chapter) == "table" then
        table.insert(normalized_chapters, {
          id = type(chapter.id) == "string" and chapter.id or ("chapter-%d"):format(index),
          title = type(chapter.title) == "string" and chapter.title or ("Chapter %d"):format(index),
          narrative = type(chapter.narrative) == "string" and chapter.narrative or "",
          files = {},
        })
      end
    end
  end

  local unassigned_files = {}
  for _, file in ipairs(diff_files) do
    if not assigned_files[file] then
      table.insert(unassigned_files, file)
    end
  end

  if #normalized_chapters == 0 and #diff_files > 0 then
    normalized_chapters = M.fallback_story(diff_items).chapters
    unassigned_files = {}
  end

  if #unassigned_files > 0 then
    table.insert(normalized_chapters, {
      id = UNASSIGNED_CHAPTER_ID,
      title = "Unassigned Changes",
      narrative = "These files were not cleanly placed in the main story. Review them together as the remaining thread.",
      files = unassigned_files,
    })
  end

  return {
    summary = type(story) == "table" and type(story.summary) == "string" and story.summary or "",
    chapters = normalized_chapters,
  }
end

function M.build_story_prompt(metadata, diff_items, diff_text)
  local parts = {
    "# Goal",
    "Split this pull request diff into a reviewer-friendly story told as chapters.",
    "",
    "## Voice",
    "Use a Sanderson-adjacent tone: clear epic-fantasy cadence, steady escalation, sharp reveals, restrained wonder, and clean prose.",
    "Do not imitate Brandon Sanderson directly, do not mention him, and do not quote existing works.",
    "",
    "## What to produce",
    "Return JSON only. No markdown fences. No commentary outside the JSON.",
    "Use this exact schema:",
    [[{
  "summary": "<2-3 sentence overview of the PR arc>",
  "chapters": [
    {
      "id": "chapter-1",
      "title": "<short chapter title>",
      "narrative": "<markdown review guidance for this chapter: why it matters, what changed at a high level, and what the reviewer should watch>",
      "files": ["path/to/file.lua"]
    }
  ]
}]],
    "",
    "## Rules",
    "- Use exact repo-relative file paths from the changed-files list.",
    "- Every changed file must appear exactly once across all chapters.",
    "- Prefer 2-7 chapters unless the PR is tiny.",
    "- Group mechanical or cleanup edits together instead of scattering them.",
    "- The narrative should guide a reviewer toward the important ideas, not perform the review for them.",
    "- Keep titles vivid but readable.",
    "",
    ("# Pull Request #%d: %s"):format(metadata.number or 0, metadata.title or "PR"),
    ("Author: %s"):format(metadata.author or "unknown"),
    ("Branch: %s <- %s"):format(metadata.base or "unknown", metadata.head or "unknown"),
    ("URL: %s"):format(metadata.url or ""),
    ("Changes: +%d -%d across %d files"):format(
      metadata.additions or 0,
      metadata.deletions or 0,
      metadata.changed_files or #diff_items
    ),
    "",
  }

  if metadata.body and metadata.body ~= "" then
    table.insert(parts, "## PR Description")
    table.insert(parts, metadata.body)
    table.insert(parts, "")
  end

  table.insert(parts, "## Changed Files")
  for _, diff_item in ipairs(diff_items) do
    table.insert(parts, "- " .. diff_item.file)
  end
  table.insert(parts, "")
  table.insert(parts, "## Diff")
  table.insert(parts, "```diff")
  table.insert(parts, diff_text)
  table.insert(parts, "```")

  return table.concat(parts, "\n")
end

function M.generate_story(metadata, diff_items, diff_text)
  local prompt_text = M.build_story_prompt(metadata, diff_items, diff_text)
  local prompt_path, write_error = write_prompt_file(prompt_text)
  if not prompt_path then
    return nil, write_error or "Failed to create prompt file"
  end

  local pi_cache_dir, cache_error = ensure_pi_cache_dir()
  if not pi_cache_dir then
    pcall(os.remove, prompt_path)
    return nil, cache_error or "Failed to prepare PI cache directory"
  end

  local stdout, command_error = util.run_command(M.build_pi_command(prompt_path), {
    env = { PI_CODING_AGENT_DIR = pi_cache_dir },
    timeout_ms = PI_TIMEOUT_MS,
  })

  pcall(os.remove, prompt_path)

  if not stdout then
    return nil, command_error
  end

  local story = M.decode_story(stdout)
  if not story then
    return nil, "Failed to decode PI chapter output"
  end

  return story, nil
end

M.STORY_MODEL = STORY_MODEL
return M
