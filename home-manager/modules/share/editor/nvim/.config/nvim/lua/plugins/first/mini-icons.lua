local function setup_icon()
  require("mini.icons").setup()

  -- Mock nvim-web-devicons to avoid loading it as a dependency,
  -- since it's only used for icons in the statusline and file explorer.
  local package_name = "nvim-web-devicons"
  package.preload[package_name] = function()
    require("mini.icons").mock_nvim_web_devicons()
    return package.loaded[package_name]
  end
end

---@type vim.pack.Spec
return
-- Icon provider.
{
  src = "https://github.com/nvim-mini/mini.icons",
  data = { setup = setup_icon },
}
