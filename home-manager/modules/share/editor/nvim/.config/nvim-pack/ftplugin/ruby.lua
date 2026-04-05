if vim.fn.executable("ruby-lsp") == 1 then
  vim.lsp.enable("ruby_lsp")
end

if vim.fn.executable("rubocop") == 1 then
  vim.lsp.enable("rubocop")
end

local fuzzy_ls_path = vim.fn.expand(vim.fn.stdpath("data") .. "/site/pack/core/opt/fuzzy_ruby_server/bin/fuzzy_darwin-arm64")
if vim.fn.filereadable(fuzzy_ls_path) == 1 then
  vim.lsp.enable("fuzzy_ls")
end

vim.keymap.set(
  "n",
  "<leader>fxr",
  function()
    require("functions.lang.ruby").execute_file({
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
    require("functions.lang.ruby").execute_file({
      cmd = "HEADLESS=1 bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Run all test in HEADLESS mode (Alt+Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tA",
  function()
    require("functions.lang.ruby").execute_file({
      cmd = "bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = false,
    })
  end,
  { buffer = true, desc = "Run all test" }
)
vim.keymap.set(
  "n",
  "<M-S-F9>",
  function()
    require("functions.lang.ruby").execute_file({
      cmd = "HEADLESS=1 bundle exec rails t",
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
    require("functions.lang.ruby").execute_file({
      cmd = "HEADLESS=1 bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test in HEADLESS mode (Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tN",
  function()
    require("functions.lang.ruby").execute_file({
      cmd = "bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test" }
)
vim.keymap.set(
  "n",
  "<F21>",
  function()
    require("functions.lang.ruby").execute_file({
      cmd = "HEADLESS=1 bundle exec rails t",
      use_interactive_shell = true,
      include_line_number = true,
    })
  end,
  { buffer = true, desc = "Run nearest test (Shift+F9)" }
)
vim.keymap.set(
  "n",
  "<leader>tr",
  function()
    require("functions.lang.ruby").rerun_last()
  end,
  { buffer = true, desc = "Re-run last test/command" }
)
