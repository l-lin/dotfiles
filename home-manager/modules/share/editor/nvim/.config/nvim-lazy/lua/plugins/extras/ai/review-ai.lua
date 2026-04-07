return {
  -- Neovim plugin to code reviewing AI-generated code
  {
    "https://codeberg.org/l-lin/review-ai.nvim",
    cmd = { "ReviewAi" },
    keys = {
      { "<leader>ar", "<cmd>ReviewAi<cr>", desc = "Review AI changes"}
    },
    opts = {},
  },
}
