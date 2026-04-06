return {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = {
    { ".emmyrc.json", ".luarc.json", ".luarc.jsonc" },
    { ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
    { ".git" },
  },
  ---@type lspconfig.settings.lua_ls
  settings = {
    Lua = {
      workspace = {
        checkThirdParty = false,
        -- NOTE: Uncomment the following if you don't want to use lazydev.
        -- library = vim.api.nvim_get_runtime_file("", true),
      },
      completion = {
        callSnippet = "Replace",
      },
      hint = {
        enable = true,
        setType = false,
        paramType = true,
        paramName = "Disable",
        semicolon = "Disable",
        arrayIndex = "Disable",
      },
      diagnostics = {
        -- NOTE: You can add your own global variables here.
        -- globals = { "LazyVim", "Snacks" },
      },
    },
  },
}
