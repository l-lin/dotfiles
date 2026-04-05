--
-- 💥 Create key bindings that stick. WhichKey helps you remember your Neovim keymaps, by showing available keybindings in a popup as you type.
--

---@type vim.pack.Spec
return {
  src = "https://github.com/folke/which-key.nvim",
  data = {
    setup = function()
      local wk = require("which-key")
      wk.setup({ preset = "helix" })
      wk.add({
        { "<leader>a", group = "ai" },
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "file/find" },
        { "<leader>fx", group = "execute" },
        { "<leader>g", group = "git" },
        { "<leader>j", group = "jira" },
        { "<leader>n", group = "notes" },
        { "<leader>o", group = "obsidian" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "test" },
        { "<leader>u", group = "ui" },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "<leader>y", group = "yank" },
        { "[", group = "previous" },
        { "]", group = "next" },
        { "g", group = "goto" },
      })
    end,
  },
}
