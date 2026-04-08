--
-- Icon provider.
--
local function setup_icon()
  require("mini.icons").setup()

  -- Mock nvim-web-devicons to avoid loading it as a dependency,
  -- since it's only used for icons in the statusline and file explorer.
  package.preload["nvim-web-devicons"] = function()
    require("mini.icons").mock_nvim_web_devicons()
    return package.loaded["nvim-web-devicons"]
  end
end

--
-- Navigate and manipulate file system.
--
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
        return dir
      end
      dir = vim.fn.fnamemodify(dir, ":h")
    end
  end

  return vim.api.nvim_buf_get_name(0)
end

local function setup_files()
  require("mini.files").setup({
    windows = {
      preview = true,
      width_focus = 50,
      width_preview = 100,
    },
    options = {
      use_as_default_explorer = true,
    },
    mappings = {
      go_in = "",
      go_out = "",
      synchronize = "<C-s>",
    },
  })

  vim.keymap.set("n", "<M-1>", function()
    local path = vim.api.nvim_buf_get_name(0)
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
    require("mini.files").open(find_sub_module(), true)
  end, {
    desc = "Open mini.files in current sub-module/sub-project",
    remap = true,
  })
end

--
-- Neovim Lua plugin with fast and feature-rich surround actions.
--
local function setup_surround()
  vim.schedule(function()
    require("mini.surround").setup({
      mappings = {
        add = "sa",
        delete = "sd",
        find = "sf",
        find_left = "sF",
        highlight = "sh",
        replace = "sr",
        update_n_lines = "sn",
      },
    })
  end)
end

--
-- Neovim Lua plugin to extend and create `a`/`i` textobjects.
--
local function setup_ai()
  require("mini.ai").setup()
end

--
-- Minimal and fast pairs
local function setup_pairs()
  require("mini.pairs").setup()
end

---@type vim.pack.Spec[]
return {
  {
    src = "https://github.com/nvim-mini/mini.nvim",
    data = {
      setup = function()
        setup_icon()
        vim.schedule(function()
          setup_files()
          setup_surround()
          setup_ai()
          setup_pairs()
        end)
      end,
    },
  },
}
