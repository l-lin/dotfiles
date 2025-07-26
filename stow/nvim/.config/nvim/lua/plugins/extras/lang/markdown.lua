---Convert the current line into a task or toggle task status.
local function convert_or_toggle_task()
  -- Get the current line/row/column
  local cursor_pos = vim.api.nvim_win_get_cursor(0)
  local row, _ = cursor_pos[1], cursor_pos[2]
  local line = vim.api.nvim_get_current_line()

  -- 1) If line is empty => replace it with "- [ ] " and set cursor after the brackets
  if line:match("^%s*$") then
    local final_line = "- [ ] "
    vim.api.nvim_set_current_line(final_line)
    -- "- [ ] " is 6 characters, so cursor col = 6 places you *after* that space
    vim.api.nvim_win_set_cursor(0, { row, 6 })
    return
  end

  -- 2) If there's already "- [ ] ", then convert to "- [x] "
  if line:match("^%s*[-*]%s+%[ %]%s+") then
    local final_line = line:gsub("%[ %]", "[x]", 1)
    vim.api.nvim_set_current_line(final_line)
    return
  end

  -- 3) If there's already "- [x] ", then convert to "- [ ] "
  if line:match("^%s*[-*]%s+%[x%]%s+") then
    local final_line = line:gsub("%[x%]", "[ ]", 1)
    vim.api.nvim_set_current_line(final_line)
    return
  end

  -- 4) Check if line already has a bullet with possible indentation: e.g. "  - Something"
  --    We'll capture "  -" (including trailing spaces) as `bullet` plus the rest as `text`.
  local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
  if bullet then
    -- Convert bullet => bullet .. "[ ] " .. text
    local final_line = bullet .. "[ ] " .. text
    vim.api.nvim_set_current_line(final_line)
    -- Place the cursor right after "[ ] "
    -- bullet length + "[ ] " is bullet_len + 4 characters,
    -- but bullet has trailing spaces, so #bullet includes those.
    local bullet_len = #bullet
    -- We want to land after the brackets (four characters: `[ ] `),
    -- so col = bullet_len + 4 (0-based).
    vim.api.nvim_win_set_cursor(0, { row, bullet_len + 4 })
    return
  end

  -- 5) If there's text, but no bullet => prepend "- [ ] " and place cursor after the brackets
  local final_line = "- [ ] " .. line
  vim.api.nvim_set_current_line(final_line)
  -- "- [ ] " is 6 characters
  vim.api.nvim_win_set_cursor(0, { row, 6 })
end

return {
  -- I do not use the preview feature.
  { "iamcco/markdown-preview.nvim", enabled = false },

  -- #######################
  -- override default config
  -- #######################

  -- Plugin to improve viewing Markdown files in Neovim.
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      checkbox = {
        enabled = true,
        right_pad = 0,
        checked = { icon = "󰱒 ", highlight = "RenderMarkdownTodo", scope_highlight = "@markup.strikethrough" },
        unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked", scope_highlight = nil },
        custom = {
          skipped = { raw = "[-]", rendered = "✘ ", highlight = "RenderMarkdownError", scope_highlight = "@markup.strikethrough" },
          postponed = { raw = "[>]", rendered = "󰥔 ", highlight = "RenderMarkdownChecked", scope_highlight = nil },
        },
      },
      heading = {
        enabled = true,
        icons = { "󰎤 ", "󰎧 ", "󰎪 ", "󰎭 ", "󰎱 ", "󰎳 " },
      },
      code = { border = "thin" },
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        -- Disable linter, let me freely write anything without hassle!
        -- src: https://github.com/LazyVim/LazyVim/issues/2437
        markdown = {},
      },
    },
  },

  -- add keymaps to which-key
  {
    "folke/which-key.nvim",
    ft = "markdown",
    opts = {
      spec = {
        {
          "<M-l>",
          convert_or_toggle_task,
          desc = "Convert bullet to a task or insert new task bullet or toggle task",
          mode = { "n", "i" },
          noremap = true,
        },
      },
    },
  },

  -- #######################
  -- add new plugins
  -- #######################

  -- markdown table
  {
    "dhruvasagar/vim-table-mode",
    ft = "markdown",
    keys = {
      { "<leader>tm", false },
      {
        "<leader>cM",
        "<cmd>TableModeToggle<cr>",
        noremap = true,
        silent = true,
        desc = "Toggle Markdown table",
      },
    },
  },

  -- add wiki-links
  {
    "saghen/blink.cmp",
    optional = true,
    dependencies = {
      "l-lin/blink-cmp-wiki-links",
      dev = true
    },
    opts = {
      sources = {
        default = { "wiki_links" },
        providers = {
          wiki_links = {
            name = "wiki_links",
            module = "blink-cmp-wiki-links",
            score_offset = 85,
          },
        },
      },
    },
  },
}
