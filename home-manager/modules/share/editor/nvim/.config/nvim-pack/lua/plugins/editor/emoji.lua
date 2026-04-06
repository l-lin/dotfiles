---@type vim.pack.Spec[]
return {
  -- Dependency for plenary's async functions and popup API.
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
  },
  -- A plugin to search for and insert emojis/kaomojis, with auto-completion support, right from Neovim 😀.
  {
    src = "https://github.com/l-lin/emoji.nvim",
    data = {
      setup = function()
        vim.keymap.set("n", "<leader>se", "<cmd>Emoji<cr>", {
          desc = "Emoji",
          noremap = true,
          silent = true,
        })
        vim.keymap.set("i", "<M-;>", "<cmd>Emoji<cr>", { desc = "Emoji" })
      end,
    },
  },
}
