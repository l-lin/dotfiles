local M = {}

---@alias OpenApiValue any JSON-compatible value, including vim.NIL
---@class OpenApiDocument
---@field value table
---@field filename string
---@class OpenApiContext
---@field documents table<string, OpenApiDocument>
---@field notes string[]
---@field active table<table, boolean>

---Parse YAML with fx rather than guessing scalar types or YAML alias semantics.
---@param text string
---@return OpenApiValue
local function decode_yaml(text)
  -- fx prints strings raw by default; stringify keeps scalar YAML keys valid JSON.
  local result = vim
    .system({ "fx", "--yaml", "--no-tui", "JSON.stringify(x)" }, { stdin = text, text = true })
    :wait(2000)
  if result.code ~= 0 then
    error("Cannot parse YAML: " .. (result.stderr or "fx timed out"))
  end
  return vim.json.decode(result.stdout)
end

---Read the latest buffer contents, including unsaved changes, before consulting disk.
---@param filename string absolute local filename
---@return OpenApiDocument
local function read_document(filename)
  local canonical = vim.uv.fs_realpath(filename) or filename
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if vim.api.nvim_buf_is_loaded(bufnr) and (vim.uv.fs_realpath(name) or name) == canonical then
      return {
        value = decode_yaml(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")),
        filename = filename,
      }
    end
  end
  return { value = decode_yaml(table.concat(vim.fn.readfile(filename), "\n")), filename = filename }
end

---Keep explanations separate from the JSON so the payload remains copyable.
---@param context OpenApiContext
---@param message string
local function note(context, message)
  if not vim.tbl_contains(context.notes, message) then
    context.notes[#context.notes + 1] = message
  end
end

---Resolve a JSON Pointer without fetching URLs or executing reference text.
---@param ref string
---@param document OpenApiDocument
---@param context OpenApiContext
---@return OpenApiValue target
---@return OpenApiDocument document
local function resolve(ref, document, context)
  local file, fragment = ref:match("^([^#]*)#?(.*)$")
  if file:match("^%a[%w+.-]*:") or file:sub(1, 2) == "//" then
    error("Remote $ref is not supported: " .. ref)
  end
  if file ~= "" then
    file = file:gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
    local filename = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(document.filename), file))
    context.documents[filename] = context.documents[filename] or read_document(filename)
    document = context.documents[filename]
  end
  fragment = fragment:gsub("%%(%x%x)", function(hex)
    return string.char(tonumber(hex, 16))
  end)
  if fragment ~= "" and fragment:sub(1, 1) ~= "/" then
    error("Unsupported $ref anchor: " .. ref)
  end
  local target = document.value
  if fragment ~= "" then
    for token in (fragment:sub(2) .. "/"):gmatch("(.-)/") do
      token = token:gsub("~1", "/"):gsub("~0", "~")
      if type(target) ~= "table" then
        error("Cannot resolve $ref: " .. ref)
      end
      local key = vim.islist(target) and tonumber(token) and tonumber(token) + 1 or token
      target = target[key]
      if target == nil then
        error("Cannot resolve $ref: " .. ref)
      end
    end
  end
  return target, document
end

---Build one illustrative value; this intentionally does not validate constraints.
---@param schema OpenApiValue
---@param document OpenApiDocument
---@param context OpenApiContext
---@param depth integer
---@return OpenApiValue
local function example(schema, document, context, depth)
  if depth > 30 then
    note(context, "Nesting limit reached; null marks omitted values.")
    return vim.NIL
  end
  if type(schema) ~= "table" then
    note(context, "No concrete schema shape; null is a placeholder.")
    return vim.NIL
  end
  if context.active[schema] then
    note(context, "Recursive schema; null marks the recursive value.")
    return vim.NIL
  end
  -- Explicit values must win even when they are false, zero, empty, or JSON null.
  for _, key in ipairs({ "example", "examples", "default", "enum" }) do
    local value = schema[key]
    if value ~= nil then
      if key == "examples" or key == "enum" then
        if type(value) == "table" then
          value = value[1]
        else
          value = nil
        end
      end
      if value ~= nil then
        return vim.deepcopy(value)
      end
    end
  end
  context.active[schema] = true
  local value
  if schema["$ref"] then
    local ok, target, owner = pcall(resolve, schema["$ref"], document, context)
    if ok then
      value = example(target, owner, context, depth + 1)
    else
      note(context, tostring(target) .. "; null marks the unresolved value.")
      value = vim.NIL
    end
  end
  for _, keyword in ipairs({ "oneOf", "anyOf" }) do
    if schema[keyword] and schema[keyword][1] then
      note(context, keyword .. ": showing the first alternative.")
      value = example(schema[keyword][1], document, context, depth + 1)
      break
    end
  end
  if schema.allOf then
    value = value or vim.empty_dict()
    for _, branch in ipairs(schema.allOf) do
      local part = example(branch, document, context, depth + 1)
      if type(value) == "table" and type(part) == "table" and not vim.islist(part) then
        value = vim.tbl_extend("force", value, part)
      else
        value = part
        note(context, "allOf: non-object branches cannot be merged; showing the last value.")
      end
    end
  end
  local kind = schema.type
  if type(kind) == "table" then
    for _, candidate in ipairs(kind) do
      if candidate ~= "null" then
        kind = candidate
        break
      end
    end
  end
  if schema.properties or kind == "object" then
    if type(value) ~= "table" or vim.islist(value) then
      value = vim.empty_dict()
    end
    for name, property in pairs(schema.properties or {}) do
      value[name] = example(property, document, context, depth + 1)
    end
    if not next(value) and type(schema.additionalProperties) == "table" then
      value.additionalProp1 = example(schema.additionalProperties, document, context, depth + 1)
    end
  elseif kind == "array" or schema.items then
    value = { example(schema.items, document, context, depth + 1) }
  elseif value == nil then
    local placeholders = { string = "string", integer = 0, number = 0, boolean = false, null = vim.NIL }
    value = placeholders[kind]
    if value == nil then
      note(context, "No concrete schema shape; null is a placeholder.")
      value = vim.NIL
    end
  end
  context.active[schema] = nil
  return value
end

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
        local decoded = text:match("^['\"]") and decode_yaml(text) or text
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

---Find a JSON body schema on request/response containers, including referenced containers.
---@param value OpenApiValue
---@param document OpenApiDocument
---@param context OpenApiContext
---@param depth integer
---@return table|nil schema
---@return OpenApiDocument document
local function body_schema(value, document, context, depth)
  if depth > 30 then
    note(context, "Recursive or excessively nested body reference; null marks the omitted value.")
    return nil, document
  end
  if type(value) ~= "table" then
    return nil, document
  end
  if value["$ref"] then
    local ok, target, owner = pcall(resolve, value["$ref"], document, context)
    if not ok then
      note(context, tostring(target))
      return nil, document
    end
    return body_schema(target, owner, context, depth + 1)
  end
  if type(value.schema) == "table" then
    if value.example ~= nil then
      return { example = value.example }, document
    end
    if type(value.examples) == "table" then
      local names = vim.fn.sort(vim.tbl_keys(value.examples))
      local explicit = value.examples[names[1]]
      if type(explicit) == "table" and explicit["$ref"] then
        local ok, target = pcall(resolve, explicit["$ref"], document, context)
        if ok then
          explicit = target
        else
          note(context, tostring(target))
        end
      end
      if type(explicit) == "table" and explicit.value ~= nil then
        return { example = explicit.value }, document
      end
    end
    return value.schema, document
  end
  local content = value.content or value
  if type(content) == "table" then
    local media = content["application/json"]
    if not media then
      for _, key in ipairs(vim.fn.sort(vim.tbl_keys(content))) do
        if type(key) == "string" and key:match("%+json$") then
          media = content[key]
          break
        end
      end
    end
    if media then
      return body_schema(media, document, context, depth + 1)
    end
  end
  return nil, document
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
      value, document = body_schema(candidates[index], document, context, 0)
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
  return example(value, document, context, 0), context.notes
end

---Show a focusable JSON example, preserving normal LSP hover outside OpenAPI schemas.
---@return nil
function M.hover()
  local bufnr = vim.api.nvim_get_current_buf()
  local ok, value, notes = pcall(function()
    local document = {
      value = decode_yaml(table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")),
      filename = vim.api.nvim_buf_get_name(bufnr),
    }
    return M.preview(document, cursor_path(bufnr))
  end)
  if not ok then
    vim.notify("OpenAPI preview: " .. tostring(value), vim.log.levels.WARN)
    return
  end
  if value == nil then
    vim.lsp.buf.hover()
    return
  end
  local result = vim
    .system({ "fx", "--no-tui", "JSON.stringify(x, null, 2)" }, {
      stdin = vim.json.encode(value),
      text = true,
    })
    :wait(2000)
  if result.code ~= 0 then
    vim.notify("Cannot format OpenAPI example", vim.log.levels.WARN)
    return
  end
  local lines = vim.split(vim.trim(result.stdout), "\n", { plain = true })
  local float_bufnr, win = vim.lsp.util.open_floating_preview(lines, "json", {
    focus_id = "openapi-example",
    border = "rounded",
    max_width = 100,
    max_height = math.max(1, math.floor(vim.o.lines * 0.7)),
    title = " OpenAPI example (illustrative) ",
  })
  vim.bo[float_bufnr].filetype = "json"
  -- Notes use virtual lines, leaving the JSON buffer valid and easy to copy.
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
