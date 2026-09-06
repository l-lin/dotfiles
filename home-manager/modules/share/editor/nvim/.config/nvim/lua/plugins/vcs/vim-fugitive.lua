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
    if line_count >= 5 then
      -- In vim-fugitive, what is displayed when there are some unstaged / staged files:
      --
      --   1. Head: main
      --   2. Rebase: origin/main
      --   3. Help: g?
      --   4.
      --   5. Unstaged (2) / Staged (2)
      --   6. M home-manager/modules/share/editor/nvim/.config/nvim/lua/plugins/vcs/vim-fugitive.lua 
      --
      -- Line 2 is not present sometimes (idk why), so the cursor to move is either line 5 or 6.
      local target_line = 5
      if vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]:match("^Rebase:") then
        target_line = 6
      end
      vim.api.nvim_win_set_cursor(0, { target_line, 0 })
    end
  end, { silent = true, noremap = true, desc = "git status (Alt+0)" })
  -- stylua: ignore start
  vim.keymap.set("n", "<leader>gb", function() require("functions.gitbrowse").browse_with_branch_select() end, { desc = "Git Browse (open)", noremap = true })
  vim.keymap.set( "x", "<leader>gb", ":<C-u>lua require('functions.gitbrowse').browse_with_branch_select({ visual = true })<CR>", { desc = "Git Browse (open)", noremap = true })
  vim.keymap.set("n", "<leader>gy", function() require("functions.gitbrowse").browse_with_branch_select({ yank = true }) end, { desc = "Git Browse (yank)", noremap = true })
  vim.keymap.set( "x", "<leader>gy", ":<C-u>lua require('functions.gitbrowse').browse_with_branch_select({ yank = true, visual = true })<CR>", { desc = "Git Browse (yank)", noremap = true })
  vim.keymap.set("n", "<leader>go", "<cmd>!gh repo view --web<cr>", { desc = "Open GitHub repository in browser", noremap = true })
  vim.keymap.set("n", "<leader>gO", "<cmd>!gh pr view --web<cr>", { desc = "Open GitHub pull request in browser", noremap = true })
  -- stylua: ignore end
end

---@type vim.pack.Spec
return
-- fugitive.vim: A Git wrapper so awesome, it should be illegal
{
  src = "https://github.com/tpope/vim-fugitive",
  data = {
    setup = function()
      vim.schedule(setup)
    end,
  },
}
