local M = {}

---Shamelessly copied and adapted from https://github.com/onsails/lspkind.nvim.
local function kind_as_icon(opts, vim_item)
  local icons = require("lazyvim.config").icons.kinds
  if icons[vim_item.kind] then
    vim_item.kind = icons[vim_item.kind] .. vim_item.kind
  end

  if opts.maxwidth ~= nil then
    if opts.ellipsis_char == nil then
      vim_item.abbr = string.sub(vim_item.abbr, 1, opts.maxwidth)
    else
      local label = vim_item.abbr
      local truncated_label = vim.fn.strcharpart(label, 0, opts.maxwidth)
      if truncated_label ~= label then
        vim_item.abbr = truncated_label .. opts.ellipsis_char
      end
    end
  end
  return vim_item
end

---From https://github.com/hrsh7th/nvim-cmp/wiki/Menu-Appearance#how-to-get-types-on-the-left-and-offset-the-menu
M.kind_to_the_left = function(_, vim_item)
  local item = kind_as_icon({ maxwidth = 50, ellipsis_char = "..." }, vim_item)
  local strings = vim.split(item.kind, "%s", { trimempty = true })
  item.kind = " " .. (strings[1] or "") .. " "
  item.menu = "    " .. (strings[2] or "")
  return item
end

return M
