return {
  {
    "obsidian-nvim/obsidian.nvim",
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
        "<leader>ot",
        "<cmd>Obsidian today<cr>",
        mode = "n",
        noremap = true,
        desc = "Open today's note",
      },
      {
        "<leader>oT",
        "<cmd>Obsidian tomorrow<cr>",
        mode = "n",
        noremap = true,
        desc = "Open tomorrow's note",
      },
    },
    opts = {
      workspaces = {
        {
          name = "perso",
          path = "~/perso/notes",
          overrides = {
            notes_subdir = "6-triage",
          },
        },
      },

      daily_notes = {
        folder = "5-rituals/daily/2024",
        date_format = "%Y-%m-%d",
        default_tags = { "journal/daily" },
        template = "template-daily-nvim.md",
        workdays_only = false,
      },

      templates = {
        folder = "0-meta/templates",
        substitutions = {
          yesterday = function()
            return os.date("%Y-%m-%d", os.time() - 86400)
          end,
          tomorrow = function()
            return os.date("%Y-%m-%d", os.time() + 86400)
          end,
          current_month = function()
            return os.date("%Y-%m")
          end,
          todo = function()
            local t = {}
            if os.date("%u") ~= "6" and os.date("%u") ~= "7" then
              table.insert(t, "- [ ] deploy in production")
            end
            if os.date("%u") == "3" then
              table.insert(t, "- [ ] [[1o1 - " .. os.date("%Y-%m") .. "]]")
            end
            if os.date("%u") == "5" then
              table.insert(t, "- [ ] update [[career progress]] with `/project-checkpoint`")
              table.insert(t, "- [ ] [[workday]]: enter your time")
            end
            if os.date("%u") == "7" then
              table.insert(t, "- [ ] weekly journal with `/weekly`")
              table.insert(t, "- [ ] update main quests")
            end
            return table.concat(t, "\n")
          end,
        },
      },

      completion = {
        nvim_cmp = false,
        -- Enables completion using blink.cmp
        blink = true,
        -- Trigger completion at 2 chars.
        min_chars = 2,
      },

      -- Where to put new notes. Valid options are
      --  * "current_dir" - put new notes in same directory as the current buffer.
      --  * "notes_subdir" - put new notes in the default notes subdirectory.
      new_notes_location = "notes_subdir",

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

      ui = {
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

      -- Optional, boolean or a function that takes a filename and returns a boolean.
      -- `true` indicates that you don't want obsidian.nvim to manage frontmatter.
      disable_frontmatter = true,
    },
  },
}
