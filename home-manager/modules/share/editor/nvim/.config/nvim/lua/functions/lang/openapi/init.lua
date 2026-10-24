local M = {}
local schema = require("functions.lang.openapi.schema")

---Recover the cursor's mapping/sequence path without relying on indentation widths.
---@param bufnr integer
---@return (string|integer)[] path
local function cursor_path(bufnr)
  local parser = vim.treesitter.get_parser(bufnr, "yaml")
  parser:parse()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local first = (vim.api.nvim_get_current_line():find("%S") or 1) - 1
  local node = vim.treesitter.get_node({ bufnr = bufnr, pos = { cursor[1] - 1, math.max(cursor[2], first) } })
  local path = {}
  while node do
    local kind = node:type()
    if kind == "block_mapping_pair" or kind == "flow_pair" then
      local key = node:field("key")[1]
      if key then
        local text = vim.treesitter.get_node_text(key, bufnr)
        local decoded = text:match("^['\"]") and schema.decode_yaml(text) or text
        table.insert(path, 1, tostring(decoded))
      end
    elseif
      kind == "block_sequence_item" or (node:parent() and node:parent():type() == "flow_sequence" and node:named())
    then
      local index = 1
      local previous = node:prev_named_sibling()
      while previous do
        if previous:type() ~= "comment" then
          index = index + 1
        end
        previous = previous:prev_named_sibling()
      end
      table.insert(path, 1, index)
    end
    node = node:parent()
  end
  return path
end

---Identify schema roots and descend only through schema-bearing keywords.
---@param path (string|integer)[]
---@return integer|nil length of the nearest schema path
local function schema_length(path)
  local length
  if path[1] == "components" and path[2] == "schemas" and path[3] then
    length = 3
  end
  for index, key in ipairs(path) do
    if
      key == "schema"
      and (
        path[index - 1] == "application/json"
        or tostring(path[index - 1]):match("%+json$")
        or path[index - 2] == "parameters"
        or path[index - 2] == "headers"
      )
    then
      length = index
    end
  end
  if not length then
    return
  end
  local index = length + 1
  while index <= #path do
    local key = path[index]
    if
      (key == "properties" or key == "$defs" or key == "definitions" or key == "patternProperties") and path[index + 1]
    then
      length = index + 1
      index = index + 2
    elseif key == "items" or key == "additionalProperties" or key == "not" then
      length = index
      index = index + 1
    elseif
      (key == "allOf" or key == "oneOf" or key == "anyOf" or key == "prefixItems")
      and type(path[index + 1]) == "number"
    then
      length = index + 1
      index = index + 2
    else
      break
    end
  end
  return length
end

---Create a payload from the nearest schema in an OpenAPI 3.x document.
---@param document OpenApiDocument
---@param path (string|integer)[] cursor path
---@return OpenApiValue|nil value nil means use ordinary LSP hover
---@return string[] notes
function M.preview(document, path)
  if type(document.value) ~= "table" or not tostring(document.value.openapi):match("^3%.") then
    return nil, {}
  end
  ---@type OpenApiContext
  local context = { documents = { [document.filename] = document }, notes = {}, active = {} }
  local length = schema_length(path)
  local value = document.value
  if length then
    for index = 1, length do
      if type(value) ~= "table" then
        return nil, {}
      end
      value = value[path[index]]
    end
  else
    -- Only body-related locations may select a media type implicitly.
    local body = path[1] == "components" and (path[2] == "requestBodies" or path[2] == "responses")
    for _, key in ipairs(path) do
      if key == "requestBody" or key == "responses" then
        body = true
      end
    end
    if not body then
      return nil, {}
    end
    for index, key in ipairs(path) do
      local media = path[index + 1]
      if
        key == "content"
        and type(media) == "string"
        and media ~= "application/json"
        and not media:match("%+json$")
      then
        return nil, {}
      end
    end
    local candidates = { value }
    for _, key in ipairs(path) do
      if type(value) ~= "table" then
        break
      end
      value = value[key]
      if value == nil then
        break
      end
      candidates[#candidates + 1] = value
    end
    value = nil
    for index = #candidates, 1, -1 do
      value, document = schema.body_schema(candidates[index], document, context, 0)
      if value then
        break
      end
    end
  end
  if value == nil then
    if #context.notes > 0 then
      return vim.NIL, context.notes
    end
    return nil, context.notes
  end
  return schema.example(value, document, context, 0), context.notes
end

---@class OpenApiPopup
---@field lines string[]
---@field notes string[]
---@field syntax 'json'|'http'

---Show an operation exchange or schema example, preserving ordinary LSP hover elsewhere.
---@return nil
function M.hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, popup = pcall(function()
    local document = {
      value = schema.decode_yaml(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")),
      filename = vim.api.nvim_buf_get_name(bufnr),
    }
    local path = cursor_path(bufnr)
    local lines, notes = require("functions.lang.openapi.operation").preview(document, path)
    if lines then
      return { lines = lines, notes = notes, syntax = "http" }
    end
    local value
    value, notes = M.preview(document, path)
    if value == nil then
      return nil
    end
    return { lines = schema.format_json(value), notes = notes, syntax = "json" }
  end)
  if not ok then
    vim.notify("OpenAPI preview: " .. tostring(popup), vim.log.levels.WARN)
    return
  end
  if not popup then
    vim.lsp.buf.hover()
    return
  end
  local lines, notes = popup.lines, popup.notes
  local float_bufnr, win = vim.lsp.util.open_floating_preview(lines, popup.syntax, {
    focus_id = "openapi-example",
    border = "rounded",
    max_width = 100,
    max_height = math.max(1, math.floor(vim.o.lines * 0.7)),
    title = popup.syntax == "http" and " OpenAPI operation (illustrative; not sent) "
      or " OpenAPI example (illustrative) ",
  })
  vim.bo[float_bufnr].filetype = popup.syntax
  -- Notes use virtual lines, keeping explanations separate from copyable examples.
  local virtual = {}
  for _, message in ipairs(notes) do
    virtual[#virtual + 1] = { { message, "DiagnosticWarn" } }
  end
  local namespace = vim.api.nvim_create_namespace("openapi-example")
  vim.api.nvim_buf_clear_namespace(float_bufnr, namespace, 0, -1)
  if #virtual > 0 then
    vim.api.nvim_buf_set_extmark(float_bufnr, namespace, #lines - 1, 0, { virt_lines = virtual })
    vim.api.nvim_win_set_height(win, math.min(#lines + #notes, math.max(1, math.floor(vim.o.lines * 0.7))))
  end
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = float_bufnr, silent = true, desc = "Close OpenAPI example" })
  end
end

return M
