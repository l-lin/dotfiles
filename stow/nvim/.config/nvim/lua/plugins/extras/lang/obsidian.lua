---@module "obsidian.nvim"
return {
  {
    "l-lin/obsidian.nvim",
    version = "*", -- recommended, use latest release instead of latest commit
    lazy = true,
    event = {
      -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
      -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
      "BufReadPre "
        .. vim.fn.expand("~")
        .. "/perso/notes/**.md",
      "BufNewFile " .. vim.fn.expand("~") .. "/perso/notes/**.md",
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "folke/which-key.nvim",
        opts = {
          spec = {
            { "<leader>o", group = "obsidian" },
          },
        },
      },
    },
    keys = {
      {
        "<leader>oy",
        "<cmd>Obsidian yesterday<cr>",
        mode = "n",
        noremap = true,
        desc = "Open yesterday's note",
      },
      {
        "<leader>oo",
        "<cmd>Obsidian today<cr>",
        mode = "n",
        noremap = true,
        desc = "Open today's note",
      },
      {
        "<leader>ot",
        "<cmd>Obsidian tomorrow<cr>",
        mode = "n",
        noremap = true,
        desc = "Open tomorrow's note",
      },
      {
        "<leader>on",
        "<cmd>Obsidian new<cr>",
        mode = "n",
        noremap = true,
        desc = "Create note",
      },
      {
        "<leader>oN",
        "<cmd>Obsidian new_from_template<cr>",
        mode = "n",
        noremap = true,
        desc = "Create note using a template",
      },
      {
        "<leader>or",
        "<cmd>Obsidian rename<cr>",
        mode = "n",
        noremap = true,
        desc = "Rename note",
      },
      {
        "<leader>oT",
        "<cmd>Obsidian template<cr>",
        mode = "n",
        noremap = true,
        desc = "Apply template",
      },
      {
        "<leader>of",
        "<cmd>Obsidian follow_link<cr>",
        mode = "n",
        noremap = true,
        desc = "Follow link",
      },
      {
        "<leader>op",
        require("plugins.custom.lang.obsidian.link_to_markdown").paste_url,
        desc = "Extract title and convert into markdown link (Alt+Shift+v)",
        mode = "n",
        noremap = true,
      },
      {
        "<M-S-v>",
        require("plugins.custom.lang.obsidian.link_to_markdown").paste_url,
        desc = "Extract title and convert into markdown link (Alt+Shift+v)",
        mode = "i",
        noremap = true,
      },
      {
        "<leader>oP",
        require("plugins.custom.lang.obsidian.article_to_markdown").paste_url,
        mode = "n",
        noremap = true,
        desc = "Generate note from URL in clipboard",
      },
      {
        "<leader>om",
        require("plugins.custom.lang.obsidian").open_current_monthly_note,
        desc = "Open current monthly note",
        mode = "n",
        noremap = true,
      },
      {
        "<leader>os",
        require("plugins.custom.lang.obsidian").search_pending_todos,
        desc = "Search pending todos",
        mode = "n",
        noremap = true,
      },
      {
        "<leader>oS",
        require("plugins.custom.lang.obsidian.article_summarizer").paste_url,
        desc = "Summarize artiche from URL in clipboard",
        mode = "n",
        noremap = true,
      },
    },
    opts = {
      -- Too noisy because of https://github.com/obsidian-nvim/obsidian.nvim/blob/5186cba27b256daae5f824b2789e016161f0b20c/lua/obsidian/config.lua#L536-L536
      log_level = vim.log.levels.ERROR,

      workspaces = {
        {
          name = "perso",
          path = vim.g.notes_dir,
          overrides = {
            notes_subdir = "6-triage",
          },
        },
      },

      daily_notes = {
        folder = "5-rituals/daily",
        date_format = "%Y-%m-%d",
        default_tags = { "journal/daily" },
        template = "template-daily-nvim.md",
        workdays_only = false,
      },

      templates = {
        folder = "0-meta/templates",
        substitutions = {
          today = require("plugins.custom.lang.obsidian").today,
          yesterday = require("plugins.custom.lang.obsidian").yesterday,
          tomorrow = require("plugins.custom.lang.obsidian").tomorrow,
          current_month = require("plugins.custom.lang.obsidian").current_month,
          previous_month = require("plugins.custom.lang.obsidian").previous_month,
          next_month = require("plugins.custom.lang.obsidian").next_month,
          todo = require("plugins.custom.lang.obsidian").todo,
        },
      },

      -- Disable completion, as I'm already using my blink-cmp-wiki-links.
      -- The one from obsidian.nvim is not optimized for large vault.
      completion = {
        nvim_cmp = false,
        -- Enables completion using blink.cmp
        blink = false,
        -- Trigger completion at 2 chars.
        min_chars = 2,
      },

      -- Where to put new notes. Valid options are
      --  * "current_dir" - put new notes in same directory as the current buffer.
      --  * "notes_subdir" - put new notes in the default notes subdirectory.
      new_notes_location = "notes_subdir",

      -- Customize how note IDs are generated given an optional title.
      ---@param title string|?
      ---@return string
      note_id_func = function(title)
        if title ~= "" then
          return title
        end
        return tostring(os.time())
      end,

      picker = {
        -- Set your preferred picker. Can be one of 'telescope.nvim', 'fzf-lua', 'mini.pick' or 'snacks.pick'.
        name = "snacks.pick",
        -- Optional, configure key mappings for the picker. These are the defaults.
        -- Not all pickers support all mappings.
        mappings = {
          -- Create a new note from your query.
          new = "<C-s>",
          -- Insert a link to the selected note.
          insert_link = "<C-l>",
        },
      },

      -- Only need those checkboxes.
      checkbox = {
        order = { " ", "x", "-", ">" },
      },

      ui = {
        -- In conflict with render-markdown.nvim.
        enable = false,
        bullets = {},
        -- Use the one from render-markdown.nvim.
        external_link_icon = {},
        -- Use the same colors as the theme, no need to hardcode the colors.
        hl_groups = {
          ObsidianTodo = { link = "Normal" },
          ObsidianDone = { link = "Normal" },
          ObsidianBullet = { link = "Normal" },
          ObsidianRefText = { link = "Keyword" },
          ObsidianExtLinkIcon = { link = "Keyword" },
          ObsidianTag = { link = "Keyword" },
          ObsidianBlockID = { link = "Keyword" },
          ObsidianHighlightText = { link = "CurSearch" },
        },
      },

      -- I don't want automatic frontmatter format.
      disable_frontmatter = true,

      -- For some reason, the footer is opening too many files, and I'm
      -- receiving lots of warning messages...
      footer = { enabled = false },
    },
  },
}
