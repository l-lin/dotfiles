return {
  -- #######################
  -- override default config
  -- #######################

  -- debugger engine
  {
    "mfussenegger/nvim-dap",
    keys = {
      {
        "<F9>",
        function()
          require("dap").continue()
        end,
        noremap = true,
        silent = true,
        desc = "Begin debug session (F9)",
      },
      {
        "<F32>",
        function()
          require("dap").toggle_breakpoint()
        end,
        noremap = true,
        silent = true,
        desc = "Toggle breakpoint (Ctrl+F8)",
      },
      {
        "<F8>",
        function()
          require("dap").step_over()
        end,
        noremap = true,
        silent = true,
        desc = "Step over (F8)",
      },
      {
        "<F7>",
        function()
          require("dap").step_into()
        end,
        noremap = true,
        silent = true,
        desc = "Step into (F7)",
      },
      {
        "<F20>",
        function()
          require("dap").step_out()
        end,
        noremap = true,
        silent = true,
        desc = "Step out (Shift+F8)",
      },
      {
        "<F26>",
        function()
          require("dap").terminate()
        end,
        desc = "Terminate DAP (Ctrl+F2)",
      },
    },
  },

  -- dap UI
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "nvim-neotest/nvim-nio"
    },
    keys = {
      {
        "<M-C-\\>",
        function()
          require("dapui").toggle({ layout = 2, reset = true })
        end,
        desc = "Open DAP UI REPL (Ctrl+Alt+4)",
      },
      {
        "<M-4>",
        function()
          require("dapui").toggle({ layout = 3, reset = true })
        end,
        desc = "Open DAP UI Console (Alt+4)",
      },
      {
        "<M-5>",
        function()
          require("dapui").toggle({ reset = true })
        end,
        desc = "Open DAP UI (Alt+5)",
      },
      {
        "<leader>du",
        function()
          require("dapui").toggle({ reset = true })
        end,
        desc = "Open DAP UI (Alt+5)",
      },
      {
        "<M-BS>",
        function()
          require("dapui").eval()
        end,
        desc = "Eval (Ctrl+Alt+8)",
        mode = { "n", "v" },
      },
    },
    opts = {
      layouts = {
        {
          elements = {
            { id = "scopes", size = 0.25 },
            { id = "breakpoints", size = 0.25 },
            { id = "stacks", size = 0.25 },
            { id = "watches", size = 0.25 },
          },
          size = 40,
          position = "left",
        },
        {
          elements = {
            { id = "repl", size = 1 },
          },
          size = 15,
          position = "bottom",
        },
        {
          elements = {
            { id = "console", size = 1 },
          },
          size = 15,
          position = "bottom",
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
