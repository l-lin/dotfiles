local M = {}

M.map = function(mode, rhs, lhs, bufopts, desc)
  if bufopts == nil then
    bufopts = {}
  end
  bufopts.desc = desc
  vim.keymap.set(mode, rhs, lhs, bufopts)
end

return M
