local map = vim.keymap.set

--
-- Files
--
-- save file
map({ "i", "x", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save File" })
-- Toggle executable permission on current file.
map("n", "<leader>fxt", function() require("functions.file").toggle_executable_permission() end, { desc = "Toggle executable permission" })
-- If this is a bash script, make it executable, and execute it in a tmux pane on the right
map("n", "<leader>fxx", function() require("functions.file").execute_bash_script() end, { desc = "Execute bash script" })
-- new file
map("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New File" })
-- Scratch buffer mode: quickly exit neovim with classic keybinds.
if vim.env.NVIM_SCRATCH then
  map("i", "<C-s>", "<Esc>ZQ", { desc = "Quit scratch buffer" })
  map("n", "q", "ZQ", { desc = "Quit scratch buffer" })
end

--
-- Windows
--
-- Move to window using the <ctrl> hjkl keys
map("n", "<M-C-h>", "<C-w>h", { desc = "Go to Left Window", remap = true })
map("n", "<M-C-j>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
map("n", "<M-C-k>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
map("n", "<M-C-l>", "<C-w>l", { desc = "Go to Right Window", remap = true })
-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

--
-- Buffer
--
-- Same behavior as browsers (muscle memory).
map("n", "<F28>", "<cmd>bd<CR>", { noremap = true, silent = true, desc = "Close current buffer (Ctrl+F4)" })

--
-- Yank
--
-- yank file path / name
map("n", "<leader>yf", function() require("functions.yank").yank_relative_path() end, { noremap = true, desc = "Copy current buffer relative path to clipboard" })
map("n", "<leader>yF", function() require("functions.yank").yank_absolute_path() end, { noremap = true, desc = "Copy current buffer absolute path to clipboard" })
map("n", "<leader>yn", function() require("functions.yank").yank_filename() end, { noremap = true, desc = "Copy current buffer file name to clipboard" })
map("x", "<leader>yf", ":<C-u>lua require('helpers.yank').yank_relative_path_with_line_range()<CR>", { noremap = true, desc = "Copy file path with line range" })
-- special keymap to cut to black hole, so I don't lose what I yank to my register '+'
map({ "n", "v" }, "<M-d>", '"_d', { noremap = true })

--
--
-- Navigation
--
-- Cursor at middle of screen
map("n", "<C-d>", "<C-d>zz", { noremap = true })
map("n", "<C-u>", "<C-u>zz", { noremap = true })
map("n", "<S-h>", "<S-h>zz", { noremap = true })
map("n", "<S-l>", "<S-l>zz", { noremap = true })
map("n", "{", "{zz", { noremap = true })
map("n", "}", "}zz", { noremap = true })
map("n", "j", function() require("functions.cursor").move_to_middle_of_screen("j") end, { noremap = true })
map("n", "k", function() require("functions.cursor").move_to_middle_of_screen("k") end, { noremap = true })
map("n", "n", "nzzzv", { noremap = true })
map("n", "N", "Nzzzv", { noremap = true })
-- do not include white space characters when using $ in visual mode, see https://vi.stackexchange.com/q/12607/15292
map("x", "$", "g_")

--
-- Tab
--
map("n", "]<tab>", "<cmd>tabnext<cr>", { noremap = true, desc = "Next Tab" })
map("n", "[<tab>", "<cmd>tabprevious<cr>", { noremap = true, desc = "Previous Tab" })

--
-- Lines
--
-- Move Lines
map("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
map("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
map("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
map("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
map("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
map("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })
-- remove trailing whitespaces
map("n", "gJ", function() vim.api.nvim_command("norm! JdiW") end, { noremap = true, silent = true, desc = "Join line without whitespace" })
-- Open link under cursor with either browser in private window for youtube links, short reponame in browser, or fallback to gx
map("n", "gx", function() require("functions.open").smart_open() end, { desc = "Smart open URL or filepath" })
-- better indenting
map("x", "<", "<gv")
map("x", ">", ">gv")

--
-- Search
--
-- Clear search and stop snippet on escape
map({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })
-- https://github.com/mhinz/vim-galore#saner-behavior-of-n-and-n
map("n", "n", "'Nn'[v:searchforward].'zv'", { expr = true, desc = "Next Search Result" })
map("x", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("o", "n", "'Nn'[v:searchforward]", { expr = true, desc = "Next Search Result" })
map("n", "N", "'nN'[v:searchforward].'zv'", { expr = true, desc = "Prev Search Result" })
map("x", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
map("o", "N", "'nN'[v:searchforward]", { expr = true, desc = "Prev Search Result" })
-- Do not select the next search element, so that I can easily do `cgn`.
map("n", "*", "*N", { noremap = true, silent = true })
map("n", "#", "#N", { noremap = true, silent = true })

--
-- LSP
--
-- TODO: move to lsp?
map("n", "<leader>ci", vim.lsp.buf.implementation, { desc = "Goto implementation" })
map("n", "<leader>ct", vim.lsp.buf.type_definition, { desc = "Goto Type definition" })
map("n", "<leader>cu", vim.lsp.buf.references, { desc = "References / Usages" })
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
map("n", "<F25>", vim.diagnostic.open_float, { desc = "Line Diagnostics (Ctrl+F1)" })
map("n", "<F2>", function () vim.diagnostic.jump({ count = 1 }) end, { desc = "Next diagnostic (F2)" })
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line Diagnostics" })
map("n", "]d", diagnostic_goto(true), { desc = "Next Diagnostic" })
map("n", "[d", diagnostic_goto(false), { desc = "Prev Diagnostic" })
map("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next Error" })
map("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev Error" })
map("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next Warning" })
map("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev Warning" })
-- commenting
map("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Below" })
map("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add Comment Above" })
-- formatting
-- TODO:
-- map({ "n", "x" }, "<leader>cf", function()
--   LazyVim.format({ force = true })
-- end, { desc = "Format" })
-- diagnostic

--
-- Quickfix list
--
map("n", "<leader>xq", function()
  local success, err = pcall(vim.fn.getqflist({ winid = 0 }).winid ~= 0 and vim.cmd.cclose or vim.cmd.copen)
  if not success and err then
    vim.notify(err, vim.log.levels.ERROR)
  end
end, { desc = "Quickfix List" })

map("n", "[q", vim.cmd.cprev, { desc = "Previous Quickfix" })
map("n", "]q", vim.cmd.cnext, { desc = "Next Quickfix" })
