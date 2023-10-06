local function find_associate_test_or_file()
  local default_text = ""
  local filename = vim.fn.expand("%:t"):match("(.+)%..+")
  if filename:sub(-#"_test") == "_test" then
    default_text = filename:gsub("_test", "") .. ".go"
  else
    default_text = filename .. "_test.go"
  end
  require("telescope.builtin").find_files({ default_text = default_text })
end

return {
  {
    "nvim-neotest/neotest",
    ft = { "go" },
    keys = {
      {
        "<M-S-F9>",
        function()
          require("neotest").run.run(vim.fn.expand("%"))
        end,
        desc = "Run File (Alt+Shift+F9)",
        noremap = true,
        silent = true,
      },
      {
        "<F21>",
        function()
          require("neotest").run.run()
        end,
        desc = "Run Nearest (F9)",
        noremap = true,
        silent = true,
      },
      {
        "<C-T>",
        find_associate_test_or_file,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
    },
  },
}
