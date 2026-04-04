--
-- A Git wrapper so awesome, it should be illegal
--

--
-- Keymaps
--
local map = vim.keymap.set
map("n", "<leader>gc", "<cmd>G commit --no-verify<cr>", { desc = "git commit" })
map("n", "<leader>gF", "<cmd>G push --force-with-lease<cr>", { desc = "git push --force-with-lease" })
map("n", "<leader>gp", "<cmd>G pull<cr>", { silent = true, noremap = true, desc = "git pull" })
map("n", "<leader>gP", "<cmd>G push<cr>", { silent = true, noremap = true, desc = "git push" })
map("n", "<M-0>", function()
  local winids = vim.api.nvim_list_wins()
  for _, id in pairs(winids) do
    local status = pcall(vim.api.nvim_win_get_var, id, "fugitive_status")
    if status then
      vim.api.nvim_win_close(id, false)
      return
    end
  end
  vim.cmd("Git")

  local line_count = vim.api.nvim_buf_line_count(0)
  if line_count >= 6 then
    vim.api.nvim_win_set_cursor(0, { 6, 0 })
  end
end, { silent = true, noremap = true, desc = "git status (Alt+0)" })
map("n", "<leader>gB", function()
  require("functions.git").browse_with_branch_select()
end, { desc = "Git Browse (open)", noremap = true })
map(
  "x",
  "<leader>gB",
  ":<C-u>lua require('helpers.git').browse_with_branch_select({ visual = true })<CR>",
  { desc = "Git Browse (open)", noremap = true }
)
map("n", "<leader>gY", function()
  require("functions.git").browse_with_branch_select({ yank = true })
end, { desc = "Git Browse (yank)", noremap = true })
map(
  "x",
  "<leader>gY",
  ":<C-u>lua require('helpers.git').browse_with_branch_select({ yank = true, visual = true })<CR>",
  { desc = "Git Browse (yank)", noremap = true }
)
map("n", "<leader>go", "<cmd>!gh repo view --web<cr>", { desc = "Open GitHub repository in browser", noremap = true })
map("n", "<leader>gO", "<cmd>!gh pr view --web<cr>", { desc = "Open GitHub pull request in browser", noremap = true })
if package.loaded["snacks"] then
  map("n", "<leader>gb", function()
    Snacks.picker.git_log_line({ current_line = true, current_file = true, follow = true })
  end, { desc = "Git Blame Line" })
  map("n", "<leader>gs", function()
    Snacks.picker.git_status({ layout = "sidebar" })
  end, { desc = "Git Status" })
  map("n", "<leader>gl", function()
    Snacks.picker.git_log({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() })
  end, { desc = "Git Log" })
  map("n", "<leader>gL", function()
    Snacks.picker.git_log()
  end, { desc = "Git Log (cwd)" })
  map("n", "<M-9>", function()
    Snacks.picker.git_log({ current_file = true, follow = true })
  end, { noremap = true, silent = true, desc = "Check current file git history (Alt+9)" })
  map("n", "<leader>G", function()
    Snacks.picker.gh_pr()
  end, { desc = "GitHub Pull Requests (open)" })
  map("n", "<M-)>", function()
    Snacks.lazygit({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() })
  end, { desc = "LazyGit open history", noremap = true })
end
