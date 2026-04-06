local function setup()
  require("yanky").setup({
    highlight = { timer = 150 },
    system_clipboard = {
      sync_with_ring = false,
    },
  })

  vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)", { desc = "Yank Text" })
  vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)", { desc = "Put Text After Cursor" })
  vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)", { desc = "Put Text Before Cursor" })
  vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)", { desc = "Put Text After Selection" })
  vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)", { desc = "Put Text Before Selection" })
  vim.keymap.set("n", "[y", "<Plug>(YankyCycleForward)", { desc = "Cycle Forward Through Yank History" })
  vim.keymap.set("n", "]y", "<Plug>(YankyCycleBackward)", { desc = "Cycle Backward Through Yank History" })
  vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
  vim.keymap.set("n", "[p", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
  vim.keymap.set("n", "]P", "<Plug>(YankyPutIndentAfterLinewise)", { desc = "Put Indented After Cursor (Linewise)" })
  vim.keymap.set("n", "[P", "<Plug>(YankyPutIndentBeforeLinewise)", { desc = "Put Indented Before Cursor (Linewise)" })
  vim.keymap.set("n", ">p", "<Plug>(YankyPutIndentAfterShiftRight)", { desc = "Put and Indent Right" })
  vim.keymap.set("n", "<p", "<Plug>(YankyPutIndentAfterShiftLeft)", { desc = "Put and Indent Left" })
  vim.keymap.set("n", ">P", "<Plug>(YankyPutIndentBeforeShiftRight)", { desc = "Put Before and Indent Right" })
  vim.keymap.set("n", "<P", "<Plug>(YankyPutIndentBeforeShiftLeft)", { desc = "Put Before and Indent Left" })

  if package.loaded["snacks"] then
    vim.keymap.set({ "n", "x" }, "<leader>p", function()
      Snacks.picker.yanky()
    end, { desc = "Open Yank History" })
  end
end

---@type vim.pack.Spec
return
-- Improved Yank and Put functionalities for Neovim
{
  src = "https://github.com/gbprod/yanky.nvim",
  data = {
    setup = function()
      vim.schedule(setup)
    end,
  },
}
