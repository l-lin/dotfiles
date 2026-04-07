return {
  cmd = { "vtsls", "--stdio" },
  init_options = {
    hostInfo = "neovim",
  },
  filetypes = {
    "javascript",
    "javascriptreact",
    "javascript.jsx",
    "typescript",
    "typescriptreact",
    "typescript.tsx",
  },
  root_dir = function(bufnr, on_dir)
    local root_markers = {
      { "package-lock.json", "yarn.lock", "pnpm-lock.yaml", "bun.lockb", "bun.lock" },
      { ".git" },
    }
    local deno_root = vim.fs.root(bufnr, { "deno.json", "deno.jsonc" })
    local deno_lock_root = vim.fs.root(bufnr, { "deno.lock" })
    local project_root = vim.fs.root(bufnr, root_markers)
    if deno_lock_root and (not project_root or #deno_lock_root > #project_root) then
      return
    end
    if deno_root and (not project_root or #deno_root >= #project_root) then
      return
    end
    on_dir(project_root or vim.fn.getcwd())
  end,
  settings = {
    complete_function_calls = true,
    typescript = {
      inlayHints = {
        enumMemberValues = { enabled = true },
        functionLikeReturnTypes = { enabled = true },
        parameterNames = { enabled = "literals" },
        parameterTypes = { enabled = true },
        propertyDeclarationTypes = { enabled = true },
        variableTypes = { enabled = false },
      },
      suggest = {
        completeFunctionCalls = true,
      },
      tsserver = {
        maxTsServerMemory = 8192,
      },
      updateImportsOnFileMove = { enabled = "always" },
    },
    vtsls = {
      autoUseWorkspaceTsdk = true,
      enableMoveToFileCodeAction = true,
      experimental = {
        completion = {
          enableServerSideFuzzyMatch = true,
        },
      },
    },
  },
}
