local gh_search_prs = require("plugins.first.snacks.gh_search_prs")

local DEFAULT_LIMIT = 1000 -- GitHub search returns at most 1000 results.
local SEARCH_FILTERS = {
  "--author",
  "@me",
  "--state",
  "open",
}

---@param search_query string|nil
---@param repo_name string|nil
---@param limit number|string|nil
---@return string[]
local function build_args(search_query, repo_name, limit)
  return gh_search_prs.build_args(search_query, SEARCH_FILTERS, repo_name, limit)
end

local finder = gh_search_prs.create_finder(function(opts)
  return build_args(nil, opts.repo, opts.limit or DEFAULT_LIMIT)
end, function(opts)
  return table.concat({
    tostring(opts.repo or ""),
    tostring(opts.limit or DEFAULT_LIMIT),
  }, ":")
end)

---@class dotfiles.snacks_gh_pr_authored.OpenOpts
---@field repo string|nil fetch PRs from this repository. If not provided, fetch across all repositories.
---@field limit number|nil maximum number of PRs to fetch. Defaults to GitHub search's 1000-result cap.

---Open the "My Pull Requests" picker.
---@param opts dotfiles.snacks_gh_pr_authored.OpenOpts|nil
local function open(opts)
  opts = opts or {}

  local picker_opts = {
    limit = opts.limit or DEFAULT_LIMIT,
  }
  if opts.repo and opts.repo ~= "" then
    picker_opts.repo = opts.repo
  end

  Snacks.picker.gh_pr_authored(picker_opts)
end

local M = {}
M.DEFAULT_LIMIT = DEFAULT_LIMIT
M.build_args = build_args
M.finder = finder
M.gh_actions = gh_search_prs.gh_actions
M.open = open
return M
