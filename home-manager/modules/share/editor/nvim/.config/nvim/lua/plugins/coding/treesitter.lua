local parsers = {
  "bash",
  "css",
  "diff",
  "editorconfig",
  "fish",
  "go",
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

  vim.keymap.set({ "n", "x", "o" }, "]f", function()
    require("nvim-treesitter-textobjects.move").goto_next_start("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next function start" })
  vim.keymap.set({ "n", "x", "o" }, "[f", function()
    require("nvim-treesitter-textobjects.move").goto_previous_start("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous function start" })
  vim.keymap.set({ "n", "x", "o" }, "]F", function()
    require("nvim-treesitter-textobjects.move").goto_next_end("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next function end" })
  vim.keymap.set({ "n", "x", "o" }, "[F", function()
    require("nvim-treesitter-textobjects.move").goto_previous_end("@function.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous function end" })
  vim.keymap.set({ "n", "x", "o" }, "]c", function()
    require("nvim-treesitter-textobjects.move").goto_next_start("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next class start" })
  vim.keymap.set({ "n", "x", "o" }, "[c", function()
    require("nvim-treesitter-textobjects.move").goto_previous_start("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous class start" })
  vim.keymap.set({ "n", "x", "o" }, "]C", function()
    require("nvim-treesitter-textobjects.move").goto_next_end("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "next class end" })
  vim.keymap.set({ "n", "x", "o" }, "[C", function()
    require("nvim-treesitter-textobjects.move").goto_previous_end("@class.outer", "textobjects")
    vim.api.nvim_command("norm! zz")
  end, { desc = "previous class end" })
  vim.keymap.set({ "n", "x" }, "gC", function()
    require("treesitter-context").go_to_context()
    vim.api.nvim_command("norm! zt")
  end, { desc = "go to context" })

  -- Fold based on treesitter.
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
  -- Indent based on treesitter
  vim.bo.indentexpr = "v:lua.vim.treesitter.indentexpr()"

  -- Auto-start treesitter
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "*" },
    callback = function()
      local filetype = vim.bo.filetype
      if filetype and filetype ~= "" then
        local success = pcall(function()
          vim.treesitter.start()
        end)
        if not success then
          return
        end
      end
    end,
  })
end

---@type vim.pack.Spec[]
return {
  -- Nvim Treesitter configurations and abstraction layer.
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter",
  },
  -- Syntax aware text-objects, select, move, swap, and peek support.
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-textobjects",
  },
  -- Show code context.
  {
    src = "https://github.com/nvim-treesitter/nvim-treesitter-context",
    data = { setup = setup },
  },
}
