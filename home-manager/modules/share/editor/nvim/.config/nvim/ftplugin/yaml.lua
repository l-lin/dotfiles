---Read a YAML scalar without its surrounding single or double quotes.
---@param node TSNode the scalar node in the current buffer
---@return string text the scalar text without surrounding quotes
---@return integer count the number of quote pairs removed
local function scalar_text(node)
  return vim.treesitter.get_node_text(node, 0):gsub("^(['\"])(.*)%1$", "%2")
end

---Find a direct mapping key without matching keys in nested mappings.
---@param node TSNode|nil the mapping or a syntax wrapper around it
---@param key string the decoded JSON Pointer token to match
---@return TSNode|nil key_node the matching key, or nil if absent
---@return TSNode|nil value_node the matching value, or nil if absent
local function find_key(node, key)
  -- YAML wraps mappings in document and block/flow nodes; comments are not containers.
  while node and node:type() ~= "block_mapping" and node:type() ~= "flow_mapping" do
    local child
    for candidate in node:iter_children() do
      if candidate:named() and candidate:type() ~= "comment" then
        child = candidate
        break
      end
    end
    node = child
  end
  if not node then return end

  for pair in node:iter_children() do
    local key_node = pair:field("key")[1]
    if key_node and scalar_text(key_node) == key then
      return key_node, pair:field("value")[1]
    end
  end
end

---Follow a same-document $ref mapping path, otherwise use LSP definition lookup.
---Requires the YAML Tree-sitter parser; unresolved local paths produce a warning.
local function goto_ref_definition()
  local ok, parser = pcall(vim.treesitter.get_parser, 0, "yaml")
  if not ok or not parser then return vim.lsp.buf.definition() end
  parser:parse()

  local cursor = vim.api.nvim_win_get_cursor(0)
  -- Indentation belongs to the parent mapping, not the $ref pair on this line.
  local first_column = (vim.api.nvim_get_current_line():find("%S") or 1) - 1
  local node = vim.treesitter.get_node({ pos = { cursor[1] - 1, math.max(cursor[2], first_column) } })
  while node and node:type() ~= "block_mapping_pair" and node:type() ~= "flow_pair" do
    node = node:parent()
  end
  local key = node and node:field("key")[1]
  local value = node and node:field("value")[1]
  if not key or scalar_text(key) ~= "$ref" or not value then return vim.lsp.buf.definition() end

  local ref = scalar_text(value)
  if ref:sub(1, 2) ~= "#/" then return vim.lsp.buf.definition() end

  -- A YAML stream can contain multiple documents; references stay in the current one.
  local document = node
  while document:parent() and document:type() ~= "document" do
    document = document:parent()
  end

  ---@type TSNode|nil
  local target
  ---@type TSNode|nil
  local current = document
  local pointer = ref:sub(3):gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
  for _, token in ipairs(vim.split(pointer, "/", { plain = true })) do
    -- JSON Pointer requires decoding ~1 before ~0 to preserve literal ~1 keys.
    token = token:gsub("~1", "/"):gsub("~0", "~")
    target, current = find_key(current, token)
    if not target then
      vim.notify("Cannot resolve local $ref: " .. ref, vim.log.levels.WARN)
      return
    end
  end

  local row, col = target:range()
  -- Preserve Ctrl-o jump-back behavior and reveal targets inside closed folds.
  vim.cmd("normal! m'")
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
  vim.cmd("normal! zv")
end

---@type integer
local bufnr = vim.api.nvim_get_current_buf()

---Install YAML navigation and hover overrides only in the buffer that loaded this ftplugin.
local function map_yaml_keys()
  vim.keymap.set("n", "K", function()
    require("functions.lang.openapi").hover()
  end, {
    buffer = bufnr,
    silent = true,
    desc = "Preview OpenAPI JSON example or LSP hover",
  })
  vim.keymap.set("n", "gd", goto_ref_definition, {
    buffer = bufnr,
    silent = true,
    desc = "Goto YAML $ref or LSP definition",
  })
end

-- Example previews do not require an attached language server.
map_yaml_keys()

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("YamlRefDefinition" .. bufnr, { clear = true }),
  buffer = bufnr,
  callback = function()
    -- Wait for shared LSP on_attach so its mappings cannot replace the YAML overrides.
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) then map_yaml_keys() end
    end)
  end,
})
