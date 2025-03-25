---Execute file on a tmux pane on the right.
---@param cmd string the command to use, e.g. "ruby", "rails t"
---@param is_interactive boolean true if the file must be executed in interactive bash mode
local function execute_file(cmd, is_interactive)
  local filename = vim.fn.expand("%:.")
  if string.match(filename, "%.rb$") then
    local command_to_run = cmd .. " " .. filename

    local bash_additional_flags = ""
    if is_interactive then
      bash_additional_flags = "-i "
    end

    -- `-l 60` specifies the size of the tmux pane, in this case 60 columns
    vim.cmd("silent !tmux split-window -h -l 60 '"
      .. "bash "
      .. bash_additional_flags
      .. "-c \""
      .. command_to_run
      .. "; echo; echo Press any key to exit...; read -n 1; exit\"'"
    )
  else
    vim.notify("Not a Ruby file.", vim.log.levels.WARN)
  end
end

return {
  -- I do not use DAP for Ruby projects.
  { "suketa/nvim-dap-ruby", enabled = false },
  -- I do not execute test from nvim.
  { "olimorris/neotest-rspec", enabled = false },

  -- add keymaps to which-key
  {
    "folke/which-key.nvim",
    ft = "ruby",
    opts = {
      spec = {
        { "<leader>e", group = "execute" },
        { "<leader>er", function() execute_file("ruby", false) end, desc = "Ruby file", mode = "n" },
        { "<leader>eR", function() execute_file("rails t", true) end, desc = "Rails file", mode = "n" },
      },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- Alternative LSP server to ruby-lsp for navigation (no auto-completion).
  {
    "neovim/nvim-lspconfig",
    dependencies = { "pheen/fuzzy_ruby_server" },
    opts = {
      servers = {
        fuzzy_ls = {
          init_options = {
            allocationType = "tempdir",
            indexGems = false,
            reportDiagnostics = false,
          },
        },
      },
      setup = {
        fuzzy_ls = function(_, opts)
          local lspconfig = require("lspconfig")
          local configs = require("lspconfig.configs")

          if not configs.fuzzy_ls then
            configs.fuzzy_ls = {
              default_config = {
                cmd = { vim.fn.expand(vim.fn.stdpath("data") .. "/lazy/fuzzy_ruby_server/bin/fuzzy_x86_64-unknown-linux-gnu") },
                filetypes = { "ruby" },
                root_dir = function(fname)
                  return vim.fs.dirname(vim.fs.find('.git', { path = fname, upward = true })[1])
                end,
                settings = {},
                init_options = {
                  -- possible values:
                  -- ram: use RAM (can be very high on big project)
                  -- tempdir: use mmap directory to store the indexes (e.g. /tmp/.tmpcCUkiK)
                  allocationType = "ram",
                  indexGems = true,
                  reportDiagnostics = true,
                },
              },
            }
          end
          lspconfig.fuzzy_ls.setup(opts)
        end,
      },
    },
  },
}
