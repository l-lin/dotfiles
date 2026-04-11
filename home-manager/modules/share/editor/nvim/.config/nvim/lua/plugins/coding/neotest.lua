---@type vim.pack.Spec
return
-- An extensible framework for interacting with tests within NeoVim.
{
  src = "nvim-neotest/neotest",
  data = {
    setup = function()
      vim.keymap.set("n", "<M-S-F9>", function()
        require("neotest").run.run(vim.fn.expand("%"))
      end, {
        desc = "Run File (Alt+Shift+F9)",
        noremap = true,
        silent = true,
      })
      vim.keymap.set("n", "<F21>", function()
        require("neotest").run.run()
      end, {
        desc = "Run Nearest (Shift+F9)",
        noremap = true,
        silent = true,
      })
    end,
  },
}
