---@type vim.pack.Spec
return
--
-- Minimal and fast pairs
--
{
  src = "https://github.com/nvim-mini/mini.pairs",
  data = {
    setup = function()
      vim.schedule(function()
        require("mini.pairs").setup({
          mappings = {
            -- Don't add closing bracket when the right neighbor is a word character or underscore.
            -- neigh_pattern is matched against [left_char][right_char]:
            --   ^[^\\]  = left char is not a backslash (default behaviour)
            --   [^%w_]  = right char is not alphanumeric / underscore
            -- So `(` before `example` stays `(example`; `(` at EOL gives `(|)`.
            ["("] = { action = "open", pair = "()", neigh_pattern = "^[^\\][^%w_]" },
            ["["] = { action = "open", pair = "[]", neigh_pattern = "^[^\\][^%w_]" },
            ["{"] = { action = "open", pair = "{}", neigh_pattern = "^[^\\][^%w_]" },
          },
        })
      end)
    end,
  },
}
