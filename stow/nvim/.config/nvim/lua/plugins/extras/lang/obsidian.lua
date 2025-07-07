return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",  -- recommended, use latest release instead of latest commit
  lazy = true,
  event = {
    -- If you want to use the home shortcut '~' here you need to call 'vim.fn.expand'.
    -- E.g. "BufReadPre " .. vim.fn.expand "~" .. "/my-vault/**.md"
    "BufReadPre " .. vim.fn.expand "~" .. "/perso/notes/**.md",
    "BufNewFile " .. vim.fn.expand "~" .. "/perso/notes/**.md",
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = {
      {
        name = "perso",
        path = "~/perso/notes",
        overrides = {
          notes_subdir = "6-triage",
        }
      },
    },

    daily_notes = {
      folder = "5-rituals/daily/2024",
      date_format = "%Y-%m-%d",
      default_tags = { "journal/daily" },
      template = "0-meta/templates/template-daily.md",
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
  },
}
