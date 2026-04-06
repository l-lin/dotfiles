local function setup()
  vim.keymap.set("n", "<leader>gc", "<cmd>G commit --no-verify<cr>", { desc = "git commit" })
  vim.keymap.set("n", "<leader>gF", "<cmd>G push --force-with-lease<cr>", { desc = "git push --force-with-lease" })
  vim.keymap.set("n", "<leader>gp", "<cmd>G pull<cr>", { silent = true, noremap = true, desc = "git pull" })
  vim.keymap.set("n", "<leader>gP", "<cmd>G push<cr>", { silent = true, noremap = true, desc = "git push" })
  vim.keymap.set("n", "<M-0>", function()
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
  vim.keymap.set("n", "<leader>gB", function()
    require("functions.git").browse_with_branch_select()
  end, { desc = "Git Browse (open)", noremap = true })
  vim.keymap.set(
    "x",
    "<leader>gB",
    ":<C-u>lua require('functions.git').browse_with_branch_select({ visual = true })<CR>",
    { desc = "Git Browse (open)", noremap = true }
  )
  vim.keymap.set("n", "<leader>gY", function()
    require("functions.git").browse_with_branch_select({ yank = true })
  end, { desc = "Git Browse (yank)", noremap = true })
  vim.keymap.set(
    "x",
    "<leader>gY",
    ":<C-u>lua require('functions.git').browse_with_branch_select({ yank = true, visual = true })<CR>",
    { desc = "Git Browse (yank)", noremap = true }
  )
  vim.keymap.set("n", "<leader>go", "<cmd>!gh repo view --web<cr>", { desc = "Open GitHub repository in browser", noremap = true })
  vim.keymap.set("n", "<leader>gO", "<cmd>!gh pr view --web<cr>", { desc = "Open GitHub pull request in browser", noremap = true })

  if package.loaded["snacks"] then
    vim.keymap.set("n", "<leader>gb", function()
      Snacks.picker.git_log_line({ current_line = true, current_file = true, follow = true })
    end, { desc = "Git Blame Line" })
    vim.keymap.set("n", "<leader>gs", function()
      Snacks.picker.git_status({ layout = "sidebar" })
    end, { desc = "Git Status" })
    vim.keymap.set("n", "<leader>gl", function()
      Snacks.picker.git_log({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() })
    end, { desc = "Git Log" })
    vim.keymap.set("n", "<leader>gL", function()
      Snacks.picker.git_log()
    end, { desc = "Git Log (cwd)" })
    vim.keymap.set("n", "<M-9>", function()
      Snacks.picker.git_log({ current_file = true, follow = true })
    end, { noremap = true, silent = true, desc = "Check current file git history (Alt+9)" })
    vim.keymap.set("n", "<leader>G", function()
      Snacks.picker.gh_pr()
    end, { desc = "GitHub Pull Requests (open)" })
    vim.keymap.set("n", "<M-)>", function()
      Snacks.lazygit({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() })
    end, { desc = "LazyGit open history", noremap = true })
  end
end

---@type vim.pack.Spec
return
-- fugitive.vim: A Git wrapper so awesome, it should be illegal
{
  src = "https://github.com/tpope/vim-fugitive",
  data = { setup = function ()
    vim.schedule(setup)
  end },
}
