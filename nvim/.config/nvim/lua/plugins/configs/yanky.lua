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

M.setup = function()
  require("yanky").setup({
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
          default = require("yanky.telescope.mapping").put("p")
        }
      }
    }
  })

  override_yank_with_xsel()
end

return M
