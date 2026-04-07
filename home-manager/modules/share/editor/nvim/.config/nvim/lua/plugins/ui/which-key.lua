local function setup()
  require("which-key").setup({
    preset = "helix",
    spec = {
      {
        mode = { "n", "x" },
        { "<leader><tab>", group = "tabs" },
        { "<leader>a", group = "ai" },
        {
          "<leader>b",
          group = "buffer",
          expand = function()
            return require("which-key.extras").expand.buf()
          end,
        },
        { "<leader>c", group = "code" },
        { "<leader>d", group = "debug" },
        { "<leader>f", group = "file/find" },
        { "<leader>fx", group = "execute" },
        { "<leader>g", group = "git" },
        { "<leader>l", group = "plugins" },
        { "<leader>n", group = "notes" },
        { "<leader>s", group = "search" },
        { "<leader>t", group = "test" },
        { "<leader>u", group = "ui" },
        {
          "<leader>w",
          group = "windows",
          proxy = "<c-w>",
          expand = function()
            return require("which-key.extras").expand.win()
          end,
        },
        { "<leader>x", group = "diagnostics/quickfix" },
        { "<leader>y", group = "yank" },
        { "[", group = "previous" },
        { "]", group = "next" },
        { "g", group = "goto" },
        { "gx", desc = "Open with system app" },
        { "z", group = "fold" },
      },
    },
  })

  vim.keymap.set("n", "<leader>?", function()
    require("which-key").show({ global = false })
  end, { desc = "Buffer Keymaps (which-key)" })
  vim.keymap.set("n", "<c-w><space>", function()
    require("which-key").show({ keys = "<c-w>", loop = true })
  end, { desc = "Window Hydra Mode (which-key)" })
end

---@type vim.pack.Spec
return
-- 💥 Create key bindings that stick. WhichKey helps you remember your Neovim keymaps, by showing available keybindings in a popup as you type.
{
  src = "https://github.com/folke/which-key.nvim",
  data = {
    setup = function()
      vim.schedule(setup)
    end,
  },
}
