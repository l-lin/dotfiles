local M = {}
local schema = require("functions.lang.openapi.schema")

---@alias OpenApiMethod 'get'|'put'|'post'|'delete'|'options'|'head'|'patch'|'trace'
---@class OpenApiParameter
---@field spec table
---@field document OpenApiDocument
---@alias OpenApiHeaders table<string, {name: string, value: string}>

---@type table<OpenApiMethod, boolean>
local methods =
  { get = true, put = true, post = true, delete = true, options = true, head = true, patch = true, trace = true }
local separator = string.rep("─", 40)

---Follow object references while retaining the owner for subsequent relative references.
---@param value any
---@param document OpenApiDocument
---@param context OpenApiContext
---@return table|nil value
---@return OpenApiDocument document
local function dereference(value, document, context)
  for _ = 1, 30 do
    if type(value) ~= "table" or not value["$ref"] then
      return value, document
    end
    local ok, target, owner = pcall(schema.resolve, value["$ref"], document, context)
    if not ok then
      schema.note(context, tostring(target))
      return nil, document
    end
    value, document = target, owner
  end
  schema.note(context, "Recursive object reference; the referenced section is omitted.")
  return nil, document
end

---Keep illustrative header values on one line without changing body examples.
---@param value any
---@return string
local function text(value)
  if value == vim.NIL then
    return "null"
  end
  if type(value) == "table" then
    value = vim.json.encode(value)
  end
  return (tostring(value):gsub("\r", "\\r"):gsub("\n", "\\n"))
end

---Encode data, not URI delimiters, so examples cannot accidentally add query fields.
---@param value any
---@return string
local function encode(value)
  return (text(value):gsub("[^A-Za-z0-9%-._~]", function(char)
    return string.format("%%%02X", char:byte())
  end))
end

---Deduplicate headers case-insensitively, including generated Content-Type and auth.
---@param headers OpenApiHeaders
---@param name string
---@param value any
local function set_header(headers, name, value)
  headers[name:lower()] = { name = name, value = text(value) }
end

---Emit deterministic headers to make the popup stable across invocations.
---@param lines string[]
---@param headers OpenApiHeaders
local function append_headers(lines, headers)
  for _, key in ipairs(vim.fn.sort(vim.tbl_keys(headers))) do
    local header = headers[key]
    lines[#lines + 1] = header.name .. ": " .. header.value
  end
end

---Merge inherited parameters; an operation overrides a path parameter by name and location.
---@param path_item table
---@param operation table
---@param document OpenApiDocument
---@param context OpenApiContext
---@return OpenApiParameter[]
local function parameters(path_item, operation, document, context)
  local result, positions = {}, {}
  for _, source in ipairs({ path_item.parameters or {}, operation.parameters or {} }) do
    for _, entry in ipairs(source) do
      local parameter, owner = dereference(entry, document, context)
      if parameter and parameter.name and parameter["in"] then
        local key = parameter["in"] .. ":" .. parameter.name
        local index = positions[key] or (#result + 1)
        positions[key] = index
        result[index] = { spec = parameter, document = owner }
      end
    end
  end
  return result
end

---Apply common OpenAPI parameter styles; unsupported styles get explicit placeholders.
---@param parameter table
---@param value any
---@param context OpenApiContext
---@return string[] parts serialized values, or name=value pairs for query/cookie parameters
local function serialize(parameter, value, context)
  local location, name = parameter["in"], parameter.name
  if parameter.content then
    value = vim.json.encode(value)
  end
  local query = location == "query" or location == "cookie"
  local style = parameter.style or (query and "form" or "simple")
  local explode = parameter.explode
  if explode == nil then
    explode = style == "form"
  end
  local escape = encode
  if location == "header" or location == "cookie" then
    escape = text
  end
  local values, pairs_list = {}, {}
  local object = type(value) == "table" and not vim.islist(value)
  if type(value) == "table" then
    local keys = vim.tbl_keys(value)
    table.sort(keys)
    for _, key in ipairs(keys) do
      if object then
        values[#values + 1] = escape(key)
        values[#values + 1] = escape(value[key])
        pairs_list[#pairs_list + 1] = escape(key) .. "=" .. escape(value[key])
      else
        values[#values + 1] = escape(value[key])
        pairs_list[#pairs_list + 1] = escape(name) .. "=" .. escape(value[key])
      end
    end
  else
    values = { escape(value) }
  end
  if style == "form" then
    if type(value) == "table" and explode then
      return pairs_list
    end
    return { escape(name) .. "=" .. table.concat(values, ",") }
  elseif style == "deepObject" and object and location == "query" then
    local result = {}
    for _, key in ipairs(vim.fn.sort(vim.tbl_keys(value))) do
      result[#result + 1] = encode(name .. "[" .. key .. "]") .. "=" .. encode(value[key])
    end
    return result
  elseif (style == "spaceDelimited" or style == "pipeDelimited") and location == "query" and not object then
    return { encode(name) .. "=" .. table.concat(values, style == "spaceDelimited" and "%20" or "%7C") }
  elseif style == "simple" then
    return { table.concat(object and explode and pairs_list or values, ",") }
  elseif style == "label" and location == "path" then
    return { "." .. table.concat(object and explode and pairs_list or values, explode and "." or ",") }
  elseif style == "matrix" and location == "path" then
    if type(value) == "table" and explode then
      return { ";" .. table.concat(pairs_list, ";") }
    end
    return { ";" .. encode(name) .. "=" .. table.concat(values, ",") }
  end
  schema.note(context, "Unsupported parameter style " .. style .. " for " .. name .. "; showing a placeholder.")
  return query and { encode(name) .. "={{" .. name .. "}}" } or { "{{" .. name .. "}}" }
end

---Choose one server without prompting or consulting environment variables.
---@param operation table
---@param path_item table
---@param document OpenApiDocument
---@param context OpenApiContext
---@return string host
---@return string base_path
local function server(operation, path_item, document, context)
  local servers = operation.servers or path_item.servers or document.value.servers or {}
  local selected = servers[1] or { url = "/" }
  if #servers > 1 then
    schema.note(context, "Servers: showing the first effective server.")
  end
  local url = (selected.url or "/"):gsub("{([^{}]+)}", function(name)
    local variable = (selected.variables or {})[name] or {}
    local value = variable.default
    if value == nil then
      value = (variable.enum or {})[1]
    end
    return value ~= nil and text(value) or "{{" .. name .. "}}"
  end)
  local host, base = url:match("^https?://([^/]+)(.*)$")
  if not host then
    host, base = url:match("^//([^/]+)(.*)$")
  end
  if not host then
    schema.note(context, "Relative server URL: {{host}} must be supplied.")
    host, base = "{{host}}", url
  end
  if base ~= "" and base:sub(1, 1) ~= "/" then
    base = "/" .. base
  end
  return host, base:gsub("/+$", "")
end

---Render only placeholders for security schemes; never read or obtain credentials.
---@param operation table
---@param document OpenApiDocument
---@param context OpenApiContext
---@param headers OpenApiHeaders
---@param query string[]
---@param cookies string[]
local function authentication(operation, document, context, headers, query, cookies)
  local security = operation.security
  if security == nil then
    security = document.value.security or {}
  end
  if #security > 1 then
    schema.note(context, "Security: showing the first authentication alternative.")
  end
  for _, name in ipairs(vim.fn.sort(vim.tbl_keys(security[1] or {}))) do
    local definition = ((document.value.components or {}).securitySchemes or {})[name]
    local scheme = dereference(definition, document, context)
    if not scheme then
      schema.note(context, "Cannot resolve security scheme: " .. name)
    elseif scheme.type == "apiKey" then
      local value = "{{" .. name .. "}}"
      if scheme["in"] == "header" then
        set_header(headers, scheme.name, value)
      elseif scheme["in"] == "query" or scheme["in"] == "cookie" then
        local parts = scheme["in"] == "query" and query or cookies
        local key = (scheme["in"] == "query" and encode(scheme.name) or scheme.name) .. "="
        for index = #parts, 1, -1 do
          if parts[index]:sub(1, #key) == key then
            table.remove(parts, index)
          end
        end
        parts[#parts + 1] = key .. value
      end
    elseif scheme.type == "http" then
      local kind = (scheme.scheme or ""):lower()
      if kind == "bearer" then
        set_header(headers, "Authorization", "Bearer {{token}}")
      elseif kind == "basic" then
        set_header(headers, "Authorization", "Basic {{base64_credentials}}")
      else
        schema.note(context, "Authentication scheme " .. kind .. " requires manual credentials.")
      end
    elseif scheme.type == "oauth2" or scheme.type == "openIdConnect" then
      set_header(headers, "Authorization", "Bearer {{token}}")
    else
      schema.note(
        context,
        "Security scheme " .. name .. " (" .. tostring(scheme.type) .. ") needs manual configuration."
      )
    end
  end
end

---Select JSON without hiding other declared formats or pretending to serialize them.
---@param container table
---@param document OpenApiDocument
---@param context OpenApiContext
---@param label string
---@param headers OpenApiHeaders
---@return string[] body
local function body(container, document, context, label, headers)
  local content = container.content or {}
  local names = vim.fn.sort(vim.tbl_keys(content))
  local selected = content["application/json"] and "application/json" or nil
  if not selected then
    for _, name in ipairs(names) do
      if name:match("%+json$") then
        selected = name
        break
      end
    end
  end
  if not selected then
    if #names > 0 then
      set_header(headers, "Content-Type", names[1])
      schema.note(context, label .. ": non-JSON body omitted (" .. table.concat(names, ", ") .. ").")
    end
    return {}
  end
  set_header(headers, "Content-Type", selected)
  if #names > 1 then
    schema.note(context, label .. ": showing " .. selected .. "; available media types: " .. table.concat(names, ", "))
  end
  local selected_schema, owner = schema.body_schema(content[selected], document, context, 0)
  if not selected_schema then
    schema.note(context, label .. ": no schema or usable example; body omitted.")
    return {}
  end
  return schema.format_json(schema.example(selected_schema, owner, context, 0))
end

---Create a documented exchange only when the cursor is on an HTTP method key.
---@param document OpenApiDocument
---@param path (string|integer)[]
---@return string[]|nil lines nil means this is not an operation-key hover
---@return string[] notes
function M.preview(document, path)
  if
    type(document.value) ~= "table"
    or not tostring(document.value.openapi):match("^3%.")
    or #path ~= 3
    or path[1] ~= "paths"
    or not methods[path[3]]
  then
    return nil, {}
  end
  local path_item = (document.value.paths or {})[path[2]]
  local operation = path_item and path_item[path[3]]
  if type(operation) ~= "table" then
    return nil, {}
  end
  ---@type OpenApiContext
  local context = { documents = { [document.filename] = document }, notes = {}, active = {} }
  local host, base_path = server(operation, path_item, document, context)
  local target, query, cookies, headers, path_values = path[2], {}, {}, {}, {}
  for _, parameter in ipairs(parameters(path_item, operation, document, context)) do
    local spec = parameter.spec
    local selected_schema, owner = schema.body_schema(spec, parameter.document, context, 0)
    local value = "{{" .. spec.name .. "}}"
    if selected_schema then
      value = schema.example(selected_schema, owner, context, 0)
    end
    local parts = serialize(spec, value, context)
    if spec["in"] == "path" then
      path_values[spec.name] = parts[1]
    elseif spec["in"] == "query" then
      vim.list_extend(query, parts)
    elseif spec["in"] == "cookie" then
      vim.list_extend(cookies, parts)
    elseif spec["in"] == "header" then
      set_header(headers, spec.name, parts[1])
    end
  end
  target = target:gsub("{([^{}]+)}", function(name)
    return path_values[name] or "{{" .. name .. "}}"
  end)
  authentication(operation, document, context, headers, query, cookies)
  if #cookies > 0 then
    set_header(headers, "Cookie", table.concat(cookies, "; "))
  end
  local request_body, request_owner = dereference(operation.requestBody, document, context)
  local request_lines = request_body and body(request_body, request_owner, context, "Request", headers) or {}
  local lines = {
    path[3]:upper()
      .. " "
      .. base_path
      .. target
      .. (#query > 0 and "?" .. table.concat(query, "&") or "")
      .. " HTTP/1.1",
    "Host: " .. (headers.host and headers.host.value or host),
  }
  headers.host = nil
  append_headers(lines, headers)
  if #request_lines > 0 then
    lines[#lines + 1] = ""
    vim.list_extend(lines, request_lines)
  end
  local responses, owner = dereference(operation.responses or {}, document, context)
  local statuses = {}
  for status in pairs(responses or {}) do
    if status == "default" or status:match("^[1-5]%d%d$") or status:match("^[1-5]XX$") then
      statuses[#statuses + 1] = status
    end
  end
  table.sort(statuses)
  for _, status in ipairs(statuses) do
    local response, response_owner = dereference(responses[status], owner, context)
    vim.list_extend(lines, {
      "",
      separator,
      status .. (response and response.description and " " .. response.description:gsub("%s+", " ") or ""),
      separator,
    })
    if response then
      local response_headers = {}
      for _, name in ipairs(vim.fn.sort(vim.tbl_keys(response.headers or {}))) do
        local header, header_owner = dereference(response.headers[name], response_owner, context)
        if header and name:lower() ~= "content-type" then
          local selected_schema, schema_owner = schema.body_schema(header, header_owner, context, 0)
          local value = "{{" .. name .. "}}"
          if selected_schema then
            value = schema.example(selected_schema, schema_owner, context, 0)
          end
          set_header(
            response_headers,
            name,
            serialize(
              { name = name, ["in"] = "header", style = header.style, explode = header.explode },
              value,
              context
            )[1]
          )
        end
      end
      local response_lines = body(response, response_owner, context, "Response " .. status, response_headers)
      append_headers(lines, response_headers)
      if #response_lines > 0 then
        lines[#lines + 1] = ""
        vim.list_extend(lines, response_lines)
      end
    else
      lines[#lines + 1] = "[Response reference unresolved]"
    end
  end
  if #statuses == 0 then
    schema.note(context, "No responses are documented for this operation.")
  end
  return lines, context.notes
end

return M
