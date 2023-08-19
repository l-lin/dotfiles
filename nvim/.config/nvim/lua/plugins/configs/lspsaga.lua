local M = {}

local function change_highlight()
  vim.api.nvim_set_hl(0, "HoverNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "HoverBorder", { bg = "none" })
  vim.api.nvim_set_hl(0, "SagaNormal", { bg = "none" })
  vim.api.nvim_set_hl(0, "SagaBorder", { bg = "none" })
end

M.setup = function()
  require("lspsaga").setup({
    callhierarchy = {
      layout = "normal",
      keys = {
        shuttle = { "<C-l>", "<C-h>" },
        toggle_or_req = { "o", "<cr>" },
        vsplit = "<C-v>",
        split = "<C-x>",
      },
    },
    finder = {
      layout = "normal",
      left_width = 0.4,
      keys = {
        shuttle = { "<C-l>", "<C-h>" },
        toggle_or_open = { "o", "<cr>" },
        vsplit = "<C-v>",
        split = "<C-x>",
      },
    },
    lightbulb = {
      sign = false,
    },
    rename = {
      in_select = false,
      auto_save = true,
      project_max_width = 0.8,
      project_max_height = 0.5,
    },
    ui = {
      border = "rounded",
    },
    symbol_in_winbar = {
      enable = false,
    },
  })
  change_highlight()
end

return M
