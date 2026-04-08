local function create_capabilities()
  local has_blink, blink = pcall(require, "blink.cmp")
  if has_blink then
    return blink.get_lsp_capabilities(vim.lsp.protocol.make_client_capabilities())
  end
  return vim.lsp.protocol.make_client_capabilities()
end

---@param bufnr integer
---@param mode string|string[]
---@param lhs string
---@param rhs string|function
---@param desc string
local function map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc, silent = true })
end

---@param client vim.lsp.Client
---@param bufnr integer
local function on_attach(client, bufnr)
  map(bufnr, "n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
  map(bufnr, "n", "<leader>cr", vim.lsp.buf.rename, "Rename (Ctrl+F6)")
  map(bufnr, "n", "<F18>", vim.lsp.buf.rename, "Rename (Ctrl+F6)")
  map(bufnr, { "n", "x" }, "<M-CR>", vim.lsp.buf.code_action, "Code action (Ctrl+Enter)")
  map(bufnr, { "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action (Ctrl+Enter)")

  if package.loaded["snacks"] then
    map(bufnr, "n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, "Goto Definition (Ctrl+b)")
    map(bufnr, { "n", "i" }, "<C-b>", function()
      Snacks.picker.lsp_definitions()
    end, "Goto definition (Ctrl+b)")

    map(bufnr, "n", "gri", function()
      Snacks.picker.lsp_implementations()
    end, "Goto Implementation (Ctrl+Alt+b)")
    map(bufnr, "n", "<M-C-B>", function()
      Snacks.picker.lsp_implementations()
    end, "Goto implementation (Ctrl+Alt+b)")

    map(bufnr, "n", "grr", function()
      Snacks.picker.lsp_references()
    end, "LSP References (Alt+Shift+7)")
    map(bufnr, "n", "<M-&>", function()
      Snacks.picker.lsp_references()
    end, "LSP references (Alt+Shift+7)")

    map(bufnr, "n", "grt", function()
      Snacks.picker.lsp_type_definitions()
    end, "Goto Type Definition")

    map(bufnr, "n", "<leader>li", function()
      Snacks.picker.lsp_config()
    end, "Lsp Info")

    -- Move around with A-n / A-p.
    if client.server_capabilities.documentHighlightProvider and Snacks.words ~= nil then
      map(bufnr, "n", "<M-n>", function()
        Snacks.words.jump(vim.v.count1, true)
      end, "Next Reference")
      map(bufnr, "n", "<M-p>", function()
        Snacks.words.jump(-vim.v.count1, true)
      end, "Prev Reference")
    end
  end

  if client.server_capabilities.inlayHintProvider then
    pcall(vim.lsp.inlay_hint.enable, true, { bufnr = bufnr })
  end
end

return {
  create_capabilities = create_capabilities,
  on_attach = on_attach,
}
