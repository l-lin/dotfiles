---@type vim.pack.Spec
return
-- ✅ Highlight, list and search todo comments in your projects.
{
  src = "https://github.com/folke/todo-comments.nvim",
  data = {
    setup = function()
      vim.schedule(function ()
        require("todo-comments").setup({})

        local map = vim.keymap.set
        map("n", "]t", function()
          require("todo-comments").jump_next()
        end, { desc = "Next Todo Comment" })
        map("n", "[t", function()
          require("todo-comments").jump_prev()
        end, { desc = "Previous Todo Comment" })

        if package.loaded["snacks"] then
          map("n", "<M-2>", function()
            Snacks.picker.todo_comments()
          end, { noremap = true, desc = "Find TODO (Alt+2)" })
        end
      end)
    end,
  },
}
