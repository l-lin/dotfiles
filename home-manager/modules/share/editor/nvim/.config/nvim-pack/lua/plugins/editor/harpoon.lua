local function setup()
  require("harpoon"):setup({
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  })

  local map = vim.keymap.set
  map("n", "<leader>H", function()
    require("harpoon"):list():add()
  end, { desc = "Harpoon File" })
  map("n", "<leader>h", function()
    local harpoon = require("harpoon")
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end, { desc = "Harpoon Quick Menu" })

  for index = 1, 9 do
    map("n", "<leader>" .. index, function()
      require("harpoon"):list():select(index)
    end, { desc = "Harpoon to File " .. index })
  end
end

---@type vim.pack.Spec
return
-- Getting you where you want with the fewest keystrokes.
{
  src = "https://github.com/ThePrimeagen/harpoon",
  version = "harpoon2",
  data = {
    setup = function()
      vim.schedule(setup)
    end,
  },
}
