---Put the cursor in the middle of the screen, only when navigating with count.
---No need to move the whole screen when moving line by line.
---@param key string either 'j' or 'k'
local function move_to_middle_of_screen(key)
  if vim.v.count > 1 then
    vim.api.nvim_command("norm! " .. vim.v.count .. key .. "zz")
  else
    vim.api.nvim_command("norm! " .. key)
  end
end

local M = {}
M.move_to_middle_of_screen = move_to_middle_of_screen
return M
