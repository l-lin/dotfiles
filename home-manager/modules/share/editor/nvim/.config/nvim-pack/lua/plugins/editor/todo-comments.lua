---@type vim.pack.Spec
return
-- ✅ Highlight, list and search todo comments in your projects.
{
  src = "https://github.com/folke/todo-comments.nvim",
  data = {
    setup = function()
      vim.schedule(function()
        require("todo-comments").setup({})

        -- stylua: ignore start
        vim.keymap.set("n", "]t", function() require("todo-comments").jump_next() end, { desc = "Next Todo Comment" })
        vim.keymap.set("n", "[t", function() require("todo-comments").jump_prev() end, { desc = "Previous Todo Comment" })
        -- stylua: ignore end

        if package.loaded["snacks"] then
          vim.keymap.set("n", "<M-2>", function()
            Snacks.picker.todo_comments()
          end, { noremap = true, desc = "Find TODO (Alt+2)" })
        end
      end)
    end,
  },
}
