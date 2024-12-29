return {
  {
    "allaman/emoji.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = { "Emoji" },
    opts = { enable_cmp_integration = true },
    keys = {
      { "<leader>se", "<cmd>Emoji<cr>", noremap = true, silent = true, desc = "Emoji" },
      { "<M-;>", mode = "i", "<cmd>Emoji<cr>", desc = "Emoji" },
    },
  },
}
