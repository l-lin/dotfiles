vim.o.tabstop = 4
vim.o.shiftwidth = vim.o.tabstop

local kotlin = require("plugins.custom.lang.kotlin")

vim.keymap.set(
  "n",
  "<leader>ta",
  kotlin.execute_maven_tests,
  { buffer = true, desc = "Execute Maven tests in a new tmux pane below" }
)
