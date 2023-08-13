local lsp = require("lspconfig")
local map = vim.keymap.set

-- configure setup on attach to a lsp server
local custom_attach = function(_, bufnr)
  -- setup diagnostics toggle on and off
  vim.g.diagnostics_visible = true
  function _G.toggle_diagnostics()
    if vim.g.diagnostics_visible then
      vim.g.diagnostics_visible = false
      vim.diagnostic.disable()
    else
      vim.g.diagnostics_visible = true
      vim.diagnostic.enable()
    end
  end

  vim.api.nvim_buf_set_keymap(0, "n", "<Leader>ct", "<cmd>call v:lua.toggle_diagnostics()<CR>", {
    silent = true,
    noremap = true,
    desc = "Diagnostics Toggle"
  })

  -- setup global autocompletion
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- -------------------------------
  -- KEYMAPS
  -- -------------------------------

  -- map("n", "]w", vim.diagnostic.goto_next,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "Diagnostic go to next" })
  -- map("n", "[w", vim.diagnostic.goto_prev,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "Diagnostic go to previous" })
  map("n", "<leader>ch", "<cmd>lua vim.lsp.buf.hover() vim.lsp.buf.hover()<cr>",
    { noremap = true, silent = true, buffer = bufnr, desc = "LSP show hovering help" })
  map("n", "<S-k>", "<cmd>lua vim.lsp.buf.hover() vim.lsp.buf.hover()<cr>",
    { noremap = true, silent = true, buffer = bufnr, desc = "LSP show hovering help (Shift+k)" })
  -- map("n", "<leader>cd", vim.lsp.buf.definition,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP definition" })
  -- map("n", "<leader>cD", vim.lsp.buf.declaration,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP declaration" })
  -- map("n", "<leader>ci", vim.lsp.buf.implementation,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP implementation" })
  -- map("n", "<leader>co", vim.lsp.buf.type_definition,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP type definition" })
  -- map("n", "<leader>cu", vim.lsp.buf.references,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP references" })
  -- map("n", "<leader>cs", vim.lsp.buf.signature_help,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP signature help" })
  -- map("n", "<leader>cr", vim.lsp.buf.rename,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP rename" })
  -- map("n", "<F18>", vim.lsp.buf.rename,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP rename (Shift+F6)" })
  map("n", "<leader>cf", "<cmd>lua vim.lsp.buf.format { async = true }<CR>",
    { noremap = true, silent = true, buffer = bufnr, desc = "LSP format" })
  map("n", "<M-C-L>", "<cmd>lua vim.lsp.buf.format { async = true }<CR>",
    { noremap = true, silent = true, buffer = bufnr, desc = "LSP format (Ctrl+Alt+l)" })
  -- map("n", "<leader>ce", vim.diagnostic.setloclist,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP show errors" })
  map("n", "<leader>ca", vim.lsp.buf.code_action,
    { noremap = true, silent = true, buffer = bufnr, desc = "LSP code action" })
  -- map("n", "<A-CR>", vim.lsp.buf.code_action,
  --   { noremap = true, silent = true, buffer = bufnr, desc = "LSP code action (Alt+Enter)" })
  map("n", "<F25>", vim.diagnostic.open_float,
    { noremap = true, buffer = bufnr, desc = "LSP open message in floating window (Ctrl+F1)" })
end

-- Setup lspconfig.
local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- Workaround for jdtls nil issue, see https://github.com/neovim/nvim-lspconfig/issues/2386
-- local function on_language_status(_, result)
--   -- Ignore nil messages.
--   if result.message == nil then
--       return
--   end
--   local command = vim.api.nvim_command
--   command "echohl ModeMsg"
--   command(string.format("echo "%s"", result.message))
--   command "echohl None"
-- end

-- setup servers for each programming language
lsp.angularls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.bashls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.dockerls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.gopls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.html.setup { on_attach = custom_attach, capabilities = capabilities }
-- lsp.jdtls.setup {
--   on_attach = custom_attach,
--   capabilities = capabilities,
--   handlers = {
--     ["$/progress"] = vim.schedule_wrap(on_language_status),
--   },
-- }
lsp.jsonls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.lua_ls.setup {
  on_attach = custom_attach,
  capabilities = capabilities,
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you"re using (most likely LuaJIT in the case of Neovim)
        version = "LuaJIT",
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = { "vim" },
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file("", true),
        checkThirdParty = false,
      },
      -- Do not send telemetry data containing a randomized but unique identifier
      telemetry = {
        enable = false,
      },
    },
  },
}
lsp.marksman.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.pylsp.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.rust_analyzer.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.sqlls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.terraform_lsp.setup { cmd = { "terraform-ls", "serve" }, on_attach = custom_attach, capabilities = capabilities }
lsp.tsserver.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.vimls.setup { on_attach = custom_attach, capabilities = capabilities }
lsp.yamlls.setup {
  on_attach = custom_attach,
  capabilities = capabilities,
  settings = {
    yaml = {
      schemas = {
        ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml",
        ["https://raw.githubusercontent.com/ansible/schemas/main/f/ansible.json"] = "/ansible/*.yml"
      }
    }
  }
}
