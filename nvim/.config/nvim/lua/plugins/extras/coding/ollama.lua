return {
  {
    "nomnivore/ollama.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = { "Ollama", "OllamaModel", "OllamaServe", "OllamaServeStop" },

    keys = {
      {
        "<leader>oo",
        ":<c-u>lua require('ollama').prompt()<cr>",
        desc = "Ollama prompt",
        mode = { "n", "v" },
      },
      -- default prompts: https://github.com/nomnivore/ollama.nvim/blob/main/lua/ollama/prompts.lua
      {
        "<leader>oa",
        ":<c-u>lua require('ollama').prompt('Ask_About_Code')<cr>",
        desc = "Ollama ask about code",
        mode = { "n", "v" },
      },
      {
        "<leader>oe",
        ":<c-u>lua require('ollama').prompt('Explain_Code')<cr>",
        desc = "Ollama explain code",
        mode = { "n", "v" },
      },
      {
        "<leader>og",
        ":<c-u>lua require('ollama').prompt('Generate_Code')<cr>",
        desc = "Ollama generate code",
        mode = { "n", "v" },
      },
      {
        "<leader>om",
        ":<c-u>lua require('ollama').prompt('Modify_Code')<cr>",
        desc = "Ollama modify code",
        mode = { "n", "v" },
      },
      { "<leader>os", "<cmd>OllamaServe<cr>", desc = "Ollama start server", mode = "n" },
      { "<leader>oS", "<cmd>OllamaServeStop<cr>", desc = "Ollama stop server", mode = "n" },
    },

    ---@type Ollama.Config
    opts = {
      model = "deepseek-coder",
      url = "http://127.0.0.1:11434",
      serve = {
        on_start = true,
        command = "docker",
        args = { "run", "-d", "--rm", "-v", "ollama:/root/.ollama", "-p", "11434:11434", "--name", "ollama", "ollama/ollama" },
        stop_command = "docker",
        stop_args = { "stop", "ollama" },
      },
    },
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      table.insert(opts.sections.lualine_x, {
        function()
          local status = require("ollama").status()

          if status == "IDLE" then
            return "󱙺" -- nf-md-robot-outline
          elseif status == "WORKING" then
            return "󰚩" -- nf-md-robot
          end
        end,
        cond = function()
          return package.loaded["ollama"] and require("ollama").status() ~= nil
        end,
      })
    end,
  },
}
