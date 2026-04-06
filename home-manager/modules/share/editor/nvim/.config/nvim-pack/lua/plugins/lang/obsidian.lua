local function setup()
  require("obsidian").setup({
    checkbox = {
      order = { " ", "x", "-", ">" },
    },
    completion = {
      blink = false,
      min_chars = 2,
      nvim_cmp = false,
    },
    daily_notes = {
      date_format = "%Y-%m-%d",
      default_tags = { "journal/daily" },
      folder = "5-rituals/daily",
      template = "template-daily.nvim.md",
      workdays_only = false,
    },
    frontmatter = { enabled = false },
    footer = { enabled = false },
    log_level = vim.log.levels.ERROR,
    new_notes_location = "notes_subdir",
    note_id_func = function(title)
      if title ~= "" then
        return title
      end
      return tostring(os.time())
    end,
    picker = {
      mappings = {
        insert_link = "<C-l>",
        new = "<C-s>",
      },
      name = "snacks.pick",
    },
    templates = {
      folder = "0-meta/templates",
      substitutions = {
        current_month = require("functions.lang.obsidian").current_month,
        next_month = require("functions.lang.obsidian").next_month,
        next_week = require("functions.lang.obsidian").next_week,
        previous_month = require("functions.lang.obsidian").previous_month,
        time_tracker = require("functions.lang.obsidian").time_tracker,
        today = require("functions.lang.obsidian").today,
        todo = require("functions.lang.obsidian").todo,
        tomorrow = require("functions.lang.obsidian").tomorrow,
        unfinished_yesterday_objective_tasks = require("functions.lang.obsidian").unfinished_yesterday_objective_tasks,
        unfinished_yesterday_other_tasks = require("functions.lang.obsidian").unfinished_yesterday_other_tasks,
        yesterday = require("functions.lang.obsidian").yesterday,
      },
    },
    ui = {
      bullets = {},
      enable = false,
      external_link_icon = {},
      hl_groups = {
        ObsidianBlockID = { link = "Keyword" },
        ObsidianBullet = { link = "Normal" },
        ObsidianDone = { link = "Normal" },
        ObsidianExtLinkIcon = { link = "Keyword" },
        ObsidianHighlightText = { link = "CurSearch" },
        ObsidianRefText = { link = "Keyword" },
        ObsidianTag = { link = "Keyword" },
        ObsidianTodo = { link = "Normal" },
      },
    },
    workspaces = {
      {
        name = "perso",
        path = vim.g.notes_dir,
        overrides = {
          notes_subdir = "6-triage",
        },
      },
    },
  })

  local map = vim.keymap.set
  map("n", "<leader>oy", "<cmd>Obsidian yesterday<cr>", { desc = "Open yesterday's note", noremap = true })
  map("n", "<leader>oo", "<cmd>Obsidian today<cr>", { desc = "Open today's note", noremap = true })
  map("n", "<leader>ot", "<cmd>Obsidian tomorrow<cr>", { desc = "Open tomorrow's note", noremap = true })
  map("n", "<leader>on", "<cmd>Obsidian new<cr>", { desc = "Create note", noremap = true })
  map("n", "<leader>oN", "<cmd>Obsidian new_from_template<cr>", { desc = "Create note using a template", noremap = true })
  map("n", "<leader>or", "<cmd>Obsidian rename<cr>", { desc = "Rename note", noremap = true })
  map("n", "<leader>oa", "<cmd>Obsidian template<cr>", { desc = "Apply template", noremap = true })
  map("n", "<leader>of", "<cmd>Obsidian follow_link<cr>", { desc = "Follow link", noremap = true })
  map("n", "<leader>oT", "<cmd>Obsidian tags<cr>", { desc = "Search tags", noremap = true })
  map("n", "<leader>op", require("functions.lang.obsidian.link_to_markdown").paste_url, { desc = "Paste URL as markdown link", noremap = true })
  map("i", "<M-S-v>", require("functions.lang.obsidian.link_to_markdown").paste_url, { desc = "Paste URL as markdown link", noremap = true })
  map("n", "<leader>oP", require("functions.lang.obsidian.article_to_markdown").paste_url, { desc = "Generate note from URL in clipboard", noremap = true })
  map("n", "<leader>om", require("functions.lang.obsidian").open_current_monthly_note, { desc = "Open current monthly note", noremap = true })
  map("n", "<leader>og", require("functions.lang.obsidian").search_pending_todos, { desc = "Search pending todos", noremap = true })
  map("n", "<leader>os", function()
    require("functions.lang.obsidian.article_summarizer").paste_url(true)
  end, { desc = "Short summarize article from URL in clipboard", noremap = true })
  map("n", "<leader>oS", function()
    require("functions.lang.obsidian.article_summarizer").paste_url(false)
  end, { desc = "Summarize article from URL in clipboard", noremap = true })
  map("v", "<leader>oy", require("functions.lang.obsidian").sanitize_and_yank, { desc = "Yank selection without wiki links", noremap = true })
  map("v", "<leader>oY", require("functions.lang.obsidian").to_html_and_yank, { desc = "Yank selection in HTML format", noremap = true })
end

---@type vim.pack.Spec[]
return {
  {
    src = "https://github.com/nvim-lua/plenary.nvim",
  },
  {
    src = "https://github.com/l-lin/obsidian.nvim",
    data = { setup = setup },
  },
}
