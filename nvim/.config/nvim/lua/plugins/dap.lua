return {
  -- debugger engine
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<F9>",
        "<Cmd>lua require('dap').continue()<cr>",
        noremap = true,
        silent = true,
        desc = "Begin debug session (F9)",
      },
      {
        "<F32>",
        "<Cmd>lua require('dap').toggle_breakpoint()<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle breakpoint (Ctrl+F8)",
      },
      {
        "<F8>",
        "<Cmd>lua require('dap').step_over()<cr>",
        noremap = true,
        silent = true,
        desc = "Step over (F8)",
      },
      {
        "<F7>",
        "<Cmd>lua require('dap').step_into()<cr>",
        noremap = true,
        silent = true,
        desc = "Step into (F7)",
      },
      {
        "<F20>",
        "<Cmd>lua require('dap').step_out()<cr>",
        noremap = true,
        silent = true,
        desc = "Step out (Shift+F8)",
      },
    },
  },

  -- dap UI
  {
    "rcarriga/nvim-dap-ui",
    keys = {
      {
        "<M-3>",
        "<cmd>lua require('dapui').toggle({ layout = 2 })<cr>",
        desc = "Open DAP UI Console (Alt+4)",
      },
      {
        "<M-4>",
        "<cmd>lua require('dapui').toggle({ layout = 2, reset = true })<cr>",
        desc = "Open DAP UI Console (Alt+4)",
      },
      {
        "<M-5>",
        "<cmd>lua require('dapui').toggle({ reset = true })<cr>",
        desc = "Open DAP UI (Alt+5)",
      },
      {
        "<leader>du",
        "<cmd>lua require('dapui').toggle({ reset = true })<cr>",
        desc = "Open DAP UI (Alt+3)",
      },
    },
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes",      size = 0.25 },
            { id = "breakpoints", size = 0.25 },
            { id = "stacks",      size = 0.25 },
            { id = "watches",     size = 0.25 },
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl",    size = 0.25 },
            { id = "console", size = 0.75 },
          },
          size = 15,
          position = "bottom",
        },
      },
    },
    config = function(_, opts)
      local dapui = require("dapui")
      dapui.setup(opts)

      -- local dap = require("dap")
      -- NOTE: no need to open DAP UI when launching DAP
      -- dap.listeners.after.event_initialized["dapui_config"] = function()
      --   dapui.open({})
      -- end
      -- NOTE: no need to close DAP config when finished
      -- dap.listeners.before.event_terminated["dapui_config"] = function()
      --   dapui.close({})
      -- end
      -- dap.listeners.before.event_exited["dapui_config"] = function()
      --   dapui.close({})
      -- end
    end,
  },

	-- fuzzy finding anything anywhere
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>dd",
        "<cmd>Telescope dap configurations<cr>",
        noremap = true,
        silent = true,
        desc = "Telescope DAP configuration (Alt+Shift+F10)",
      },
      {
        "<M-S-F10>",
        "<cmd>Telescope dap configurations<cr>",
        noremap = true,
        silent = true,
        desc = "Telescope DAP configuration (Alt+Shift+F10)",
      },
    },
    dependencies = {
      "nvim-telescope/telescope-dap.nvim",
      config = function()
        require("telescope").load_extension("dap")
      end,
    },
  },
}
