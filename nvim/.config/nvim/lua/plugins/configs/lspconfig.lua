local M = {}

M.attach_keymaps = function(_, bufnr)
  local map = require("mapper").map
  local bufopts = { silent = true, noremap = true, buffer = bufnr }

  map("n", "<Leader>ct", "<cmd>call v:lua.toggle_diagnostics()<CR>", bufopts, "Diagnostics Toggle")
  -- map("n", "]w", vim.diagnostic.goto_next, bufopts, "Diagnostic go to next" )
  -- map("n", "[w", vim.diagnostic.goto_prev, bufopts, "Diagnostic go to previous" )
  -- map("n", "<leader>ch", "<cmd>lua vim.lsp.buf.hover()<cr>", bufopts, "LSP show hovering help" )
  -- map("n", "<S-k>", "<cmd>lua vim.lsp.buf.hover()<cr>", bufopts, "LSP show hovering help (Shift+k)" )
  -- map("n", "<leader>cd", vim.lsp.buf.definition, bufopts, "LSP definition" )
  -- map("n", "<leader>cD", vim.lsp.buf.declaration, bufopts, "LSP declaration" )
  -- map("n", "<leader>ci", vim.lsp.buf.implementation, bufopts, "LSP implementation" )
  -- map("n", "<leader>co", vim.lsp.buf.type_definition, bufopts, "LSP type definition" )
  -- map("n", "<leader>cu", vim.lsp.buf.references, bufopts, "LSP references" )
  -- map("n", "<leader>cs", vim.lsp.buf.signature_help, bufopts, "LSP signature help" )
  -- map("n", "<leader>cr", vim.lsp.buf.rename, bufopts, "LSP rename" )
  -- map("n", "<F18>", vim.lsp.buf.rename, bufopts, "LSP rename (Shift+F6)" )
  map("n", "<leader>cf", "<cmd>lua vim.lsp.buf.format { async = true }<CR>", bufopts, "LSP format")
  map("n", "<M-C-L>", "<cmd>lua vim.lsp.buf.format { async = true }<CR>", bufopts, "LSP format (Ctrl+Alt+l)")

  map("n", "<leader>cs", vim.lsp.buf.signature_help, bufopts, "LSP signature help")
  -- map("n", "<leader>ce", vim.diagnostic.setloclist, bufopts, "LSP show errors" )
  -- map("n", "<leader>ca", vim.lsp.buf.code_action, bufopts, "LSP code action" )
  -- map("n", "<A-CR>", vim.lsp.buf.code_action, bufopts, "LSP code action (Alt+Enter)" )
  -- map("n", "<F25>", vim.diagnostic.open_float, bufopts, "LSP open message in floating window (Ctrl+F1)" )
end

-- configure setup on attach to a lsp server
local function attach(client, bufnr)
  -- setup global autocompletion
  vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")

  -- attach keymaps
  M.attach_keymaps(client, bufnr)
end

local function create_capabilities()
  -- return require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())
  local capabilities = vim.lsp.protocol.make_client_capabilities()

  capabilities.textDocument.completion.completionItem = {
    documentationFormat = { "markdown", "plaintext" },
    snippetSupport = true,
    preselectSupport = true,
    insertReplaceSupport = true,
    labelDetailsSupport = true,
    deprecatedSupport = true,
    commitCharactersSupport = true,
    tagSupport = { valueSet = { 1 } },
    resolveSupport = {
      properties = {
        "documentation",
        "detail",
        "additionalTextEdits",
      },
    },
  }
  return capabilities
end

M.setup = function()
  local lsp = require("lspconfig")

  -- setup lspconfig
  local capabilities = create_capabilities()

  -- setup servers for each programming language
  lsp.angularls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.bashls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.dockerls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.gopls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.html.setup({ on_attach = attach, capabilities = capabilities })
  lsp.jsonls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.lua_ls.setup({
    on_attach = attach,
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
        -- Do not send telemetry data containing a randomized but unique identifier
        telemetry = {
          enable = false,
        },
      },
    },
  })
  lsp.marksman.setup({ on_attach = attach, capabilities = capabilities })
  lsp.pylsp.setup({ on_attach = attach, capabilities = capabilities })
  lsp.rust_analyzer.setup({ on_attach = attach, capabilities = capabilities })
  lsp.sqlls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.terraform_lsp.setup({ cmd = { "terraform-ls", "serve" }, on_attach = attach, capabilities = capabilities })
  lsp.tsserver.setup({ on_attach = attach, capabilities = capabilities })
  lsp.vimls.setup({ on_attach = attach, capabilities = capabilities })
  lsp.yamlls.setup({
    on_attach = attach,
    capabilities = capabilities,
    settings = {
      yaml = {
        schemas = {
          ["https://raw.githubusercontent.com/instrumenta/kubernetes-json-schema/master/v1.18.0-standalone-strict/all.json"] = "/*.k8s.yaml",
          ["https://raw.githubusercontent.com/ansible/schemas/main/f/ansible.json"] = "/ansible/*.yml"
        }
      }
    }
  })
end

return M
