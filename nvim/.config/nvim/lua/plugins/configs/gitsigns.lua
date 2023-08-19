local M = {}

-- load gitsigns only when a git file is opened
M.init = function()
  vim.api.nvim_create_autocmd({ "BufRead" }, {
    group = vim.api.nvim_create_augroup("GitSignsLazyLoad", { clear = true }),
    callback = function()
      vim.fn.system("git -C " .. '"' .. vim.fn.expand "%:p:h" .. '"' .. " rev-parse")
      if vim.v.shell_error == 0 then
        vim.api.nvim_del_augroup_by_name "GitSignsLazyLoad"
        vim.schedule(function()
          require("lazy").load { plugins = { "gitsigns.nvim" } }
        end)
      end
    end,
  })
end

local function on_attach(bufnr)
  local gs = package.loaded.gitsigns
  local map = require("mapper").map
  local bufopts = { buffer = bufnr }

  -- Actions
  map({ "n", "v" }, "<leader>ga", "<cmd>Gitsigns stage_hunk<CR>", bufopts, "Gitsigns add/stage hunk")
  map({ "n", "v" }, "<leader>gr", "<cmd>Gitsigns reset_hunk<CR>", bufopts, "Gitsigns reset hunk (Ctrl+Alt+z)")
  map({ "n", "v" }, "<M-C-Z>", "<cmd>Gitsigns reset_hunk<CR>", bufopts, "Gitsigns reset hunk (Ctrl+Alt+z)")
  map("n", "<leader>gA", gs.stage_buffer, bufopts, "Gitsigns add/stage buffer")
  map("n", "<leader>gu", gs.undo_stage_hunk, bufopts, "Gitsigns undo add/stage hunk")
  map("n", "<leader>gR", gs.reset_buffer, bufopts, "Gitsigns reset buffer")
  map("n", "<leader>gv", gs.preview_hunk_inline, bufopts, "Gitsigns preview hunk (Ctrl+Alt+g)")
  map("n", "<M-C-G>", gs.preview_hunk_inline, bufopts, "Gitsigns preview hunk (Ctrl+Alt+g)")
  map("n", "<leader>gB", function() gs.blame_line { full = true } end, bufopts, "Gitsigns blame line")
  map("n", "<leader>gT", gs.toggle_current_line_blame, bufopts, "Gitsigns toggle current line blame")
  map("n", "<leader>gD", gs.diffthis, bufopts, "Gitsigns diff this")
  map("n", "<leader>gt", gs.toggle_deleted, bufopts, "Gitsigns toggle deleted")

  -- Text object
  map({ "o", "x" }, "ih", "<cmd><C-U>Gitsigns select_hunk<CR>", bufopts, "Gitsigns select hunk")
end

M.setup = function()
  require("gitsigns").setup({
    on_attach = on_attach
  })
end

return M
