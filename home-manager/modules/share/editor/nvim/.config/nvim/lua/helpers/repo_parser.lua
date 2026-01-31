---Check if text matches GitHub repository pattern (user/repo)
---@param text string the text to check
---@return boolean true if matches repo pattern like "username/project"
local function is_repo_pattern(text)
  return text:match("^[%w_][%w%-%._]+/[%w_][%w%-%._]+$") ~= nil
end

local M = {}
M.is_repo_pattern = is_repo_pattern
return M
