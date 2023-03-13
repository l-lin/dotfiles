local null_ls = require("null-ls")

null_ls.setup({
  -- https://github.com/jose-elias-alvarez/null-ls.nvim/blob/main/doc/BUILTINS.md
  sources = {
    null_ls.builtins.formatting.stylua,

    -- ansible
    -- null_ls.builtins.diagnostics.ansiblelint,
    -- -- protobuf
    -- null_ls.builtins.diagnostics.buf,
    -- -- dockerfile
    -- null_ls.builtins.diagnostics.hadolint,
    -- -- rust
    -- null_ls.builtins.diagnostics.ltrs,
    -- -- lua
    -- null_ls.builtins.diagnostics.luacheck,
    -- -- shell
    -- null_ls.builtins.diagnostics.shellcheck,
    -- -- openapi
    -- null_ls.builtins.diagnostics.spectral,
    -- -- terraform
    -- null_ls.builtins.diagnostics.terraform_validate,
    -- null_ls.builtins.diagnostics.tfsec,
    -- english prose
    null_ls.builtins.diagnostics.write_good,
    -- js, ts
    --null_ls.builtins.diagnostics.xo,

    -- git operations
    null_ls.builtins.code_actions.gitsigns,
    -- golang tool to modify struct field tags
    -- null_ls.builtins.code_actions.gomodifytags,
    -- -- rust
    -- null_ls.builtins.code_actions.ltrs,
    -- -- english prose linter
    -- null_ls.builtins.code_actions.proselint,
    -- -- refactoring
    -- null_ls.builtins.code_actions.refactoring,
    -- -- shellcheck
    -- null_ls.builtins.code_actions.shellcheck,
    -- -- js, ts
    -- null_ls.builtins.code_actions.xo,
  },
})
