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

local M = {}

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
---@param filters string[]
---@param repo_name string|nil
---@param limit number|string|nil
---@return string[]
function M.build_args(search_query, filters, repo_name, limit)
  local args = { "search", "prs" }
  if search_query and search_query ~= "" then
    if search_query:sub(1, 1) == "-" then
      table.insert(args, "--")
    end
    table.insert(args, search_query)
  end

  local final_filters = concat_lists(filters, {})
  if repo_name and repo_name ~= "" then
    table.insert(final_filters, "--repo")
    table.insert(final_filters, repo_name)
  end

  if limit ~= nil and tostring(limit) ~= "" then
    table.insert(final_filters, "--limit")
    table.insert(final_filters, tostring(limit))
  end

  table.insert(final_filters, "--json")
  table.insert(final_filters, table.concat(SEARCH_JSON_FIELDS, ","))

  return concat_lists(args, final_filters)
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
function M.to_picker_item(search_result)
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
function M.decode_search_results(raw_output)
  if raw_output == "" then
    return {}
  end

  local ok, decoded_results = pcall(vim.json.decode, raw_output)
  if not ok or type(decoded_results) ~= "table" then
    return {}
  end

  local picker_items = {}
  for _, search_result in ipairs(decoded_results) do
    local picker_item = M.to_picker_item(search_result)
    if picker_item then
      table.insert(picker_items, picker_item)
    end
  end

  return picker_items
end

local function ensure_gh_item(item)
  if not item or item.gh_item or not item.repo or not item.number then
    return item and item.gh_item or nil
  end

  item.gh_item = require("snacks.gh.api").get({
    number = item.number,
    repo = item.repo,
    type = item.type or "pr",
  }, {
    fields = { "comments" },
  })

  return item.gh_item
end

function M.gh_actions(picker, item, action)
  ensure_gh_item(item)

  local gh_actions = require("snacks.picker.source.gh").actions.gh_actions
  if gh_actions and gh_actions.action then
    return gh_actions.action(picker, item, action)
  end
end

---@param build_args_fn fun(opts: table): string[]
---@param get_cache_key fun(opts: table): string
---@return snacks.picker.finder
function M.create_finder(build_args_fn, get_cache_key)
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

  ---@param picker table
  ---@return table
  local function get_state(picker)
    if not state_by_picker[picker] then
      state_by_picker[picker] = new_state()
    end

    return state_by_picker[picker]
  end

  ---@param opts table|nil
  ---@param ctx snacks.picker.finder.ctx
  ---@return table[]
  local function get_picker_items(opts, ctx)
    opts = opts or {}
    local picker = ctx.picker or ctx
    local state = get_state(picker)
    local cache_key = get_cache_key(opts)
    if state.cache_key == cache_key and state.picker_items then
      return state.picker_items
    end

    local raw_chunks = {}
    require("snacks.picker.source.proc").proc({
      args = build_args_fn(opts),
      cmd = "gh",
      notify = true,
      raw = true,
    }, ctx)(function(item)
      table.insert(raw_chunks, item.text or "")
    end)

    state.cache_key = cache_key
    state.picker_items = M.decode_search_results(table.concat(raw_chunks))
    return state.picker_items
  end

  return function(opts, ctx)
    return function(cb)
      for _, picker_item in ipairs(get_picker_items(opts, ctx)) do
        cb(picker_item)
      end
    end
  end
end

M.ensure_gh_item = ensure_gh_item
return M
