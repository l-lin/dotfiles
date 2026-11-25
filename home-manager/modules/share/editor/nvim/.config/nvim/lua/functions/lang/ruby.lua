local pane = require("functions.pane")

---@type fun()|nil
local last_run = nil

---@class dotfiles.ruby.RubyExecutionConfig
---@field cmd string the command to run
---@field use_interactive_shell boolean true to run the command in interactive shell
---@field include_line_number boolean true to include the current line number in the command to run

---Run a Ruby file in a new pane below.
---@param config dotfiles.ruby.RubyExecutionConfig the configuration to use for executing ruby file
local function execute_file(config)
  local filename = vim.fn.expand("%:.")
  if string.match(filename, "%.rb$") then
    if config.include_line_number then
      filename = filename .. ":" .. vim.fn.line(".")
    end

    last_run = pane.run(config.cmd .. " " .. vim.fn.shellescape(filename), config.use_interactive_shell)
  else
    vim.notify("Not a Ruby file.", vim.log.levels.WARN)
  end
end

local M = {}
M.execute_file = execute_file
M.rerun_last = function()
  pane.rerun(last_run)
end
return M
