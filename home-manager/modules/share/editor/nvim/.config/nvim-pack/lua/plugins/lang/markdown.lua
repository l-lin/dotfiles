local function setup()
  require("render-markdown").setup({
    checkbox = {
      enabled = true,
      right_pad = 0,
      checked = { icon = "󰱒 ", highlight = "RenderMarkdownTodo", scope_highlight = "@markup.strikethrough" },
      unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked", scope_highlight = nil },
      custom = {
        skipped = {
          raw = "[-]",
          rendered = "✘ ",
          highlight = "RenderMarkdownError",
          scope_highlight = "@markup.strikethrough",
        },
        postponed = {
          raw = "[>]",
          rendered = "󰥔 ",
          highlight = "RenderMarkdownChecked",
          scope_highlight = nil,
        },
      },
    },
    code = {
      border = "thin",
      right_pad = 1,
      sign = false,
      width = "block",
    },
    heading = {
      enabled = true,
      icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
    },
  })

  Snacks.toggle({
    name = "Render Markdown",
    get = function()
      return require("render-markdown.state").enabled
    end,
    set = function(enabled)
      local render_markdown = require("render-markdown")
      if enabled then
        render_markdown.enable()
      else
        render_markdown.disable()
      end
    end,
  }):map("<leader>um")

  local map = vim.keymap.set
  map({ "n", "i" }, "<M-l>", require("functions.lang.markdown").convert_or_toggle_task, {
    desc = "Convert bullet to task or toggle task",
    noremap = true,
  })
  map({ "i", "v" }, "<Tab>", require("functions.lang.markdown").smart_indent, {
    desc = "Indent bullet point",
    noremap = true,
  })
  map({ "i", "v" }, "<S-Tab>", require("functions.lang.markdown").smart_dedent, {
    desc = "Dedent bullet point",
    noremap = true,
  })
  map("v", "<leader>of", require("functions.lang.markdown").fence_selected_text, {
    desc = "Fence selected text with triple backticks",
    noremap = true,
  })
  map("v", "<leader>ob", require("functions.lang.markdown").bold_selected_text, {
    desc = "Make selected text bold",
    noremap = true,
  })
  map("n", "<leader>ob", require("functions.lang.markdown").bold_word_under_cursor, {
    desc = "Make word under cursor bold/unbold",
    noremap = true,
  })
end

---@type vim.pack.Spec
return {
  src = "https://github.com/MeanderingProgrammer/render-markdown.nvim",
  data = { setup = setup },
}
