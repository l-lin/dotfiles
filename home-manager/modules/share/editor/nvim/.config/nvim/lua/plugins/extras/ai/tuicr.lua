return {
  -- Neovim plugin to code reviewing AI-generated code
  {
    "https://codeberg.org/l-lin/tuicr.nvim",
    dev = true,
    cmd = { "TuicrReview" },
    keys = {
      { "<leader>ar", "<cmd>TuicrReview<cr>", desc = "Review AI changes"}
    },
    opts = {},
  },
}
