local function setup()
  require("gitsigns").setup({
    preview_config = {
      border = "rounded",
    },
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
      untracked = { text = "▎" },
    },
    signs_staged = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
  })
end

---@param map fun(mode: string|string[], lhs: string, rhs: string|function, opts?: table)
local function keymaps(map)
  map("n", "<M-C-G>", "<cmd>Gitsigns preview_hunk_inline<cr>", { desc = "Preview Hunk inline (Ctrl+Alt+g)" })
  map({ "n", "v" }, "<M-C-Z>", "<cmd>Gitsigns reset_hunk<cr>", { desc = "Reset hunk (Ctrl+Alt+z)" })
  map("n", "]h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "]c", bang = true })
    else
      require("gitsigns").nav_hunk("next")
    end
  end, { desc = "Next Hunk" })
  map("n", "[h", function()
    if vim.wo.diff then
      vim.cmd.normal({ "[c", bang = true })
    else
      require("gitsigns").nav_hunk("prev")
    end
  end, { desc = "Prev Hunk" })
end

---@type vim.pack.Spec
return {
  src = "https://github.com/lewis6991/gitsigns.nvim",
  data = {
    setup = setup,
    keymaps = keymaps,
  },
}
