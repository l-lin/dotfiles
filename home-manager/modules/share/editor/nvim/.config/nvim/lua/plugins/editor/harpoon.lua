local function setup()
  require("harpoon"):setup({
    menu = {
      width = vim.api.nvim_win_get_width(0) - 4,
    },
    settings = {
      save_on_toggle = true,
    },
  })

  vim.keymap.set("n", "<leader>H", function()
    require("harpoon"):list():add()
  end, { desc = "Harpoon File" })
  vim.keymap.set("n", "<leader>h", function()
    local harpoon = require("harpoon")
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end, { desc = "Harpoon Quick Menu" })

  for index = 1, 9 do
    vim.keymap.set("n", "<leader>" .. index, function()
      require("harpoon"):list():select(index)
    end, { desc = "Harpoon to File " .. index })
  end
end

---@type vim.pack.Spec[]
return {
  -- plenary: full; complete; entire; absolute; unqualified. All the lua functions I don't want to write twice.
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
  },
  -- Getting you where you want with the fewest keystrokes.
  {
    src = "https://github.com/ThePrimeagen/harpoon",
    version = "harpoon2",
    data = {
      setup = function()
        vim.schedule(setup)
      end,
    },
  },
}
