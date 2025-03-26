local ruby = require("plugins.custom.lang.ruby")

vim.keymap.set(
  "n",
  "<leader>er",
  function()
    ruby.execute_file({
      cmd = "ruby",
      is_interactive = false,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Ruby" }
)
vim.keymap.set(
  "n",
  "<leader>ta",
  function()
    ruby.execute_file({
      cmd = "rails t",
      is_interactive = true,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Run all test" }
)
vim.keymap.set(
  "n",
  "<leader>tn",
  function()
    ruby.execute_file({
      cmd = "rails t",
      is_interactive = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test (Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<F21>",
  function()
    ruby.execute_file({
      cmd = "rails t",
      is_interactive = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test (Shift+F9)" }
)
