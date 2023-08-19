local M = {}

local function attach()
  vim.api.nvim_create_autocmd("InsertLeave", {
    callback = function()
      if
          require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
          and not require("luasnip").session.jump_active
      then
        require("luasnip").unlink_current()
      end
    end,
  })
end

M.setup = function()
  require("luasnip").config.set_config({
    history = true,
    updateevents = "TextChanged,TextChangedI",
  })
  require("luasnip.loaders.from_snipmate").lazy_load()
  require("luasnip.loaders.from_vscode").lazy_load()
  require("luasnip.loaders.from_lua").lazy_load()

  attach()
end

return M
