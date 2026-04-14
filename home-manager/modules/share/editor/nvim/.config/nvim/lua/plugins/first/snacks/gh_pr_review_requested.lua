local SEARCH_JSON_FIELDS = {
  "author",
  "isDraft",
  "labels",
  "number",
  "repository",
  "state",
  "title",
  "updatedAt",
  "url",
}

local state_by_picker = setmetatable({}, { __mode = "k" })

local State = {}
State.__index = State

---@return table
local function new_state()
  return setmetatable({
    cache_key = nil,
    picker_items = nil,
  }, State)
end

---@param left string[]
---@param right string[]
---@return string[]
local function concat_lists(left, right)
  local result = {}

  for _, value in ipairs(left) do
    table.insert(result, value)
  end

  for _, value in ipairs(right) do
    table.insert(result, value)
  end

  return result
end

---@param search_query string|nil
---@param repo_name string|nil
---@return string[]
local function build_args(search_query, repo_name)
  local args = { "search", "prs" }
  if search_query and search_query ~= "" then
    if search_query:sub(1, 1) == "-" then
      table.insert(args, "--")
    end
    table.insert(args, search_query)
  end

  local filters = {
    "--review-requested",
    "@me",
    "--state",
    "open",
  }
  if repo_name and repo_name ~= "" then
    table.insert(filters, "--repo")
    table.insert(filters, repo_name)
  end
  table.insert(filters, "--json")
  table.insert(filters, table.concat(SEARCH_JSON_FIELDS, ","))

  return concat_lists(args, filters)
end

---@param repository table|nil
---@return string|nil
local function get_repo_name(repository)
  if type(repository) ~= "table" then
    return nil
  end

  if repository.nameWithOwner and repository.nameWithOwner ~= "" then
    return repository.nameWithOwner
  end

  if repository.fullName and repository.fullName ~= "" then
    return repository.fullName
  end

  local owner = type(repository.owner) == "table" and (repository.owner.login or repository.owner.name) or nil
  if owner and repository.name then
    return owner .. "/" .. repository.name
  end

  return nil
end

---@param author table|nil
---@return string|nil
local function get_author_login(author)
  if type(author) ~= "table" then
    return nil
  end

  return author.login or author.name or author.username
end

---@param author table|nil
---@return boolean
local function is_bot(author)
  if type(author) ~= "table" then
    return false
  end

  return author.is_bot == true or author.isBot == true
end

---@param labels table[]|nil
---@return table[]
local function normalize_labels(labels)
  local normalized_labels = {}
  if type(labels) ~= "table" then
    return normalized_labels
  end

  for _, label in ipairs(labels) do
    if type(label) == "table" and label.name then
      table.insert(normalized_labels, {
        color = label.color,
        name = label.name,
      })
    end
  end

  return normalized_labels
end

---@param labels table[]
---@return string
local function join_label_names(labels)
  local names = {}

  for _, label in ipairs(labels) do
    if type(label) == "table" and label.name then
      table.insert(names, label.name)
    end
  end

  return table.concat(names, ",")
end

---@param values (string|nil)[]
---@return string
local function join_non_empty(values)
  local result = {}
  for _, value in ipairs(values) do
    if type(value) == "string" and value ~= "" then
      table.insert(result, value)
    end
  end

  return table.concat(result, " ")
end

---@param search_result table
---@return table|nil
local function to_picker_item(search_result)
  local repo_name = get_repo_name(search_result.repository)
  if not repo_name or not search_result.number then
    return nil
  end

  local author_login = get_author_login(search_result.author)
  local normalized_labels = normalize_labels(search_result.labels)
  local label_text = join_label_names(normalized_labels)
  local hash = "#" .. tostring(search_result.number)
  local status = type(search_result.state) == "string" and search_result.state:lower() or nil
  local uri = ("gh://%s/pr/%s"):format(repo_name, tostring(search_result.number))
  local normalized_item = {
    author = author_login and { is_bot = is_bot(search_result.author), login = author_login } or nil,
    isDraft = search_result.isDraft == true,
    labels = normalized_labels,
    number = search_result.number,
    state = search_result.state,
    title = search_result.title,
    updatedAt = search_result.updatedAt,
    url = search_result.url,
  }

  return {
    author = author_login,
    draft = search_result.isDraft == true,
    file = uri,
    hash = hash,
    isDraft = search_result.isDraft == true,
    item = normalized_item,
    label = label_text ~= "" and label_text or nil,
    number = search_result.number,
    repo = repo_name,
    state = status,
    status = search_result.isDraft == true and "draft" or status,
    text = join_non_empty({ search_result.title, author_login, hash, label_text, repo_name }),
    title = search_result.title,
    type = "pr",
    uri = uri,
    url = search_result.url,
  }
end

---@param raw_output string
---@return table[]
local function decode_search_results(raw_output)
  if raw_output == "" then
    return {}
  end

  local ok, decoded_results = pcall(vim.json.decode, raw_output)
  if not ok or type(decoded_results) ~= "table" then
    return {}
  end

  local picker_items = {}
  for _, search_result in ipairs(decoded_results) do
    local picker_item = to_picker_item(search_result)
    if picker_item then
      table.insert(picker_items, picker_item)
    end
  end

  return picker_items
end

---@param picker table
---@return table
local function get_state(picker)
  if not state_by_picker[picker] then
    state_by_picker[picker] = new_state()
  end

  return state_by_picker[picker]
end

---@param opts snacks.picker.gh.pr.Config
---@param ctx snacks.picker.finder.ctx
---@return table[]
local function get_picker_items(opts, ctx)
  local picker = ctx.picker or ctx
  local state = get_state(picker)
  local cache_key = tostring(opts.repo or "")
  if state.cache_key == cache_key and state.picker_items then
    return state.picker_items
  end

  local raw_chunks = {}
  require("snacks.picker.source.proc").proc({
    args = build_args(nil, opts.repo),
    cmd = "gh",
    notify = true,
    raw = true,
  }, ctx)(function(item)
    table.insert(raw_chunks, item.text or "")
  end)

  state.cache_key = cache_key
  state.picker_items = decode_search_results(table.concat(raw_chunks))
  return state.picker_items
end

---@param opts snacks.picker.gh.pr.Config
---@param ctx snacks.picker.finder.ctx
---@return snacks.picker.finder
local function finder(opts, ctx)
  return function(cb)
    for _, picker_item in ipairs(get_picker_items(opts, ctx)) do
      cb(picker_item)
    end
  end
end

---@class dotfiles.snacks_gh_pr_review_requested.OpenOpts
---@field all_repos boolean|nil fetch PRs from all repositories instead of just the current one. Ignored if `repo` is provided.
---@field repo string|nil fetch PRs from this repository. Should be in the format "owner/repo". If not provided, defaults to the current repository. If `all_repos` is true, this is ignored.

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

  Snacks.picker.gh_pr_review_requested(picker_opts)
end

local M = {}
M.build_args = build_args
M.to_picker_item = to_picker_item
M.decode_search_results = decode_search_results
M.finder = finder
M.open = open
return M
