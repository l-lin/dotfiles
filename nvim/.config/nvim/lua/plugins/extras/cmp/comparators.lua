local types = require("cmp.types")

-- Custom comparators as the one provided by default by CMP does not suit my tastes.
local M = {}

---has_value: check if the given `tab` contains `val`
---@param tab tablelib
---@param val string
local function has_value(tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

---deprioritize_kind: move given LSP Kind to the bottom
---from: https://www.reddit.com/r/neovim/comments/14k7pbc/what_is_the_nvimcmp_comparatorsorting_you_are/
---@param kind lsp.CompletionItemKind
M.deprioritize_kind = function(kind)
  return function(e1, e2)
    if e1:get_kind() == kind then
      return false
    end
    if e2:get_kind() == kind then
      return true
    end
  end
end

---move_labels_to_bottom: move given labels to bottom
---@param unwanted tablelib
M.deprioritize_labels = function(unwanted)
  ---@type cmp.ComparatorFunction
  return function(e1, e2)
    if has_value(unwanted, e1.completion_item.label) then
      return false
    end
    if has_value(unwanted, e2.completion_item.label) then
      return true
    end
    return nil
  end
end

---kind: Entires with smaller ordinal value of 'kind' will be ranked higher.
---(see lsp.CompletionItemKind enum).
---Same as the official cmp.compare.kind, except no special care for Snippets.
---@type cmp.ComparatorFunction
M.kind = function(entry1, entry2)
  local kind1 = entry1:get_kind() --- @type lsp.CompletionItemKind | number
  local kind2 = entry2:get_kind() --- @type lsp.CompletionItemKind | number
  kind1 = kind1 == types.lsp.CompletionItemKind.Text and 100 or kind1
  kind2 = kind2 == types.lsp.CompletionItemKind.Text and 100 or kind2
  if kind1 ~= kind2 then
    local diff = kind1 - kind2
    if diff < 0 then
      return true
    elseif diff > 0 then
      return false
    end
  end
  return nil
end

return M
