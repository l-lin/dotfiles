return {
  --
  -- A plugin sda a to search for and insert emojis/kaomojis, with auto-completion support, right from Neovim 😀
  --
  {
    "l-lin/emoji.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Emoji" },
    keys = {
      { "<leader>se", "<cmd>Emoji<cr>", noremap = true, silent = true, desc = "Emoji" },
      { "<M-;>", mode = "i", "<cmd>Emoji<cr>", desc = "Emoji" },
    },
  },
}
