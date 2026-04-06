local plugins = require("functions.pack").to_pack_specs({
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
