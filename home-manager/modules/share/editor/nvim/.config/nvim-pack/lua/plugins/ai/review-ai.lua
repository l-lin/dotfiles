---@type vim.pack.Spec
return {
  src = "https://codeberg.org/l-lin/review-ai.nvim",
  data = {
    setup = function()
      require("review-ai").setup()
    end,
    ---@param map fun(mode: string|string[], lhs: string, rhs: string|function, opts?: table)
    keymaps = function(map)
      map("n", "<leader>ar", "<cmd>ReviewAi<cr>", { desc = "Review AI changes" })
    end,
  },
}
