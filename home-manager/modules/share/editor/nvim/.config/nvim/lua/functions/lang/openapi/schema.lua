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
  if type(value.schema) == "table" or value.example ~= nil or type(value.examples) == "table" then
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

---Format a JSON value without fx's raw-string output or terminal UI.
---@param value OpenApiValue
---@return string[] lines
function M.format_json(value)
  local result = vim
    .system({ "fx", "--no-tui", "JSON.stringify(x, null, 2)" }, {
      stdin = vim.json.encode(value),
      text = true,
    })
    :wait(2000)
  if result.code ~= 0 then
    error("Cannot format OpenAPI example: " .. (result.stderr or "fx timed out"))
  end
  return vim.split(vim.trim(result.stdout), "\n", { plain = true })
end

M.decode_yaml = decode_yaml
M.resolve = resolve
M.note = note
M.example = example
M.body_schema = body_schema

return M
