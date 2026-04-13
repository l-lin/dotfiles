--
-- Files
--
-- save file
vim.keymap.set({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
-- Toggle executable permission on current file.
vim.keymap.set("n", "<leader>fxt", function() require("functions.file").toggle_executable_permission() end, { desc = "Toggle executable permission" })
-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
vim.keymap.set("n", "<leader>fxx", function() require("functions.file").execute_bash_script() end, { desc = "Execute bash script" })
-- new file
vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
-- Scratch buffer mode: quickly exit neovim with classic keybinds.
if vim.env.NVIM_SCRATCH then
  vim.keymap.set("i", "<C-s>", "<Esc>ZQ", { desc = "Quit scratch buffer" })
  vim.keymap.set("n", "q", "ZQ", { desc = "Quit scratch buffer" })
end

--
-- Windows
--
-- Move to window using the <ctrl> hjkl keys
vim.keymap.set("n", "<M-C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<M-C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<M-C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<M-C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
-- Resize window using <ctrl> arrow keys
vim.keymap.set("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
vim.keymap.set("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
vim.keymap.set("n", "<C-Left>", "<cmd>vertical resize +2<cr>", { desc = "Decrease Window Width" })
vim.keymap.set("n", "<C-Right>", "<cmd>vertical resize -2<cr>", { desc = "Increase Window Width" })

--
-- Buffer
--
-- Same behavior as browsers (muscle memory).
vim.keymap.set("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer (Ctrl+F4)" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<CR>", { noremap = true, silent = true, desc = "Switch to Other Buffer" })

--
-- Yank
--
-- yank file path / name
vim.keymap.set("n", "<leader>yf", function() require("functions.yank").yank_relative_path() end, { noremap = true, desc = "Copy current buffer relative path to clipboard" })
vim.keymap.set("n", "<leader>yF", function() require("functions.yank").yank_absolute_path() end, { noremap = true, desc = "Copy current buffer absolute path to clipboard" })
vim.keymap.set("n", "<leader>yn", function() require("functions.yank").yank_filename() end, { noremap = true, desc = "Copy current buffer file name to clipboard" })
vim.keymap.set("x", "<leader>yf", ":<C-u>lua require('functions.yank').yank_relative_path_with_line_range()<CR>", { noremap = true, desc = "Copy relative file path with line range" })
vim.keymap.set("x", "<leader>yF", ":<C-u>lua require('functions.yank').yank_absolute_path_with_line_range()<CR>", { noremap = true, desc = "Copy absolute file path with line range" })
-- special keymap to cut to black hole, so I don't lose what I yank to my register '+'
vim.keymap.set({ "n", "v" }, "<M-d>", '"_d', { noremap = true })

--
--
-- Navigation
--
-- Cursor at middle of screen
vim.keymap.set("n", "<C-d>", "<C-d>zz", { noremap = true })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { noremap = true })
vim.keymap.set("n", "<S-h>", "<S-h>zz", { noremap = true })
vim.keymap.set("n", "<S-l>", "<S-l>zz", { noremap = true })
vim.keymap.set("n", "{", "{zz", { noremap = true })
vim.keymap.set("n", "}", "}zz", { noremap = true })
vim.keymap.set("n", "j", function() require("functions.cursor").move_to_middle_of_screen("j") end, { noremap = true })
vim.keymap.set("n", "k", function() require("functions.cursor").move_to_middle_of_screen("k") end, { noremap = true })
vim.keymap.set("n", "n", "nzzzv", { noremap = true })
vim.keymap.set("n", "N", "Nzzzv", { noremap = true })
-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
vim.keymap.set("x", "$", "g_")

--
-- Fold
--
-- Close all folds except current one (great for focus)
vim.keymap.set("n", "zv", "zMzvzz", { desc = "Close all folds except the current one" })

--
-- Tab
--
vim.keymap.set("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
vim.keymap.set("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })
vim.keymap.set("n", "<leader><tab>l", "<cmd>tablast<cr>", { desc = "Last Tab" })
vim.keymap.set("n", "<leader><tab>o", "<cmd>tabonly<cr>", { desc = "Close Other Tabs" })
vim.keymap.set("n", "<leader><tab>f", "<cmd>tabfirst<cr>", { desc = "First Tab" })
vim.keymap.set("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", { desc = "New Tab" })
vim.keymap.set("n", "<leader><tab>]", "<cmd>tabnext<cr>", { desc = "Next Tab" })
vim.keymap.set("n", "<leader><tab>d", "<cmd>tabclose<cr>", { desc = "Close Tab" })
vim.keymap.set("n", "<leader><tab>[", "<cmd>tabprevious<cr>", { desc = "Previous Tab" })

--
-- Lines
--
-- Move Lines
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
-- Smart j/k: moves by visual lines when no count, real lines with count
-- vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
-- vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })
-- remove trailing whitespaces
vim.keymap.set("n", "gJ", function() vim.api.nvim_command("norm! JdiW") end, { noremap = true, silent = true, desc = "Join line without whitespace" })
-- Open link under cursor with either browser in private window for youtube links, short reponame in browser, or fallback to gx
vim.keymap.set("n", "gx", function() require("functions.open").smart_open() end, { desc = "Smart open URL or filepath" })
-- better indenting
vim.keymap.set("x", "<", "<gv")
vim.keymap.set("x", ">", ">gv")

-- Auto-close pairs (simple, no plugin needed)
-- vim.keymap.set("i", "`", "``<left>")
-- vim.keymap.set("i", '"', '""<left>')
-- vim.keymap.set("i", "(", "()<left>")
-- vim.keymap.set("i", "[", "[]<left>")
-- vim.keymap.set("i", "{", "{}<left>")
-- vim.keymap.set("i", "<", "<><left>")

--
-- Search
--
-- Clear search and stop snippet on escape
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
vim.keymap.set("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
vim.keymap.set("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
vim.keymap.set("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
vim.keymap.set("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
-- Do not select the next search element, so that I can easily do `cgn`.
vim.keymap.set("n", "*", "*N", { noremap = true, silent = true })
vim.keymap.set("n", "#", "#N", { noremap = true, silent = true })

--
-- LSP
--
-- diagnostics
local diagnostic_goto = function(next, severity)
  return function()
    vim.diagnostic.jump({
      count = (next and 1 or -1) * vim.v.count1,
      severity = severity and vim.diagnostic.severity[severity] or nil,
      float = true,
    })
  end
end
vim.keymap.set("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
vim.keymap.set("n", "<F2>", function () vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic (F2)" })
vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
vim.keymap.set("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
vim.keymap.set("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
-- commenting
vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })

--
-- Quickfix list
--
local function toggle_quickfix_list()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end
vim.keymap.set("n", "<leader>xq", toggle_quickfix_list, { desc = "Quickfix List" })
vim.keymap.set("n", "<M-3>", toggle_quickfix_list, { desc = "Quickfix list"})
vim.keymap.set("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
vim.keymap.set("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })

--
-- Location list
--
vim.keymap.set("n", "<leader>xl", function()
  local success, err = pcall(vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 and vim.cmd.lclose or vim.cmd.lopen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Location List" })
