---Closes the fugitive status window if it is open.
---@return boolean True if the fugitive status window was closed, false otherwise.
local function close_fugitive_status()
  for _, winid in pairs(vim.api.nvim_list_wins()) do
    if pcall(vim.api.nvim_win_get_var, winid, "fugitive_status") then
      vim.api.nvim_win_close(winid, false)
      return true
    end
  end
  return false
end

---Checks if the given file matches the current path within the work tree.
---@param file table The file object from fugitive status.
---@param current_path string The normalized current file path.
---@param work_tree string The normalized work tree path.
---@return boolean True if the file matches the current path, false otherwise.
local function file_matches_current_path(file, current_path, work_tree)
  for _, relative_path in ipairs(file.relative or {}) do
    if vim.fs.normalize(work_tree .. "/" .. relative_path) == current_path then
      return true
    end
  end
  return false
end

---Finds the line number of the changed file in the fugitive status buffer that matches the current file path.
---@param current_file string The current file path to check against the changed files in the fugitive status buffer.
---@return number? The line number of the changed file in the fugitive status buffer, or nil if not found.
local function find_changed_file_line(current_file)
  local fugitive_status = vim.b.fugitive_status
  if current_file == "" or not fugitive_status or type(fugitive_status.work_tree) ~= "string" then
    return nil
  end

  local current_path = vim.fs.normalize(vim.fn.fnamemodify(current_file, ":p"))
  local work_tree = vim.fs.normalize(fugitive_status.work_tree)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local changed_files = fugitive_status.files or {}
  local sections = {
    changed_files.Unstaged or {},
    changed_files.Staged or {},
  }
  local untracked_files = {}
  for _, file in ipairs(fugitive_status.untracked or {}) do
    untracked_files[file.filename] = file
  end
  table.insert(sections, untracked_files)

  for _, files in ipairs(sections) do
    for line_number, line in ipairs(lines) do
      local filename = line:match("^[A-Z?] (.*)$") or ""
      local file = files[filename]
      if file and file_matches_current_path(file, current_path, work_tree) then
        return line_number
      end
    end
  end
end

---In vim-fugitive, what is displayed when there are some unstaged / staged files:
---
---  1. Head: main
---  2. Rebase: origin/main
---  3. Help: g?
---  4.
---  5. Unstaged (2) / Staged (2)
---  6. M home-manager/modules/share/editor/nvim/.config/nvim/lua/plugins/vcs/vim-fugitive.lua 
---
---Line 2 is not present sometimes (idk why), so the cursor to move is either line 5 or 6.
---
---@return number? The line number to move the cursor to in the fugitive status buffer, or nil if not applicable.
local function find_fallback_line()
  if vim.api.nvim_buf_line_count(0) < 5 then
    return nil
  end
  if vim.api.nvim_buf_get_lines(0, 1, 2, false)[1]:match("^Rebase:") then
    return 6
  end
  return 5
end

local function setup()
  vim.keymap.set("n", "<leader>gc", "<cmd>G commit --no-verify<cr>", { desc = "git commit" })
  vim.keymap.set("n", "<leader>gF", "<cmd>G push --force-with-lease<cr>", { desc = "git push --force-with-lease" })
  vim.keymap.set("n", "<leader>gp", "<cmd>G pull<cr>", { silent = true, noremap = true, desc = "git pull" })
  vim.keymap.set("n", "<leader>gP", "<cmd>G push<cr>", { silent = true, noremap = true, desc = "git push" })
  vim.keymap.set("n", "<M-0>", function()
    if close_fugitive_status() then
      return
    end

    vim.cmd("Git")

    local current_file = vim.api.nvim_buf_get_name(0)
    local target_line = find_changed_file_line(current_file) or find_fallback_line()
    if target_line then
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
