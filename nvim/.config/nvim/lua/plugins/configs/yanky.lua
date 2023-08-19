local M = {}

-- override yank using xsel instead of xclip
-- see https://github.com/gbprod/yanky.nvim/issues/46
local function override_yank_with_xsel()
  vim.g.clipboard = {
    name = "xsel_override",
    copy = {
      ["+"] = "xsel --input --clipboard",
      ["*"] = "xsel --input --primary",
    },
    paste = {
      ["+"] = "xsel --output --clipboard",
      ["*"] = "xsel --output --primary",
    },
    cache_enabled = 1,
  }
end

M.attach_keymaps = function()
  local map = vim.keymap.set
  map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
  map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
  map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
  map({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
  map({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
  map("n", "<c-n>", "<Plug>(YankyCycleForward)")
  map("n", "<c-p>", "<Plug>(YankyCycleBackward)")
end

M.setup = function()
  local mapping = require("yanky.telescope.mapping")
  local config = {
    ring = {
      history_length = 10
    },
    highlight = {
      timer = 300,
    },
    picker = {
      telescope = {
        use_default_mappings = false,
        mappings = {
          default = mapping.put("p")
        }
      }
    }
  }

  require("yanky").setup(config)

  override_yank_with_xsel()

  M.attach_keymaps()
end

return M
