-- Navigate and manipulate file system.
vim.pack.add({ "https://github.com/nvim-mini/mini.files" })

--
-- Setup
--
require("mini.files").setup({
  windows = {
    preview = true,
    width_focus = 50,
    width_preview = 100,
  },
  options = {
    -- Whether to use for editing directories.
    use_as_default_explorer = true,
  },
  mappings = {
    go_in = "",
    go_out = "",
    synchronize = "<C-s>",
  },
})

--
-- Keymaps
--
vim.keymap.set("n", "<M-1>", function()
  local path = vim.api.nvim_buf_get_name(0)
  -- If already in minifiles, then go directly to root directory
  if path:match("^minifiles://") then
    require("mini.files").open(vim.uv.cwd(), true)
  else
    require("mini.files").open(path, true)
  end
end, {
  desc = "Open mini.files (directory of current file) (Alt+1)",
  noremap = true,
})

vim.keymap.set("n", "<leader>fh", function()
  local relative_filepath = vim.fn.expand("%:.")
  local _, extension = relative_filepath:match("(.+)%.(.+)$")

  if extension == "rb" then
    local parts = vim.fn.split(relative_filepath, "/")
    if #parts > 2 and parts[1] == "engines" then
      return "engines/" .. parts[2]
    end
  end

  if extension == "java" then
    local filepath = vim.fn.expand("%:.")
    local dir = vim.fn.fnamemodify(filepath, ":h")
    while dir ~= "/" do
      local pom_file = dir .. "/pom.xml"
      if vim.fn.filereadable(pom_file) == 1 then
        return dir
      end
      dir = vim.fn.fnamemodify(dir, ":h")
    end
  end

  local sub_module = vim.api.nvim_buf_get_name(0)
  require("mini.files").open(sub_module, true)
end, {
  desc = "Open mini.files in current sub-module/sub-project",
  remap = true,
})
