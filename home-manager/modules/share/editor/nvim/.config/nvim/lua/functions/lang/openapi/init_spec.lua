-- Busted runs in plain Lua; these checks need real Neovim buffers and Tree-sitter.
if type(describe) == "function" then
  local spec_path = debug.getinfo(1, "S").source:sub(2)
  describe("OpenAPI integration", function()
    it("GIVEN Neovim and fx WHEN running the headless suite THEN all preview checks pass", function()
      local command = "nvim --headless -u NONE -l '" .. spec_path:gsub("'", "'\\''") .. "' 2>&1"
      local process = assert(io.popen(command))
      local output = process:read("*a")
      local actual, _, code = process:close()
      local expected = true
      assert.are.equal(expected, actual, "Headless Neovim exited with " .. tostring(code) .. ":\n" .. output)
    end)
  end)
  return
end

-- Run directly with: nvim --headless -u NONE -l <path-to-this-file>
local root = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "../../../.."))
vim.opt.runtimepath:prepend(root)
local openapi = require("functions.lang.openapi")
local directory = vim.fn.tempname()
vim.fn.mkdir(directory, "p")
local checks = 0

---Compare results with enough context to identify a failing behavior.
---@param actual any
---@param expected any
---@param behavior string GIVEN/WHEN/THEN description
local function then_equal(actual, expected, behavior)
  assert(
    vim.deep_equal(actual, expected),
    behavior .. "\nexpected: " .. vim.inspect(expected) .. "\nactual: " .. vim.inspect(actual)
  )
  checks = checks + 1
end

---Wrap a schema in an OpenAPI root to keep example-generation cases focused.
---@param schema table
---@return OpenApiDocument
local function given_document(schema)
  return {
    filename = directory .. "/api.yaml",
    value = { openapi = "3.1.0", components = { schemas = { Pet = schema } } },
  }
end

---Preview the model root without requiring a visible editor window.
---@param schema table
---@return any actual
---@return string[] notes
local function when_example(schema)
  return openapi.preview(given_document(schema), { "components", "schemas", "Pet" })
end

---Invoke the installed buffer mapping, exercising YAML decoding and cursor selection.
---@param text string
---@param needle string
---@return any actual decoded JSON, HTTP text, or nil on fallback
---@return integer source_bufnr
local function when_hover(text, needle)
  vim.cmd("enew!")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_name(bufnr, directory .. "/hover-" .. bufnr .. ".yaml")
  local lines = vim.split(text, "\n", { plain = true })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  for row, line in ipairs(lines) do
    if line:find(needle, 1, true) then
      vim.api.nvim_win_set_cursor(0, { row, 0 })
      break
    end
  end
  vim.cmd("luafile " .. vim.fn.fnameescape(root .. "/ftplugin/yaml.lua"))
  vim.api.nvim_exec_autocmds("LspAttach", { buffer = bufnr, data = { client_id = 0 } })
  vim.wait(50, function()
    return vim.fn.maparg("K", "n", false, true).desc == "Preview OpenAPI HTTP/JSON examples or LSP hover"
  end)
  local map = vim.fn.maparg("K", "n", false, true)
  map.callback()
  local float = vim.b[bufnr].lsp_floating_preview
  if not float or not vim.api.nvim_win_is_valid(float) then
    return nil, bufnr
  end
  local float_bufnr = vim.api.nvim_win_get_buf(float)
  local actual = table.concat(vim.api.nvim_buf_get_lines(float_bufnr, 0, -1, false), "\n")
  if vim.bo[float_bufnr].filetype == "json" then
    actual = vim.json.decode(actual)
  end
  return actual, bufnr
end

local ok, failure = xpcall(function()
  local actual = when_example({
    type = "object",
    properties = {
      id = { type = "integer" },
      active = { type = "boolean", example = false, default = true },
      label = { type = "string", example = "chosen", default = "ignored" },
      zero = { default = 0 },
      color = { enum = { "red", "blue" } },
      optional = { type = "string" },
      items = { type = "array", items = { type = "number" } },
      nothing = { example = vim.NIL },
      newer = { examples = { "first", "second" } },
    },
  })
  local expected = {
    id = 0,
    active = false,
    label = "chosen",
    zero = 0,
    color = "red",
    optional = "string",
    items = { 0 },
    nothing = vim.NIL,
    newer = "first",
  }
  then_equal(
    actual,
    expected,
    "GIVEN optional fields and explicit values WHEN generating THEN preserve precedence and include every field"
  )
  then_equal(
    when_example({ enum = { false, true } }),
    false,
    "GIVEN a false enum WHEN generating THEN preserve its value"
  )
  then_equal(
    when_example({ examples = { false, true } }),
    false,
    "GIVEN a false example list WHEN generating THEN preserve its value"
  )
  then_equal(
    when_example({ type = "object" }),
    vim.empty_dict(),
    "GIVEN an empty object WHEN generating THEN preserve JSON object shape"
  )
  then_equal(
    when_example({ type = { "null", "string" } }),
    "string",
    "GIVEN nullable types WHEN generating THEN choose the concrete type"
  )
  then_equal(
    when_example({ type = "object", additionalProperties = { type = "integer" } }),
    { additionalProp1 = 0 },
    "GIVEN a map WHEN generating THEN illustrate one entry"
  )

  local notes
  actual, notes = when_example({
    allOf = {
      { type = "object", properties = { a = { type = "string" } } },
      { type = "object", properties = { b = { oneOf = { { example = 7 }, { example = 8 } } } } },
    },
  })
  then_equal(
    actual,
    { a = "string", b = 7 },
    "GIVEN allOf and oneOf WHEN generating THEN merge fields and use the first alternative"
  )
  then_equal(
    notes,
    { "oneOf: showing the first alternative." },
    "GIVEN alternatives WHEN generating THEN explain branch selection"
  )
  actual, notes = when_example({ anyOf = { { type = "boolean" }, { type = "string" } } })
  then_equal(actual, false, "GIVEN anyOf WHEN generating THEN preserve the first false placeholder")
  then_equal(#notes, 1, "GIVEN anyOf WHEN generating THEN explain branch selection")

  local document =
    given_document({ type = "object", properties = { child = { ["$ref"] = "#/components/schemas/Pet" } } })
  actual, notes = openapi.preview(document, { "components", "schemas", "Pet" })
  then_equal(actual, { child = vim.NIL }, "GIVEN a recursive reference WHEN generating THEN stop at null")
  then_equal(#notes, 1, "GIVEN recursion WHEN generating THEN explain the omitted value")
  document.value.components.schemas["a/b~c"] = { example = "escaped" }
  document.value.components.schemas.Pet = { ["$ref"] = "#/components/schemas/a~1b~0c" }
  then_equal(
    openapi.preview(document, { "components", "schemas", "Pet" }),
    "escaped",
    "GIVEN escaped JSON Pointer tokens WHEN resolving THEN decode in the correct order"
  )

  vim.fn.writefile(
    { "Pet:", "  type: object", "  properties:", "    name: {type: string}" },
    directory .. "/models.yaml"
  )
  actual = when_example({ ["$ref"] = "./models.yaml#/Pet" })
  then_equal(actual, { name = "string" }, "GIVEN a relative YAML file WHEN resolving THEN expand its schema")
  vim.fn.writefile({ '{"Pet":{"example":{"id":42}}}' }, directory .. "/models.json")
  then_equal(
    when_example({ ["$ref"] = "./models.json#/Pet" }),
    { id = 42 },
    "GIVEN a JSON reference file WHEN resolving THEN expand its schema"
  )
  local other = vim.fn.bufadd(directory .. "/models.yaml")
  vim.fn.bufload(other)
  vim.api.nvim_buf_set_lines(other, 0, -1, false, { "Pet: {example: unsaved}" })
  then_equal(
    when_example({ ["$ref"] = "./models.yaml#/Pet" }),
    "unsaved",
    "GIVEN an unsaved referenced buffer WHEN resolving THEN prefer it to disk"
  )
  for _, ref in ipairs({ "./missing.yaml#/Pet", "#/missing", "https://example.invalid/schema" }) do
    actual, notes =
      when_example({ type = "object", properties = { missing = { ["$ref"] = ref }, good = { example = 1 } } })
    then_equal(
      actual,
      { missing = vim.NIL, good = 1 },
      "GIVEN an unresolved reference WHEN generating THEN retain the rest of the payload: " .. ref
    )
    then_equal(#notes, 1, "GIVEN an unresolved reference WHEN generating THEN explain the null: " .. ref)
  end

  document = given_document({ type = "string" })
  document.value.components.requestBodies =
    { Shared = { content = { ["application/json"] = { schema = { example = "body" } } } } }
  document.value.paths = { ["/pets"] = { post = { requestBody = { ["$ref"] = "#/components/requestBodies/Shared" } } } }
  local body_path = { "paths", "/pets", "post", "requestBody", "$ref" }
  then_equal(
    openapi.preview(document, body_path),
    "body",
    "GIVEN a referenced requestBody WHEN previewing THEN find the target body schema"
  )
  local media = document.value.components.requestBodies.Shared.content["application/json"]
  media.example = false
  then_equal(
    openapi.preview(document, body_path),
    false,
    "GIVEN an explicit media example WHEN previewing its body THEN prefer even a false example"
  )
  media.example = nil
  media.examples = { First = { value = { supplied = true } } }
  then_equal(
    openapi.preview(document, body_path),
    { supplied = true },
    "GIVEN named media examples WHEN previewing THEN unwrap the Example Object value"
  )
  document.value.paths["/pets"].post.requestBody = { ["$ref"] = "#/missing" }
  actual, notes = openapi.preview(document, body_path)
  then_equal(
    actual,
    vim.NIL,
    "GIVEN an unresolved body reference WHEN previewing THEN show an explained null instead of ordinary hover"
  )
  then_equal(#notes, 1, "GIVEN an unresolved body reference WHEN previewing THEN retain its explanation")

  local text = [[openapi: 3.0.3
info: {title: Test, version: '1'}
components:
  schemas:
    Pet:
      type: object
      properties:
        id: {type: integer}
        'a/b':
          type: string
          example: hello
        children:
          type: array
          items:
            $ref: '#/components/schemas/Pet'
paths:
  /pets:
    post:
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/Pet'
      responses:
        '200':
          content:
            application/problem+json:
              schema:
                type: object
                properties:
                  error: {example: failed}
]]
  actual = when_hover(text, "    Pet:")
  then_equal(
    actual,
    { id = 0, ["a/b"] = "hello", children = { vim.NIL } },
    "GIVEN a model-name cursor WHEN pressing K THEN open a JSON payload float"
  )
  actual = when_hover(text, "        id:")
  then_equal(actual, 0, "GIVEN indentation before a flow property WHEN pressing K THEN preview only that property")
  actual = when_hover(text, "          example: hello")
  then_equal(
    actual,
    "hello",
    "GIVEN a cursor in property metadata WHEN pressing K THEN select the enclosing quoted property"
  )
  actual = when_hover(text, "      requestBody:")
  then_equal(
    actual,
    { id = 0, ["a/b"] = "hello", children = { vim.NIL } },
    "GIVEN a request body container WHEN pressing K THEN choose its JSON schema"
  )
  actual = when_hover(text, "        '200':")
  then_equal(actual, { error = "failed" }, "GIVEN a response status WHEN pressing K THEN choose its +json schema")

  actual = when_hover(
    [[openapi: 3.1.0
components:
  schemas:
    Value:
      allOf:
        - type: object
          properties:
            x: {example: 9}
        - type: string
]],
    "        - type: string"
  )
  then_equal(actual, "string", "GIVEN a cursor on an allOf sequence item WHEN pressing K THEN select that branch")
  actual = when_hover(
    [[openapi: 3.1.0
components:
  schemas:
    Value:
      type: object
      properties:
        base: &base {example: false}
        alias: *base
]],
    "        alias:"
  )
  then_equal(actual, false, "GIVEN YAML aliases WHEN pressing K THEN decode their values accurately")

  local source
  actual, source = when_hover(text, "        id:")
  local moving_float = vim.b[source].lsp_floating_preview
  vim.api.nvim_exec_autocmds("CursorMoved", { buffer = source })
  vim.wait(50, function()
    return not vim.api.nvim_win_is_valid(moving_float)
  end)
  then_equal(
    vim.api.nvim_win_is_valid(moving_float),
    false,
    "GIVEN a hover float WHEN the source cursor moves THEN close it"
  )
  actual, source = when_hover(text, "    Pet:")
  local notes_float = vim.b[source].lsp_floating_preview
  local extmarks = vim.api.nvim_buf_get_extmarks(
    vim.api.nvim_win_get_buf(notes_float),
    vim.api.nvim_create_namespace("openapi-example"),
    0,
    -1,
    { details = true }
  )
  then_equal(
    #extmarks,
    1,
    "GIVEN recursive JSON WHEN showing a preview THEN display the explanation outside the copyable payload"
  )
  actual, source = when_hover(text, "        id:")
  local float = vim.b[source].lsp_floating_preview
  then_equal(
    vim.bo[vim.api.nvim_win_get_buf(float)].filetype,
    "json",
    "GIVEN an example float WHEN opening THEN use JSON highlighting"
  )
  vim.fn.maparg("K", "n", false, true).callback()
  then_equal(vim.api.nvim_get_current_win(), float, "GIVEN an open preview WHEN pressing K again THEN focus it")
  vim.fn.maparg("q", "n", false, true).callback()
  then_equal(vim.api.nvim_win_is_valid(float), false, "GIVEN a focused preview WHEN pressing q THEN close it")

  local operation = require("functions.lang.openapi.operation")
  local exchange = given_document({ example = { name = "Milo" } })
  exchange.value.servers = {
    { url = "https://{region}.example.com/v1", variables = { region = { default = "api" } } },
    { url = "https://other.example.com" },
  }
  exchange.value.security = { { bearer = {} }, { key = {} } }
  exchange.value.components.securitySchemes = {
    bearer = { type = "http", scheme = "bearer" },
    key = { type = "apiKey", ["in"] = "header", name = "X-API-Key" },
    queryKey = { type = "apiKey", ["in"] = "query", name = "api_key" },
    cookieKey = { type = "apiKey", ["in"] = "cookie", name = "secret" },
    basic = { type = "http", scheme = "basic" },
    oauth = { type = "oauth2" },
  }
  exchange.value.components.requestBodies = {
    Pet = {
      content = {
        ["application/json"] = { schema = { ["$ref"] = "#/components/schemas/Pet" } },
        ["application/xml"] = { schema = { type = "string" } },
      },
    },
  }
  exchange.value.components.responses = {
    Created = {
      description = "Created",
      headers = {
        Location = { schema = { example = "/v1/owners/42/pets/123" } },
        ["X-Enabled"] = { schema = { example = false } },
      },
      content = { ["application/json"] = { example = { id = 123 } } },
    },
  }
  exchange.value.paths = {
    ["/owners/{ownerId}/pets"] = {
      parameters = {
        { name = "ownerId", ["in"] = "path", schema = { example = 42 } },
        { name = "notify", ["in"] = "query", schema = { example = true } },
      },
      post = {
        parameters = {
          { name = "notify", ["in"] = "query", schema = { example = false } },
          { name = "tag", ["in"] = "query", schema = { example = { "a b", "c&d" } } },
          { name = "X-Count", ["in"] = "header", schema = { default = 0 } },
          { name = "session", ["in"] = "cookie", schema = { example = "abc" } },
        },
        requestBody = { ["$ref"] = "#/components/requestBodies/Pet" },
        responses = {
          ["201"] = { ["$ref"] = "#/components/responses/Created" },
          ["204"] = { description = "No Content" },
          ["400"] = {
            description = "Bad Request",
            content = { ["application/problem+json"] = { schema = { example = { error = "invalid" } } } },
          },
          ["default"] = { description = "Unexpected error" },
          ["x-note"] = "Not a response",
        },
      },
    },
  }
  local operation_path = { "paths", "/owners/{ownerId}/pets", "post" }
  local lines
  lines, notes = operation.preview(exchange, operation_path)
  actual = table.concat(lines, "\n")
  expected = [[POST /v1/owners/42/pets?notify=false&tag=a%20b&tag=c%26d HTTP/1.1
Host: api.example.com
Authorization: Bearer {{token}}
Content-Type: application/json
Cookie: session=abc
X-Count: 0

{
  "name": "Milo"
}

────────────────────────────────────────
201 Created
────────────────────────────────────────
Content-Type: application/json
Location: /v1/owners/42/pets/123
X-Enabled: false

{
  "id": 123
}

────────────────────────────────────────
204 No Content
────────────────────────────────────────

────────────────────────────────────────
400 Bad Request
────────────────────────────────────────
Content-Type: application/problem+json

{
  "error": "invalid"
}

────────────────────────────────────────
default Unexpected error
────────────────────────────────────────]]
  then_equal(
    actual,
    expected,
    "GIVEN a documented operation WHEN previewing THEN show its complete illustrative request and every response"
  )
  then_equal(
    #notes,
    3,
    "GIVEN alternative servers, security and media WHEN previewing THEN explain deterministic choices"
  )

  local path_item = exchange.value.paths[operation_path[2]]
  local post = path_item.post
  path_item.servers = { { url = "https://path.example.com/v2/" } }
  lines = operation.preview(exchange, operation_path)
  then_equal(
    lines[1]:match("^POST (%S+)"),
    "/v2/owners/42/pets?notify=false&tag=a%20b&tag=c%26d",
    "GIVEN a path server WHEN previewing THEN override the document server"
  )
  post.servers = { { url = "https://operation.example.com/v3" } }
  post.security = {}
  lines = operation.preview(exchange, operation_path)
  actual = table.concat(lines, "\n")
  then_equal(
    lines[1]:find("/v3/owners/", 1, true) ~= nil and lines[2] == "Host: operation.example.com",
    true,
    "GIVEN an operation server WHEN previewing THEN override the path server"
  )
  then_equal(
    actual:find("Authorization:", 1, true),
    nil,
    "GIVEN security: [] WHEN previewing THEN suppress inherited authentication"
  )
  for _, name in ipairs({ "key", "queryKey", "cookieKey", "basic", "oauth" }) do
    post.security = { { [name] = {} } }
    lines = operation.preview(exchange, operation_path)
    actual = table.concat(lines, "\n")
    local expected_fragments = {
      key = "X-API-Key: {{key}}",
      queryKey = "api_key={{queryKey}}",
      cookieKey = "secret={{cookieKey}}",
      basic = "Authorization: Basic {{base64_credentials}}",
      oauth = "Authorization: Bearer {{token}}",
    }
    then_equal(
      actual:find(expected_fragments[name], 1, true) ~= nil,
      true,
      "GIVEN " .. name .. " security WHEN previewing THEN use a credential placeholder"
    )
  end
  post.security = {}
  post.servers = {}
  path_item.servers = nil
  lines = operation.preview(exchange, operation_path)
  then_equal(
    lines[2],
    "Host: {{host}}",
    "GIVEN no effective server WHEN previewing THEN leave an explicit host placeholder"
  )

  vim.fn.writefile({
    "body:",
    "  content:",
    "    application/json:",
    "      schema:",
    "        $ref: './nested.json#/Model'",
    "response:",
    "  description: From file",
    "  headers:",
    "    X-Remote:",
    "      schema: {example: remote}",
    "  content:",
    "    application/json:",
    "      schema:",
    "        $ref: './nested.json#/Model'",
  }, directory .. "/exchange.yaml")
  vim.fn.writefile({ '{"Model":{"example":{"external":true}}}' }, directory .. "/nested.json")
  post.requestBody = { ["$ref"] = "./exchange.yaml#/body" }
  post.responses = { ["200"] = { ["$ref"] = "./exchange.yaml#/response" }, ["404"] = { ["$ref"] = "./missing.yaml" } }
  lines, notes = operation.preview(exchange, operation_path)
  actual = table.concat(lines, "\n")
  then_equal(
    select(2, actual:gsub('"external": true', "")),
    2,
    "GIVEN external request and response objects WHEN previewing THEN resolve nested references against their owning files"
  )
  then_equal(
    actual:find("X-Remote: remote", 1, true) ~= nil,
    true,
    "GIVEN referenced response headers WHEN previewing THEN include their examples"
  )
  then_equal(
    actual:find("[Response reference unresolved]", 1, true) ~= nil and #notes > 0,
    true,
    "GIVEN an unresolved response WHEN previewing THEN retain the request and explain the omitted response"
  )
  post.requestBody = { content = { ["application/xml"] = { schema = { type = "string" } } } }
  post.responses =
    { ["2XX"] = { description = "Success", content = { ["text/plain"] = { schema = { type = "string" } } } } }
  lines, notes = operation.preview(exchange, operation_path)
  then_equal(
    table.concat(lines, "\n"):find("2XX Success", 1, true) ~= nil,
    true,
    "GIVEN a response status range WHEN previewing THEN include it"
  )
  then_equal(
    table.concat(notes, "\n"):find("non-JSON body omitted", 1, true) ~= nil,
    true,
    "GIVEN non-JSON content WHEN previewing THEN clearly explain omitted bodies"
  )

  post.requestBody = nil
  post.responses = {}
  lines, notes = operation.preview(exchange, operation_path)
  then_equal(
    table.concat(notes, "\n"):find("No responses are documented", 1, true) ~= nil,
    true,
    "GIVEN an operation without responses WHEN previewing THEN explain their absence"
  )
  then_equal(
    operation.preview(exchange, { "paths", operation_path[2], "post", "summary" }),
    nil,
    "GIVEN operation metadata WHEN previewing THEN preserve existing hover selection"
  )
  for _, method in ipairs({ "get", "put", "delete", "options", "head", "patch", "trace" }) do
    path_item[method] = { responses = { ["204"] = { description = "No Content" } } }
    lines = operation.preview(exchange, { "paths", operation_path[2], method })
    then_equal(
      lines[1]:match("^(%S+)"),
      method:upper(),
      "GIVEN an HTTP " .. method .. " key WHEN previewing THEN render its method"
    )
  end

  local serialization_cases = {
    {
      spec = {
        name = "ownerId",
        ["in"] = "path",
        style = "label",
        explode = true,
        schema = { example = { "a b", "c/d" } },
      },
      expected = "/owners/.a%20b.c%2Fd/pets",
    },
    {
      spec = {
        name = "ownerId",
        ["in"] = "path",
        style = "matrix",
        explode = true,
        schema = { example = { x = 1, y = 2 } },
      },
      expected = "/owners/;x=1;y=2/pets",
    },
    {
      spec = { name = "ownerId", ["in"] = "path", schema = { example = { x = 1, y = 2 } } },
      expected = "/owners/x,1,y,2/pets",
    },
    {
      spec = { name = "value", ["in"] = "query", explode = false, schema = { example = { false, 0 } } },
      expected = "value=false,0",
    },
    {
      spec = { name = "filter", ["in"] = "query", style = "deepObject", schema = { example = { name = "a b" } } },
      expected = "filter%5Bname%5D=a%20b",
    },
    {
      spec = { name = "value", ["in"] = "query", style = "spaceDelimited", schema = { example = { "x", "y" } } },
      expected = "value=x%20y",
    },
    {
      spec = { name = "value", ["in"] = "query", style = "pipeDelimited", schema = { example = { "x", "y" } } },
      expected = "value=x%7Cy",
    },
    {
      spec = {
        name = "payload",
        ["in"] = "query",
        content = { ["application/json"] = { schema = { example = { id = 1 } } } },
      },
      expected = "payload=%7B%22id%22%3A1%7D",
    },
    { spec = { name = "X-Line", ["in"] = "header", schema = { example = "a\r\nb" } }, expected = "X-Line: a\\r\\nb" },
  }
  for _, case in ipairs(serialization_cases) do
    post.parameters = { case.spec }
    lines = operation.preview(exchange, operation_path)
    then_equal(
      table.concat(lines, "\n"):find(case.expected, 1, true) ~= nil,
      true,
      "GIVEN "
        .. (case.spec.style or "default")
        .. " "
        .. case.spec["in"]
        .. " parameters WHEN previewing THEN preserve their serialization"
    )
  end
  post.parameters = { { name = "api_key", ["in"] = "query", schema = { example = "example-key" } } }
  post.security = { { queryKey = {}, key = {} } }
  lines = operation.preview(exchange, operation_path)
  actual = table.concat(lines, "\n")
  then_equal(
    select(2, actual:gsub("api_key=", "")),
    1,
    "GIVEN a declared API-key parameter and security scheme WHEN previewing THEN avoid duplicate query keys"
  )
  then_equal(
    actual:find("api_key={{queryKey}}", 1, true) ~= nil and actual:find("X-API-Key: {{key}}", 1, true) ~= nil,
    true,
    "GIVEN combined security requirements WHEN previewing THEN show every required credential placeholder"
  )
  post.security = {}
  post.parameters = { { name = "ownerId", ["in"] = "path", style = "unsupported", schema = { example = 42 } } }
  lines, notes = operation.preview(exchange, operation_path)
  then_equal(
    lines[1]:find("/owners/{{ownerId}}/pets", 1, true) ~= nil
      and table.concat(notes, "\n"):find("Unsupported parameter style", 1, true) ~= nil,
    true,
    "GIVEN an unsupported parameter style WHEN previewing THEN keep a readable placeholder with an explanation"
  )
  post.parameters = {}
  path_item.parameters = {}
  lines = operation.preview(exchange, operation_path)
  then_equal(
    lines[1]:find("/owners/{{ownerId}}/pets", 1, true) ~= nil,
    true,
    "GIVEN an unresolved path parameter WHEN previewing THEN preserve a readable placeholder"
  )

  actual, source = when_hover(text, "    post:")
  then_equal(
    actual:find("POST /pets HTTP/1.1", 1, true) ~= nil and actual:find("200", 1, true) ~= nil,
    true,
    "GIVEN the cursor on an HTTP method WHEN pressing K THEN show a request and its responses"
  )
  local operation_float = vim.b[source].lsp_floating_preview
  then_equal(
    vim.bo[vim.api.nvim_win_get_buf(operation_float)].filetype,
    "http",
    "GIVEN an operation popup WHEN opening THEN use HTTP rather than JSON filetype"
  )
  vim.fn.maparg("K", "n", false, true).callback()
  then_equal(
    vim.api.nvim_get_current_win(),
    operation_float,
    "GIVEN an operation popup WHEN pressing K again THEN focus it"
  )
  vim.fn.maparg("<Esc>", "n", false, true).callback()
  then_equal(
    vim.api.nvim_win_is_valid(operation_float),
    false,
    "GIVEN a focused operation popup WHEN pressing Escape THEN close it"
  )

  local fallback = 0
  local original_hover = vim.lsp.buf.hover
  vim.lsp.buf.hover = function()
    fallback = fallback + 1
  end
  when_hover("ordinary: yaml", "ordinary")
  when_hover(text:gsub("application/problem%+json", "text/plain"), "                type: object")
  when_hover(text, "info:")
  when_hover(text:gsub("openapi: 3.0.3", "swagger: '2.0'"), "    Pet:")
  when_hover("type: object\nproperties: {id: {type: integer}}", "properties")
  vim.lsp.buf.hover = original_hover
  then_equal(
    fallback,
    5,
    "GIVEN ordinary YAML, metadata, Swagger, or a standalone fragment WHEN pressing K THEN use LSP hover"
  )

  vim.cmd("enew!")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, vim.split(text, "\n", { plain = true }))
  vim.cmd("luafile " .. vim.fn.fnameescape(root .. "/ftplugin/yaml.lua"))
  local buffer = vim.api.nvim_get_current_buf()
  vim.keymap.set("n", "K", function() end, { buffer = buffer, desc = "Simulated LSP override" })
  vim.api.nvim_exec_autocmds("LspAttach", { buffer = buffer, data = { client_id = 0 } })
  vim.wait(50, function()
    return vim.fn.maparg("K", "n", false, true).desc == "Preview OpenAPI HTTP/JSON examples or LSP hover"
  end)
  then_equal(
    vim.fn.maparg("K", "n", false, true).desc,
    "Preview OpenAPI HTTP/JSON examples or LSP hover",
    "GIVEN LSP attachment WHEN shared mappings finish THEN retain the YAML K override"
  )
end, debug.traceback)

vim.fn.delete(directory, "rf")
if not ok then
  error(failure)
end
print("OpenAPI: " .. checks .. " checks passed")
