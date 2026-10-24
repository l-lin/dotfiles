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
local root = vim.fs.normalize(vim.fs.joinpath(vim.fs.dirname(debug.getinfo(1, "S").source:sub(2)), "../../.."))
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
---@return any actual decoded floating-buffer JSON, or nil on fallback
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
    return vim.fn.maparg("K", "n", false, true).desc == "Preview OpenAPI JSON example or LSP hover"
  end)
  local map = vim.fn.maparg("K", "n", false, true)
  map.callback()
  local float = vim.b[bufnr].lsp_floating_preview
  if not float or not vim.api.nvim_win_is_valid(float) then
    return nil, bufnr
  end
  local actual =
    vim.json.decode(table.concat(vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(float), 0, -1, false), "\n"))
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
    return vim.fn.maparg("K", "n", false, true).desc == "Preview OpenAPI JSON example or LSP hover"
  end)
  then_equal(
    vim.fn.maparg("K", "n", false, true).desc,
    "Preview OpenAPI JSON example or LSP hover",
    "GIVEN LSP attachment WHEN shared mappings finish THEN retain the YAML K override"
  )
end, debug.traceback)

vim.fn.delete(directory, "rf")
if not ok then
  error(failure)
end
print("OpenAPI: " .. checks .. " checks passed")
