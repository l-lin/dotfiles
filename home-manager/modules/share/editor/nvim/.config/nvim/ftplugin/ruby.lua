vim.keymap.set(
  "n",
  "<leader>fxr",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "ruby",
      use_interactive_shell = false,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Ruby" }
)
vim.keymap.set(
  "n",
  "<leader>ta",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Run all test (Alt+Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tA",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "HEADLESS=1 bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Run all test in HEADLESS mode" }
)
vim.keymap.set(
  "n",
  "<M-S-F9>",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Run all test (Alt+Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tn",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test (Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tN",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "HEADLESS=1 bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test in HEADLESS mode" }
)
vim.keymap.set(
  "n",
  "<F21>",
  function()
    require("helpers.lang.ruby").execute_file({
      cmd = "bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test (Shift+F9)" }
)
