local icons = require("config.constants").icons

local ignored_client_names = {
  copilot = true,
}

local M = {
  progress = {},
}

local function redraw_statusline()
  if vim.cmd ~= nil and type(vim.cmd.redrawstatus) == "function" then
    vim.cmd.redrawstatus()
  end
end

---@param bufnr integer
---@return vim.lsp.Client[]
local function get_ready_clients(bufnr)
  if vim.lsp == nil or type(vim.lsp.get_clients) ~= "function" then
    return {}
  end

  local ok, clients = pcall(vim.lsp.get_clients, { bufnr = bufnr })
  if not ok or type(clients) ~= "table" then
    return {}
  end

  local ready_clients = {}
  for _, client in ipairs(clients) do
    if
      type(client) == "table"
      and client.initialized ~= false
      and type(client.name) == "string"
      and client.name ~= ""
      and not ignored_client_names[client.name]
    then
      table.insert(ready_clients, client)
    end
  end

  table.sort(ready_clients, function(left, right)
    return left.name < right.name
  end)

  return ready_clients
end

---@param text string
---@return string
local function escape_statusline_text(text)
  local escaped = text:gsub("%%", "%%%%")
  return escaped
end

---@param client vim.lsp.Client
---@param progress { percentage?: number }|nil
---@return string
local function format_client_status(client, progress)
  local label = string.format("%s %s", icons.lsp.ready, escape_statusline_text(client.name))
  if type(progress) == "table" and progress.percentage ~= nil then
    return string.format("%s (%d%%%%)", label, progress.percentage)
  end

  return label
end

---@param segments string[]
---@return string
local function join_segments(segments)
  local result = {}

  for _, segment in ipairs(segments) do
    if segment ~= "" then
      table.insert(result, segment)
    end
  end

  return table.concat(result, " ")
end

---@param ev { data?: { client_id?: integer, params?: { value?: unknown } } }
function M.update(ev)
  local data = type(ev) == "table" and ev.data or nil
  local client_id = type(data) == "table" and data.client_id or nil
  local params = type(data) == "table" and data.params or nil
  local value = type(params) == "table" and params.value or nil
  if type(client_id) ~= "number" or type(value) ~= "table" then
    return
  end

  if value.kind == "end" then
    M.progress[client_id] = nil
    redraw_statusline()
    return
  end

  M.progress[client_id] = {
    percentage = type(value.percentage) == "number" and math.floor(value.percentage) or nil,
  }
  redraw_statusline()
end

---@param bufnr? integer
---@return string
function M.get_statusline(bufnr)
  local client_segments = {}

  for _, client in ipairs(get_ready_clients(bufnr or 0)) do
    table.insert(client_segments, format_client_status(client, M.progress[client.id]))
  end

  return join_segments(client_segments)
end

function M.setup()
  local group = vim.api.nvim_create_augroup("config.lsp.status", { clear = true })

  vim.api.nvim_create_autocmd("LspProgress", {
    callback = function(ev)
      M.update(ev)
    end,
    desc = "[config.lsp] update statusline progress",
    group = group,
  })

  vim.api.nvim_create_autocmd({ "LspAttach", "LspDetach" }, {
    callback = redraw_statusline,
    desc = "[config.lsp] redraw statusline when LSP clients change",
    group = group,
  })
end

return M
