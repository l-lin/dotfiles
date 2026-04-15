local gh_search_prs = require("plugins.first.snacks.gh_search_prs")

local SEARCH_FILTERS = {
  "--review-requested",
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
  return build_args(nil, opts.repo, opts.limit)
end, function(opts)
  return table.concat({
    tostring(opts.repo or ""),
    tostring(opts.limit or ""),
  }, ":")
end)

---@class dotfiles.snacks_gh_pr_review_requested.OpenOpts
---@field all_repos boolean|nil fetch PRs from all repositories instead of just the current one. Ignored if `repo` is provided.
---@field repo string|nil fetch PRs from this repository. Should be in the format "owner/repo". If not provided, defaults to the current repository. If `all_repos` is true, this is ignored.
---@field limit number|nil maximum number of PRs to fetch.

---Open the "PRs Review Requested" picker.
---@param opts dotfiles.snacks_gh_pr_review_requested.OpenOpts|nil
local function open(opts)
  opts = opts or {}

  local picker_opts = {}
  if opts.repo and opts.repo ~= "" then
    picker_opts.repo = opts.repo
  elseif not opts.all_repos then
    local current_repo_name = require("functions.git").get_current_repo_name()
    if not current_repo_name then
      vim.notify("Not in a git repository", vim.log.levels.ERROR)
      return
    end

    picker_opts.repo = current_repo_name
  end

  if opts.limit then
    picker_opts.limit = opts.limit
  end

  Snacks.picker.gh_pr_review_requested(picker_opts)
end

local M = {}
M.build_args = build_args
M.to_picker_item = gh_search_prs.to_picker_item
M.decode_search_results = gh_search_prs.decode_search_results
M.finder = finder
M.gh_actions = gh_search_prs.gh_actions
M.open = open
return M
