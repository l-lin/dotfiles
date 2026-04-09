local function setup_ai()
  local ai = require("mini.ai")
  ai.setup({
    custom_textobjects = {
      o = ai.gen_spec.treesitter({ -- code block
        a = { "@block.outer", "@conditional.outer", "@loop.outer" },
        i = { "@block.inner", "@conditional.inner", "@loop.inner" },
      }),
      f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }), -- function
      c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }), -- class
      t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" }, -- tags
      g = function()
        local from = { line = 1, col = 1 }
        local to = {
          line = vim.fn.line("$"),
          col = math.max(vim.fn.getline("$"):len(), 1),
        }
        return { from = from, to = to }
      end,
    },
  })

  if package.loaded["which-key"] then
    local objects = {
      { " ", desc = "whitespace" },
      { '"', desc = '" string' },
      { "'", desc = "' string" },
      { "(", desc = "() block" },
      { ")", desc = "() block with ws" },
      { "<", desc = "<> block" },
      { ">", desc = "<> block with ws" },
      { "?", desc = "user prompt" },
      { "U", desc = "use/call without dot" },
      { "[", desc = "[] block" },
      { "]", desc = "[] block with ws" },
      { "_", desc = "underscore" },
      { "`", desc = "` string" },
      { "a", desc = "argument" },
      { "b", desc = ")]} block" },
      { "c", desc = "class" },
      { "d", desc = "digit(s)" },
      { "e", desc = "CamelCase / snake_case" },
      { "f", desc = "function" },
      { "g", desc = "entire file" },
      { "i", desc = "indent" },
      { "o", desc = "block, conditional, loop" },
      { "q", desc = "quote `\"'" },
      { "t", desc = "tag" },
      { "u", desc = "use/call" },
      { "{", desc = "{} block" },
      { "}", desc = "{} with ws" },
    }

    ---@type wk.Spec[]
    local ret = { mode = { "o", "x" } }
    ---@type table<string, string>
    local mappings = {
      around = "a",
      inside = "i",
      around_next = "an",
      inside_next = "in",
      around_last = "al",
      inside_last = "il",
    }
    mappings.goto_left = nil
    mappings.goto_right = nil

    for name, prefix in pairs(mappings) do
      name = name:gsub("^around_", ""):gsub("^inside_", "")
      ret[#ret + 1] = { prefix, group = name }
      for _, obj in ipairs(objects) do
        local desc = obj.desc
        if prefix:sub(1, 1) == "i" then
          desc = desc:gsub(" with ws", "")
        end
        ret[#ret + 1] = { prefix .. obj[1], desc = obj.desc }
      end
    end
    require("which-key").add(ret, { notify = false })
  end
end

---@type vim.pack.Spec
return
--
-- Neovim Lua plugin to extend and create `a`/`i` textobjects.
--
{
  src = "https://github.com/nvim-mini/mini.ai",
  data = {
    setup = function()
      vim.schedule(setup_ai)
    end,
  },
}
