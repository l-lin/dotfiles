---@type vim.pack.Spec
return
-- Review AI-generated diffs directly inside Neovim using snacks.picker.
{
  src = "https://codeberg.org/l-lin/review-ai.nvim",
  data = {
    setup = function()
      vim.schedule(function ()
        require("review-ai").setup()
        vim.keymap.set("n", "<leader>ar", "<cmd>ReviewAi<cr>", { desc = "Review AI changes" })
      end)
    end,
  },
}
