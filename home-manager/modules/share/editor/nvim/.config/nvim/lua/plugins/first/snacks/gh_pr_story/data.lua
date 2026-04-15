local story = require("plugins.first.snacks.gh_pr_story.story")
local util = require("plugins.first.snacks.gh_pr_story.util")

local GH_TIMEOUT_MS = 120000
local PR_VIEW_FIELDS = {
  "additions",
  "author",
  "baseRefName",
  "body",
  "changedFiles",
  "deletions",
  "headRefName",
  "number",
  "title",
  "url",
}

local M = {}

local function shallow_copy(item)
  local copy = {}
  for key, value in pairs(item or {}) do
    copy[key] = value
  end
  return copy
end

local function warn(message)
  util.schedule_notify("gh_pr_story: " .. message, vim.log.levels.WARN)
end

local function with_repo(args, repo)
  if repo then
    table.insert(args, "--repo")
    table.insert(args, repo)
  end

  return args
end

local function fancy_previewers(previewers)
  previewers = shallow_copy(previewers)
  previewers.diff = shallow_copy(previewers.diff)
  previewers.diff.style = "fancy"
  return previewers
end

function M.fetch_pr_metadata(opts)
  if not opts.pr then
    return nil, "PR id is required"
  end

  local stdout, error_message = util.run_command(with_repo({
    "gh",
    "pr",
    "view",
    tostring(opts.pr),
    "--json",
    table.concat(PR_VIEW_FIELDS, ","),
  }, opts.repo), {
    timeout_ms = GH_TIMEOUT_MS,
  })
  if not stdout then
    return nil, error_message
  end

  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok or type(decoded) ~= "table" then
    return nil, "Failed to decode PR metadata"
  end

  local author = decoded.author
  if type(author) == "table" then
    author = author.login or author.name or author.username
  end

  return {
    additions = tonumber(decoded.additions) or 0,
    author = type(author) == "string" and author or "unknown",
    base = decoded.baseRefName or "unknown",
    body = type(decoded.body) == "string" and decoded.body or "",
    changed_files = tonumber(decoded.changedFiles) or 0,
    deletions = tonumber(decoded.deletions) or 0,
    head = decoded.headRefName or "unknown",
    number = tonumber(decoded.number) or tonumber(opts.pr) or 0,
    repo = opts.repo,
    title = decoded.title or ("PR #%s"):format(tostring(opts.pr)),
    url = decoded.url
      or ((opts.repo and opts.pr) and ("https://github.com/%s/pull/%s"):format(opts.repo, tostring(opts.pr)) or ""),
  }, nil
end

function M.fetch_pr_diff(opts)
  if not opts.pr then
    return nil, "PR id is required"
  end

  return util.run_command(with_repo({
    "gh",
    "pr",
    "diff",
    tostring(opts.pr),
  }, opts.repo), {
    timeout_ms = GH_TIMEOUT_MS,
  })
end

function M.fallback_metadata(metadata, opts)
  metadata = metadata or {}
  local repo = metadata.repo or opts.repo
  local pr = tonumber(metadata.number) or tonumber(opts.pr) or 0

  return {
    additions = tonumber(metadata.additions) or 0,
    author = metadata.author or "unknown",
    base = metadata.base or "unknown",
    body = metadata.body or "",
    changed_files = tonumber(metadata.changed_files) or 0,
    deletions = tonumber(metadata.deletions) or 0,
    head = metadata.head or "unknown",
    number = pr,
    repo = repo,
    title = metadata.title or ("PR #%s"):format(tostring(pr)),
    url = metadata.url or (repo and pr > 0 and ("https://github.com/%s/pull/%d"):format(repo, pr) or ""),
  }
end

local function get_gh_item(opts)
  local api_item = require("snacks.gh.api").get({
    number = opts.pr,
    repo = opts.repo,
    type = "pr",
  }, {
    -- `comments` forces the GraphQL fetch that also returns `viewerDidAuthor`,
    -- which snacks uses to detect an existing pending review.
    fields = { "comments" },
  })

  return api_item, api_item or {
    number = opts.pr,
    repo = opts.repo,
    type = "pr",
  }
end

local function get_annotations(api_item, ctx)
  if not api_item then
    return {}
  end

  if ctx.async and ctx.async.schedule then
    return ctx.async:schedule(function()
      return require("snacks.gh.render").annotations(api_item)
    end)
  end

  return require("snacks.gh.render").annotations(api_item)
end

local function build_diff_items(opts, ctx, diff_text)
  if not diff_text or diff_text == "" then
    return {}
  end

  local api_item, gh_item = get_gh_item(opts)
  local diff_items = {}
  local diff_opts = {
    annotations = get_annotations(api_item, ctx),
    cwd = ctx.git_root and ctx:git_root() or nil,
    diff = diff_text,
    group = true,
    previewers = fancy_previewers(opts.previewers),
  }

  if ctx.opts then
    diff_opts = ctx:opts(diff_opts)
  end

  require("snacks.picker.source.diff").diff(diff_opts, ctx)(function(item)
    item.gh_item = gh_item
    table.insert(diff_items, item)
  end)

  return diff_items
end

local function build_story(metadata, diff_items, diff_text, diff_error)
  if not diff_text or diff_text == "" then
    return story.fallback_story(diff_items, diff_error or "Failed to fetch PR diff")
  end

  local actual_story, story_error = story.generate_story(metadata, diff_items, diff_text)
  if actual_story then
    return actual_story
  end

  warn(("%s. Falling back to a single chapter."):format(story_error or "Unknown PI failure"))
  return story.fallback_story(diff_items, story_error)
end

function M.get_review_data(opts, ctx)
  local diff_text, diff_error = M.fetch_pr_diff(opts)
  local metadata, metadata_error = M.fetch_pr_metadata(opts)
  metadata = M.fallback_metadata(metadata, opts)

  local diff_items = build_diff_items(opts, ctx, diff_text)
  if #diff_items > 0 then
    metadata.changed_files = #diff_items
  end

  if metadata_error and metadata_error ~= "" then
    warn(("%s. Using minimal PR metadata."):format(metadata_error))
  end
  if diff_error and diff_error ~= "" and (not diff_text or diff_text == "") then
    warn(diff_error)
  end

  local review_story = build_story(metadata, diff_items, diff_text, diff_error)
  return {
    diff_items = diff_items,
    diff_text = diff_text or "",
    metadata = metadata,
    story = story.normalize_story(review_story, diff_items),
  }
end

return M
