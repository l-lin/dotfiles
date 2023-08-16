local M = {}

M.attach_keymap = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }
  map({ "v", "n" }, "<M-CR>", require("actions-preview").code_actions, bufopts, "Code action with preview (Alt+Enter)")
end

M.setup = function()
  local config = {
    telescope = {
      sorting_strategy = "ascending",
      layout_strategy = "vertical",
      layout_config = {
        width = 0.8,
        height = 0.9,
        prompt_position = "top",
        preview_cutoff = 15,
        preview_height = function(_, _, max_lines)
          return max_lines - 10
        end,
      },
    },
  }
  require("actions-preview").setup(config)

  M.attach_keymap()
end

return M
