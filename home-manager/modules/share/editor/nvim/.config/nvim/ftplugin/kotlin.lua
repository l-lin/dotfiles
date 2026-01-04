vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

-- Maven error format. If you use another build tool like Gradle, create a function that returns the errorformat depending on the project.
vim.opt_local.errorformat = { "[ERROR] file://%f:%l:%v %m", "[WARNING] file://%f:%l:%v %m" }
-- Set :make command to compile the project.
-- Use `sort -u` to ensure no duplicates in qflist.
vim.opt_local.makeprg = "mvn-compile"

vim.keymap.set(
  "n",
  "<leader>ta",
  require("helpers.lang.kotlin").execute_all_tests_with_maven,
  { buffer = true, desc = "Execute Maven tests in a new tmux pane below" }
)
vim.keymap.set(
  "n",
  "<leader>tn",
  require("helpers.lang.kotlin").execute_nearest_test_with_maven,
  { buffer = true, desc = "Execute nearest Maven test in a new tmux pane below" }
)
vim.keymap.set("n", "<F33>", require("helpers.async").make, { silent = true, noremap = true, desc = "Compile (Ctrl+F9)" })
