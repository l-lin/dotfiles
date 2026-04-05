local plugins = require("functions.pack").to_pack_specs({
  require("plugins.ui"),
  require("plugins.editor"),
})

vim.pack.add(plugins, {
  load = function(plugin)
    vim.cmd.packadd(plugin.spec.name)

    local data = plugin.spec.data or {}
    local setup = data.setup
    if setup ~= nil and type(setup) == "function" then
      setup()
    end
    local keymaps = data.keymaps
    if keymaps ~= nil and type(keymaps) == "function" then
      keymaps(vim.keymap.set)
    end
    local autocmds = data.autocmds
    if autocmds ~= nil and type(autocmds) == "function" then
      autocmds(vim.api.nvim_create_autocmd)
    end
  end,
  confirm = false,
})
