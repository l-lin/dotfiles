local M = {}

local function goto_prev_error()
  require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
end

local function goto_next_error()
  require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
end

M.attach_keymaps = function(_, bufnr)
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true, buffer = bufnr }

  -- diagnostic
  map("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<cr>", bufopts, "Lspsaga diagnostic go to next (F2)")
  map("n", "<F2>", "<cmd>Lspsaga diagnostic_jump_next<cr>", bufopts, "Lspsaga diagnostic go to next (F2)")
  map("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<cr>", bufopts, "Lspsaga diagnostic go to previous (Shift+F2)")
  map("n", "<F14>", "<cmd>Lspsaga diagnostic_jump_prev<cr>", bufopts, "Lspsaga diagnostic go to previous (Shift+F2)")
  map("n", "[E", goto_prev_error, bufopts, "Lspsaga diagnostic go to previous ERROR")
  map("n", "]E", goto_next_error, bufopts, "Lspsaga diagnostic go to next ERROR")
  map("n", "<leader>ce", "<cmd>Lspsaga show_line_diagnostics<cr>", bufopts, "Lspsaga diagnostic show message (Ctrl+F1)")
  map("n", "<F25>", "<cmd>Lspsaga show_line_diagnostics<cr>", bufopts, "Lspsaga diagnostic show message (Ctrl+F1)")

  map("n", "<leader>ch", "<cmd>Lspsaga hover_doc<cr>", bufopts, "LSP show hovering help (Shift+k)")
  map("n", "<S-k>", "<cmd>Lspsaga hover_doc<cr>", bufopts, "LSP show hovering help (Shift+k)")
  map("n", "<leader>cc", "<cmd>Lspsaga finder<cr>", bufopts, "Lspsaga definition and usage finder")
  -- map("n", "<leader>cd", "<cmd>Lspsaga goto_definition<cr>", bufopts, "Lspsaga go to definition (Ctrl+b)")
  -- map("n", "<C-b>", "<cmd>Lspsaga goto_definition<cr>", bufopts, "Lspsaga go to definition (Ctrl+b)")
  map("n", "<leader>cD", "<cmd>Lspsaga peek_definition<cr>", bufopts, "Lspsaga peek definition")
  map("n", "<leader>ct", "<cmd>Lspsaga goto_type_definition<cr>", bufopts, "Lspsaga goto type definition")
  map("n", "<leader>cT", "<cmd>Lspsaga peek_type_definition<cr>", bufopts, "Lspsaga peek type definition")
  map("n", "<leader>ci", "<cmd>Lspsaga incoming_calls<cr>", bufopts, "Lspsaga incoming calls")
  map("n", "<leader>co", "<cmd>Lspsaga outgoing_calls<cr>", bufopts, "Lspsaga outgoing calls")
  map("n", "<leader>cm", "<cmd>Lspsaga outline<cr>", bufopts, "Lspsaga outline minimap")
  map("n", "<leader>cr", "<cmd>Lspsaga rename ++project<cr>", bufopts, "Lspsaga rename")
  map("n", "<F18>", "<cmd>Lspsaga rename ++project<cr>", bufopts, "Lspsaga rename (Shift+F6)")
  map("n", "<leader>cE", "<cmd>Lspsaga show_buf_diagnostics<cr>", bufopts, "LSP show errors")
  -- map("n", "<leader>ca", "<cmd>Lspsaga code_action<cr>", bufopts, "LSP code action" )
  -- map("n", "<M-cr>", "<cmd>Lspsaga code_action<cr>", bufopts, "LSP code action (Ctrl+Enter)" )
end

M.change_highlight = function()
  local bg = require("appearance").get_background_color()
  vim.api.nvim_set_hl(0, "HoverNormal", { bg = bg })
  vim.api.nvim_set_hl(0, "HoverBorder", { bg = bg })
  vim.api.nvim_set_hl(0, "SagaNormal", { bg = bg })
  vim.api.nvim_set_hl(0, "SagaBorder", { bg = bg })
end

M.attach = function()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(args)
      local bufnr = args.buf
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      M.attach_keymaps(client, bufnr)
      M.change_highlight()
    end,
  })
end

M.config = function()
  return {
    lightbulb = {
      sign = false,
    },
    ui = {
      border = "rounded",
    },
  }
end

M.setup = function()
  require("lspsaga").setup(M.config())
  M.attach()
end

return M
