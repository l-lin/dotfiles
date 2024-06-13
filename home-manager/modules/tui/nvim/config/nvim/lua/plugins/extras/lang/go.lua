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
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<C-T>",
        find_associate_test_or_file,
        desc = "Find associated test file (Ctrl+t)",
        noremap = true,
        silent = true,
      },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    ft = { "go" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      {
        "nvim-telescope/telescope.nvim",
        optional = true,
        opts = function()
          require("lazyvim.util").on_load("telescope.nvim", function()
            require("telescope").load_extension("refactoring")
          end)
        end,
      },
    },
    keys = {
      {
        "<M-C-V>",
        "<cmd>Refactor extract_var<cr>",
        noremap = true,
        silent = true,
        desc = "Extract variable",
        mode = { "n", "x" },
      },
      {
        "<M-C-N>",
        "<cmd>Refactor extract<cr>",
        noremap = true,
        silent = true,
        desc = "Extract function",
        mode = { "n", "x" },
      },
    },
    opts = {
      prompt_func_return_type = {
        go = true,
      },
      prompt_func_param_type = {
        go = true,
      },
    },
  },
}
