return {
  {
    "rebelot/kanagawa.nvim",
    opts = {
      colors = {
        theme = {
          all = {
            ui = {
              bg_gutter = "none",
            },
          },
        },
      },
    },
  },
  {
    "sainnhe/gruvbox-material",
    enabled = false,
    config = function()
      vim.g.gruvbox_material_background = "medium" -- hard, soft, medium
      vim.g.gruvbox_material_foreground = "material" -- original, mix, material
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_sign_column_background = "none"

      vim.cmd([[ colorscheme gruvbox-material ]])
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa",
      defaults = {
        -- disable default keymaps as the window navigation overrides Navigator plugin's one
        keymaps = false,
      },
    },
  },
}
