local pane = require("functions.pane")

---@type fun()|nil
local last_run = nil

---Run a Zig file in a new pane below.
---@param cmd string the command to run
local function execute_file(cmd)
  local filename = vim.fn.expand("%:.")
  if string.match(filename, "%.zig$") then
    last_run = pane.run(cmd .. " " .. vim.fn.shellescape(filename))
  else
    vim.notify("Not a Zig file.", vim.log.levels.WARN)
  end
end

local M = {}
M.execute_file = execute_file
M.rerun_last = function()
  pane.rerun(last_run)
end
return M
