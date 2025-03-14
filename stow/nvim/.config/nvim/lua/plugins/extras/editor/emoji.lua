return {
  -- Emoji source for blink.nvim.
  {
    "allaman/emoji.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Emoji" },
    keys = {
      { "<leader>se", "<cmd>Emoji<cr>", noremap = true, silent = true, desc = "Emoji" },
      { "<M-;>", mode = "i", "<cmd>Emoji<cr>", desc = "Emoji" },
    },
  },
}
