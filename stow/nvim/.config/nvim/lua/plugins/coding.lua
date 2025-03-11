local function find_sub_module()
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
        return vim.fn.fnamemodify(dir, ":t")
      end
      dir = vim.fn.fnamemodify(dir, ":h")
    end
  end

  return vim.api.nvim_buf_get_name(0)
end

return {
  -- #######################
  -- override default config
  -- #######################

  -- autocompletion engine
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "enter",
        ['<C-e>'] = { 'select_and_accept' },
      },
    },
  },

  -- autopairs - not quite as good as nvim-autopairs
  { "echasnovski/mini.pairs", enabled = false },

  -- Navigate and manipulate file system.
  {
    "echasnovski/mini.files",
    optional = true,
    keys = {
      {
        "<leader>fh",
        function()
          require("mini.files").open(find_sub_module(), true)
        end,
        desc = "Open mini.files in current sub-module/sub-project",
        remap = true,
      },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- autopairs - better than mini.pairs in my taste
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {},
  },
}
