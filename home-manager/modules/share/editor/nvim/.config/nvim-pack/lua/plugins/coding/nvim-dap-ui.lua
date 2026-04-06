local function setup()
  require("dapui").setup({
    layouts = {
      {
        elements = {
          { id = "scopes", size = 0.25 },
          { id = "breakpoints", size = 0.25 },
          { id = "stacks", size = 0.25 },
          { id = "watches", size = 0.25 },
        },
        position = "left",
        size = 40,
      },
      {
        elements = {
          { id = "repl", size = 1 },
        },
        position = "bottom",
        size = 15,
      },
      {
        elements = {
          { id = "console", size = 1 },
        },
        position = "bottom",
        size = 15,
      },
    },
    mappings = {
      edit = "e",
      expand = { "<CR>", "l", "h" },
      open = "o",
      remove = "d",
      repl = "r",
      toggle = "t",
    },
  })

  local map = vim.keymap.set
  map("n", "<M-C-\\>", function()
    require("dapui").toggle({ layout = 2, reset = true })
  end, { desc = "Open DAP UI REPL (Ctrl+Alt+4)" })
  map("n", "<M-4>", function()
    require("dapui").toggle({ layout = 3, reset = true })
  end, { desc = "Open DAP UI Console (Alt+4)" })
  map("n", "<M-5>", function()
    require("dapui").toggle({ reset = true })
  end, { desc = "Open DAP UI (Alt+5)" })
  map("n", "<leader>du", function()
    require("dapui").toggle({ reset = true })
  end, { desc = "Open DAP UI (Alt+5)" })
  map({ "n", "v" }, "<M-BS>", function()
    require("dapui").eval()
  end, { desc = "Eval (Ctrl+Alt+8)" })
end

---@type vim.pack.Spec[]
return {
  {
    src = "https://github.com/nvim-neotest/nvim-nio",
  },
  {
    src = "https://github.com/rcarriga/nvim-dap-ui",
    data = { setup = setup },
  },
}
