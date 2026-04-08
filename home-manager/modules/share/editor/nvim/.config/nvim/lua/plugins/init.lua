-- Build hooks must be registered before `vim.pack.add`.
-- src: https://echasnovski.com/blog/2026-03-13-a-guide-to-vim-pack#hooks
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "nvim-treesitter" and kind == "update" then
      if not ev.data.active then
        vim.cmd.packadd("nvim-treesitter")
      end
      vim.cmd("TSUpdate")
    end
  end,
})

local plugins = require("functions.pack").to_pack_specs({
  require("plugins.mini"),
  require("plugins.ui"),
  require("plugins.editor"),
  require("plugins.coding"),
  require("plugins.integration"),
  require("plugins.vcs"),
  require("plugins.lang"),
  require("plugins.format"),
  require("plugins.ai"),
})

vim.pack.add(plugins, {
  load = function(plugin)
    vim.cmd.packadd(plugin.spec.name)

    local data = plugin.spec.data or {}
    local setup = data.setup
    if setup ~= nil and type(setup) == "function" then
      setup()
    end
  end,
  confirm = false,
})
