-- Keymaps are automatically loaded on the VeryLazy event.
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua.
-- Add any additional keymaps here.

---Put the cursor in the middle of the screen, only when navigating with count.
---No need to move the whole screen when moving line by line.
---@param key string either 'j' or 'k'
local function cursor_to_middle_of_screen(key)
  if vim.v.count > 1 then
    vim.api.nvim_command("norm! " .. vim.v.count .. key .. "zz")
  else
    vim.api.nvim_command("norm! " .. key)
  end
end

---Join lines without trailing whitespaces
local function remove_trailing_whitespaces()
  vim.api.nvim_command("norm! JdiW")
end

local map = vim.keymap.set

-- buffer
-- Same behavior as browsers (muscle memory).
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer (Ctrl+F4)" })

-- yank file path / name
map("n", "<leader>yf", "<cmd>let @+=expand('%:.')<CR>", { noremap = true, desc = "Copy current buffer relative path to clipboard" })
map("n", "<leader>yF", "<cmd>let @+=expand('%:p')<CR>", { noremap = true, desc = "Copy current buffer absolute path to clipboard" })
map("n", "<leader>yn", "<cmd>let @+=expand('%:t')<CR>", { noremap = true, desc = "Copy current buffer file name to clipboard" })

-- remove keymaps set globally by LazyVim
-- use default H and L to navigate
vim.keymap.del("n", "<S-h>")
vim.keymap.del("n", "<S-l>")
-- remove those keymaps so that I use the <M-C-hjkl> instead
vim.keymap.del("n", "<C-h>")
vim.keymap.del("n", "<C-j>")
vim.keymap.del("n", "<C-k>")
vim.keymap.del("n", "<C-l>")

-- navigation
-- Always put cursor at middle of screen.
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })
map("n", "<S-h>", "<S-h>zz", { noremap = true })
map("n", "<S-l>", "<S-l>zz", { noremap = true })
map("n", "{", "{zz", { noremap = true })
map("n", "}", "}zz", { noremap = true })
map("n", "j", function() cursor_to_middle_of_screen("j") end, { noremap = true })
map("n", "k", function() cursor_to_middle_of_screen("k") end, { noremap = true })
-- search
map("n", "n", "nzzzv", { noremap = true })
map("n", "N", "Nzzzv", { noremap = true })

-- tab
map("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })

-- special keymap to cut to black hole, so I don't lose what I yank to my register '+'
map({ "n", "v" }, "<M-d>", '"_d', { noremap = true })

-- documentation
vim.api.nvim_create_user_command('CheatSheet', function()
  vim.cmd('split ' .. vim.fn.expand(vim.fn.stdpath("config") .. '/doc/cheat_sheet.txt'))
end, {})

-- diagnostics (same behavior as IntelliJ)
map("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
map("n", "<F2>", function () vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic (F2)" })

-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

-- remove trailing whitespaces
map("n", "gJ", remove_trailing_whitespaces, { noremap = true, silent = true, desc = "Join line without whitespace" })

-- Toggle executable permission on current file.
map("n", "<leader>fxx", function()
  local file = vim.fn.expand("%")
  local perms = vim.fn.getfperm(file)
  local is_executable = string.match(perms, "x", -1) ~= nil
  local escaped_file = vim.fn.shellescape(file)
  if is_executable then
    vim.cmd("silent !chmod -x " .. escaped_file)
    vim.notify("Removed executable permission", vim.log.levels.INFO)
  else
    vim.cmd("silent !chmod +x " .. escaped_file)
    vim.notify("Added executable permission", vim.log.levels.INFO)
  end
end, { desc = "Toggle executable permission" })

-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
map("n", "<leader>fxx", function()
  local filename = vim.fn.expand("%")
  local first_line = vim.fn.getline(1)
  -- Check if the bash script is valid by checking if it contains a shebang.
  if string.match(first_line, "^#!/") then
    -- Properly escape the file name for shell commands
    local escaped_file = vim.fn.shellescape(filename)
    -- Make the file executable
    vim.cmd("silent !chmod +x " .. escaped_file)

    -- Execute the script on a new tmux pane below.
    vim.cmd(
      "silent !tmux split-window -v -l 20 'bash -c \"./"
        .. escaped_file
        .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"
    )
  else
    vim.cmd("echo 'Not a script. Shebang line not found.'")
  end
end, { desc = "Bash script" })

-- Remove floating terminal keyamps (I use Tmux, no need for embedded terminal).
vim.keymap.del("n", "<leader>fT")
vim.keymap.del("n", "<leader>ft")
vim.keymap.del("n", "<c-/>")
vim.keymap.del("n", "<c-_>")

-- Do not select the next search element, so that I can easily do `cgn`.
map("n", "*", "*N", { noremap = true, silent = true })
map("n", "#", "#N", { noremap = true, silent = true })
