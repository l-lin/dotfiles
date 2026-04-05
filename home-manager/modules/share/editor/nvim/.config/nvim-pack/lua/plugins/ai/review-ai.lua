--
-- Review AI-generated diffs directly inside Neovim using snacks.picker.
--
require("review-ai").setup()
vim.keymap.set("n", "<leader>ar", "<cmd>ReviewAi<cr>", { desc = "Review AI changes" })
