local parsers = {
  "bash",
  "css",
  "diff",
  "editorconfig",
  "fish",
  "git_config",
  "git_rebase",
  "gitattributes",
  "gitcommit",
  "gitignore",
  "hcl",
  "html",
  "java",
  "javascript",
  "jsdoc",
  "json",
  "json5",
  "kotlin",
  "latex",
  "lua",
  "make",
  "markdown",
  "markdown_inline",
  "nix",
  "python",
  "query",
  "regex",
  "ruby",
  "toml",
  "tsx",
  "typescript",
  "typst",
  "vim",
  "vimdoc",
  "xml",
  "yaml",
  "yang",
}

local function setup()
  require("nvim-treesitter").setup({
    install_dir = vim.fn.stdpath("data") .. "/site",
  })
  require("nvim-treesitter-textobjects").setup({ move = { set_jumps = true } })
  require("treesitter-context").setup({
    max_lines = 3,
    min_window_height = 20,
    multiline_threshold = 5,
  })

  vim.schedule(function()
    require("nvim-treesitter").install(parsers)
  end)

  local map = vim.keymap.set
  map({ "n", "x", "o" }, "]f", function()
    require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next function start" })
  map({ "n", "x", "o" }, "[f", function()
    require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous function start" })
  map({ "n", "x", "o" }, "]F", function()
    require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next function end" })
  map({ "n", "x", "o" }, "[F", function()
    require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous function end" })
  map({ "n", "x", "o" }, "]c", function()
    require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next class start" })
  map({ "n", "x", "o" }, "[c", function()
    require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous class start" })
  map({ "n", "x", "o" }, "]C", function()
    require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next class end" })
  map({ "n", "x", "o" }, "[C", function()
    require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous class end" })
  map("n", "gC", function()
    require("treesitter-context").go_to_context()
    vim.api.nvim_command("norm! zt")
  end, { desc = "go to context" })
end

---@type vim.pack.Spec[]
return {
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  },
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-context",
    data = { setup = setup },
  },
}
