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

---@type vim.pack.Spec
return
--
-- Neovim Lua plugin with fast and feature-rich surround actions.
--
{
  src = "https://github.com/nvim-mini/mini.surround",
  data = {
    setup = function()
      vim.schedule(setup_surround)
    end,
  },
}
