local lsp = require('lspconfig')

-- configure setup on attach to a lsp server
local custom_attach = function(_, bufnr)

    -- setup diagnostics toggle on and off
    vim.g.diagnostics_visible = true
    function _G.toggle_diagnostics()
        if vim.g.diagnostics_visible then
            vim.g.diagnostics_visible = false
            vim.diagnostic.disable()
            print("Diagnostics disabled")
        else
            vim.g.diagnostics_visible = true
            vim.diagnostic.enable()
            print("Diagnostics enabled")
        end
    end

    vim.api.nvim_buf_set_keymap(0, 'n', '<Leader>ct', ':call v:lua.toggle_diagnostics()<CR>', { silent = true,
        noremap = true, desc = "Diagnostics Toggle" })

    -- setup global autocompletion
    vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

    -- keymaps
    vim.keymap.set('n', ']w', vim.diagnostic.goto_next,
        { noremap = true, silent = true, buffer = bufnr, desc = "Diagnostic go to next" })
    vim.keymap.set('n', '[w', vim.diagnostic.goto_prev,
        { noremap = true, silent = true, buffer = bufnr, desc = "Diagnostic go to previous" })
    vim.keymap.set('n', '<leader>ch', '<cmd>lua vim.lsp.buf.hover() vim.lsp.buf.hover()<cr>',
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP show hovering help" })
    vim.keymap.set('n', '<leader>cd', vim.lsp.buf.definition,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP definition" })
    vim.keymap.set('n', '<leader>cD', vim.lsp.buf.declaration,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP declaration" })
    vim.keymap.set('n', '<leader>ci', vim.lsp.buf.implementation,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP implementation" })
    vim.keymap.set('n', '<leader>co', vim.lsp.buf.type_definition,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP type definition" })
    vim.keymap.set('n', '<leader>cu', vim.lsp.buf.references,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP references" })
    vim.keymap.set('n', '<leader>cs', vim.lsp.buf.signature_help,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP signature help" })
    vim.keymap.set('n', '<S-k>', vim.lsp.buf.signature_help,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP signature help" })
    vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP rename" })
    vim.keymap.set('n', '<leader>cf', '<cmd>lua vim.lsp.buf.format { async = true }<CR>',
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP format" })
    vim.keymap.set('n', '<leader>ce', vim.diagnostic.setloclist,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP show errors" })
    vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP code action" })
    vim.keymap.set('n', '<A-CR>', vim.lsp.buf.code_action,
        { noremap = true, silent = true, buffer = bufnr, desc = "LSP code action" })
end

-- Setup lspconfig.
local capabilities = require('cmp_nvim_lsp').default_capabilities(vim.lsp.protocol.make_client_capabilities())

-- setup servers for each programming language
lsp.pylsp.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.sumneko_lua.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = { 'vim' },
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
lsp.vimls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.bashls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.yamlls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.gopls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.sqls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.dockerls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.jsonls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.yamlls.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.html.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.marksman.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
lsp.rust_analyzer.setup {
    on_attach = custom_attach,
    capabilities = capabilities,
}
