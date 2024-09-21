local function find_associate_test_or_file()
  local default_text = ""
  local filename = vim.fn.expand("%:t")
  local name, extension = filename:match("(.+)%.(.+)")
  if name:sub(-#"_test") == "_test" then
    default_text = name:gsub("_test", "") .. "." .. extension
  else
    default_text = name .. "_test." .. extension
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
}
