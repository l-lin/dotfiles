vim.keymap.set(
  "n",
  "<leader>fxx",
  function()
    require("functions.lang.zig").execute_file("zig run")
  end,
  { buffer = true, desc = "Execute Zig file" }
)
vim.keymap.set(
  "n",
  "<leader>ta",
  function()
    require("functions.lang.zig").execute_file("zig test")
  end,
  { buffer = true, desc = "Run all test in (Alt+Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<M-S-F9>",
  function()
    require("functions.lang.zig").execute_file("zig test")
  end,
  { buffer = true, desc = "Run all test (Alt+Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tr",
  function()
    require("functions.lang.zig").rerun_last()
  end,
  { buffer = true, desc = "Re-run last test/command" }
)
