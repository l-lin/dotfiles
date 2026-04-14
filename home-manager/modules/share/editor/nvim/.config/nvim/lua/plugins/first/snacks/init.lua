-- Local variables to store the PR ID and repo name for resuming PR review.
-- Poor man implementation of state management for PR review.
-- This allows the user to resume reviewing the same PR after closing the picker or switching to another picker.
local pr_id = nil
local repo_name = nil

---@param next_repo_name string|nil
---@param next_pr_id number|string|nil
local function set_review_target(next_repo_name, next_pr_id)
  repo_name = next_repo_name
  pr_id = next_pr_id and tonumber(next_pr_id) or nil
end

---Sync the review target from the buffer name.
---@param buffer_name string
local function sync_review_target_from_buffer_name(buffer_name)
  local next_repo_name, next_pr_id = buffer_name:match("^gh://([^/]+/[^/]+)/pr/(%d+)$")
  if next_repo_name and next_pr_id then
    set_review_target(next_repo_name, next_pr_id)
  end
end

---Review a PR by ID. The repo is determined by the current git repository.
local function review_pr()
  vim.ui.input({ prompt = "PR ID: " }, function(input)
    local next_pr_id = tonumber(input)
    local next_repo_name = require("functions.git").get_current_repo_name()
    set_review_target(next_repo_name, next_pr_id)

    if not pr_id or not repo_name then
      return
    end
    Snacks.picker.gh_diff({ pr = pr_id, repo = repo_name })
  end)
end

---Resume reviewing the PR if the PR ID and repo name are available.
local function resume_review_pr()
  if not pr_id or not repo_name then
    review_pr()
    return
  end
  Snacks.picker.gh_diff({ pr = pr_id, repo = repo_name })
end

---Open the pull request from the clipboard URL in a new tab.
local function open_pr_from_clipboard()
  local clipboard_content = vim.fn.getreg("+"):gsub("%s+$", "")
  local next_repo_name, next_pr_id = require("functions.git").extract_repo_name_and_pr_id_from_url(clipboard_content)
  set_review_target(next_repo_name, next_pr_id)

  if not repo_name or not pr_id then
    vim.notify("Clipboard does not contain a pull request URL", vim.log.levels.ERROR)
    return
  end

  vim.cmd.tabedit(("gh://%s/pr/%d"):format(repo_name, pr_id))
end

---Switch mode from files to grep.
---src: https://github.com/folke/snacks.nvim/discussions/499
---@param picker snacks.Picker the current picker
local function switch_to_grep(picker)
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  local pattern = picker.input.filter.pattern or picker.input.filter.search
  local search = (pattern and pattern:match("%S")) and (" -- -g **/*" .. pattern .. "*/**") or ""

  snacks.picker.grep({ cwd = cwd, search = search })
  vim.defer_fn(function()
    require("functions.cursor").move_to_column(0)
  end, 10)
end

---Append file search to the search.
---@param picker snacks.Picker the current picker
local function append_file_search(picker)
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  local pattern = picker.input.filter.search or picker.input.filter.pattern
  local search = (pattern and pattern:match("%S")) and (pattern .. " -- -g **/**/**") or ""
  -- cursor position: after "pattern -- -g **/*" (before the second *)
  local cursor_col = (pattern and pattern:match("%S")) and (#pattern + #" -- -g **/*") or 0

  snacks.picker.grep({ cwd = cwd, search = search })
  vim.defer_fn(function()
    require("functions.cursor").move_to_column(cursor_col)
  end, 10)
end

---Append file type to the search.
---@param picker snacks.Picker the current picker
local function append_file_type(picker)
  local snacks = require("snacks")
  local cwd = picker.input.filter.cwd

  picker:close()

  local pattern = picker.input.filter.search or picker.input.filter.pattern
  local filetype = vim.bo.filetype
  local search = (pattern and pattern:match("%S")) and (pattern .. " -- -t" .. filetype) or ""

  snacks.picker.grep({ cwd = cwd, search = search })
end

---Edit the file typed on the prompt.
---@param picker snacks.Picker the current picker
local function edit_file(picker)
  local prompt = picker.input.filter.pattern
  picker:close()
  vim.api.nvim_command("edit! " .. prompt)
end

---De-duplicate LSP items across multiple clients.
---@type snacks.picker.transform
local function deduplicate_lsp_items(item, ctx)
  local seen = ctx.meta.seen
  if not seen then
    seen = {}
    ctx.meta.seen = seen
  end
  local pos = item.pos or {}
  local key = table.concat({
    item.file or "",
    tostring(pos[1] or ""),
    tostring(pos[2] or ""),
  }, ":")
  if seen[key] then
    return false
  end

  seen[key] = true
  return item
end

local function setup()
  local gh_diff_tree = require("plugins.first.snacks.gh_diff_tree")
  local gh_pr_review_requested = require("plugins.first.snacks.gh_pr_review_requested")

  require("snacks").setup({
    animate = { enabled = false },
    bigfile = { enabled = true },
    bufdelete = { enabled = true },
    dashboard = { enabled = false },
    debug = { enabled = false },
    dim = { enabled = false },
    explorer = { enabled = false },
    gh = { enabled = true },
    git = { enabled = true },
    gitbrowse = { enabled = true },
    keymap = { enabled = false },
    lazygit = { enabled = true, win = { width = 0, height = 0 } },
    layout = { enabled = false },
    image = { enabled = true },
    indent = { enabled = true, animate = { enabled = false }, scope = { hl = "NormalFloat" } },
    input = { enabled = true },
    matcher = { enabled = true, fuzzy = true, cwd_bonus = true },
    notifier = { enabled = true, top_down = false },
    notify = { enabled = false },
    picker = {
      enabled = true,
      layouts = {
        vertical = {
          reverse = true,
          cycle = true,
          layout = {
            backdrop = false,
            border = "rounded",
            box = "vertical",
            height = 0.9,
            min_height = 30,
            title = "{title} {live} {flags}",
            title_pos = "center",
            width = 0.9,
            { win = "preview", title = "{preview}", height = 0.6, border = "bottom" },
            { win = "list", border = "none" },
            { win = "input", height = 1, border = "top" },
          },
        },
        select = { cycle = true },
      },
      layout = "ivy_split",
      focus = "input",
      formatters = {
        file = { truncate = 150 },
      },
      previewers = {
        diff = {
          builtin = false,
          cmd = { "delta" },
        },
        git = { builtin = false },
      },
      sources = {
        files = {
          focus = "input",
          actions = {
            edit_file = edit_file,
            switch_to_grep = switch_to_grep,
          },
          win = {
            input = {
              keys = {
                ["<M-k>"] = { "switch_to_grep", desc = "Switch to grep", mode = { "i", "v" } },
                ["<C-s>"] = { "edit_file", desc = "Edit file", mode = { "i", "v" } },
              },
            },
            list = {
              keys = {
                ["<C-s>"] = "edit_file",
              },
            },
          },
        },
        git_files = {
          focus = "input",
          actions = {
            edit_file = edit_file,
            switch_to_grep = switch_to_grep,
          },
          win = {
            input = {
              keys = {
                ["<M-k>"] = { "switch_to_grep", desc = "Switch to grep", mode = { "i", "v" } },
                ["<C-s>"] = { "edit_file", desc = "Edit file", mode = { "i", "v" } },
              },
            },
            list = {
              keys = {
                ["<C-s>"] = "edit_file",
              },
            },
          },
        },
        gh_diff = {
          layout = "sidebar",
          focus = "list",
          finder = gh_diff_tree.finder,
          format = gh_diff_tree.format,
          preview = gh_diff_tree.preview,
          confirm = gh_diff_tree.confirm,
          actions = {
            gh_diff_tree_close = gh_diff_tree.close,
            gh_diff_tree_open = gh_diff_tree.open,
            gh_diff_tree_toggle = gh_diff_tree.toggle,
          },
          formatters = {
            file = {
              filename_only = true,
            },
          },
          win = {
            list = {
              keys = {
                ["H"] = "gh_diff_tree_close",
                ["L"] = "gh_diff_tree_open",
                ["za"] = "gh_diff_tree_toggle",
                ["<M-a>"] = { "gh_actions", mode = { "n", "x" } },
              },
            },
            preview = {
              keys = {
                ["<M-c>"] = { "gh_comment", mode = { "n", "x" } },
                ["<cr>"] = { "gh_actions", mode = { "n", "x" } },
                ["<M-a>"] = { "gh_actions", mode = { "n", "x" } },
              },
            },
          },
        },
        gh_pr_review_requested = {
          title = " Pull Requests Requiring My Review",
          finder = gh_pr_review_requested.finder,
          format = "gh_format",
          preview = "gh_preview",
          sort = { fields = { "score:desc", "idx" } },
          supports_live = false,
          live = false,
          confirm = "gh_actions",
          win = {
            input = {
              keys = {
                ["<M-a>"] = { "gh_actions", mode = { "n", "x" } },
                ["<M-b>"] = { "gh_browse", mode = { "n", "i" } },
                ["<M-y>"] = { "gh_yank", mode = { "n", "i" } },
              },
            },
            list = {
              keys = {
                ["<M-a>"] = { "gh_actions", mode = { "n", "x" } },
                ["<M-y>"] = { "gh_yank", mode = { "n", "x" } },
              },
            },
          },
        },
        grep = {
          actions = {
            append_file_search = append_file_search,
            append_file_type = append_file_type,
          },
          win = {
            input = {
              keys = {
                ["<M-k>"] = { "append_file_search", desc = "Append file search", mode = { "i", "v" } },
                ["<M-j>"] = { "append_file_type", desc = "Append file type", mode = { "i", "v" } },
              },
            },
          },
        },
        select = { focus = "input" },
        lsp_definitions = { transform = deduplicate_lsp_items },
        lsp_references = { transform = deduplicate_lsp_items },
      },
      win = {
        input = {
          keys = {
            ["<M-l>"] = { "focus_list", mode = { "i", "n" } },
            ["<M-w>"] = { "focus_preview", mode = { "i", "n" } },
            ["<M-q>"] = { "qflist", mode = { "i", "n" } },
          },
        },
        list = {
          keys = {
            ["a"] = "focus_input",
            ["<M-l>"] = "focus_list",
            ["<M-w>"] = "focus_preview",
            ["<M-q>"] = "qflist",
            ["<C-c>"] = "close",
          },
        },
        preview = {
          keys = {
            ["a"] = "focus_input",
            ["<M-l>"] = "focus_list",
            ["<M-w>"] = "focus_preview",
          },
        },
      },
      debug = { scores = false },
    },
    profiler = { enabled = false },
    quickfile = { enabled = true },
    rename = { enabled = true },
    scope = { enabled = true },
    scratch = { enabled = true },
    scroll = { enabled = false },
    statuscolumn = { enabled = true },
    terminal = { enabled = false },
    toggle = { enabled = false },
    util = { enabled = false },
    win = { enabled = false },
    words = { enabled = true },
    zen = { enabled = false },
  })

  -- stylua: ignore start
  local selector = require("functions.selector")
  vim.keymap.set("n", "<leader>bo", function() Snacks.bufdelete.other() end, { desc = "Delete Other Buffers" })
  vim.keymap.set("n", "<C-g>", function() Snacks.picker.files({ focus = "input" }) end, { noremap = true, silent = true, desc = "Find file (Ctrl+g)" })
  vim.keymap.set("v", "<C-g>", function() Snacks.picker.files({ pattern = selector.get_selected_text() }) end, { noremap = true, silent = true, desc = "Find file (Ctrl+g)" })
  vim.keymap.set("n", "<C-t>", function() Snacks.picker.files({ pattern = require("functions.coding.subject").find_subject() }) end, { desc = "Find associated test file (Ctrl+t)", noremap = true, silent = true })
  vim.keymap.set("n", "<M-f>", function() Snacks.picker.grep({ focus = "input" }) end, { noremap = true, silent = true, desc = "Find pattern in all files (Alt+f)" })
  vim.keymap.set("v", "<M-f>", function() Snacks.picker.grep({ search = selector.get_selected_text() }) end, { noremap = true, silent = true, desc = "Find pattern in all files (Alt+f)" })
  vim.keymap.set("n", "<M-e>", function()
    Snacks.picker.buffers({
      current = false,
      win = {
        input = {
          keys = {
            ["<c-x>"] = { "bufdelete", mode = { "i", "n" } },
            ["<C-j>"] = { "focus_list", mode = { "i", "n" } },
            ["<C-k>"] = { "focus_preview", mode = { "i", "n" } },
          },
        },
        list = {
          keys = {
            ["d"] = "bufdelete",
            ["<C-j>"] = "",
            ["<C-k>"] = "focus_input",
          },
        },
        preview = {
          keys = {
            ["<C-j>"] = "focus_input",
            ["<C-k>"] = "",
          },
        },
      },
    })
  end, {
    noremap = true,
    silent = true,
    desc = "Find file in buffer (Alt+e)",
  })
  vim.keymap.set("n", "<C-x>", function() Snacks.picker.resume() end, { noremap = true, silent = true, desc = "Resume search" })
  vim.keymap.set("n", "<M-6>", function() Snacks.picker.diagnostics() end, { noremap = true, silent = true, desc = "Diagnostic (Alt+6)" })
  vim.keymap.set("n", "<leader>N", function() Snacks.picker.notifications() end, { desc = "Notification History" })
  vim.keymap.set("n", "<leader>:", function() Snacks.picker.command_history() end, { desc = "Command History" })

  -- find
  vim.keymap.set("n", "<leader>fb", function() Snacks.picker.buffers() end, { desc = "Buffers" })
  vim.keymap.set("n", "<leader>fB", function() Snacks.picker.buffers({ hidden = true, nofile = true }) end, { desc = "Buffers (all)" })
  vim.keymap.set("n", "<leader>fg", function() Snacks.picker.git_files() end, { desc = "Find Files (git-files)" })
  -- git
  vim.keymap.set("n", "<M-9>", function() Snacks.picker.git_log({ current_file = true, follow = true }) end, { noremap = true, silent = true, desc = "Check current file git history (Alt+9)" })
  vim.keymap.set("n", "<leader>gb", function() Snacks.picker.git_log_line({ current_line = true, current_file = true, follow = true }) end, { desc = "Git Blame Line" })
  vim.keymap.set("n", "<leader>gd", function() Snacks.picker.git_diff() end, { desc = "Git Diff (hunks)" })
  vim.keymap.set("n", "<leader>gD", function() Snacks.picker.git_diff({ base = "origin", group = true }) end, { desc = "Git Diff (origin)" })
  vim.keymap.set("n", "<leader>gl", function() Snacks.picker.git_log({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() }) end, { desc = "Git Log" })
  vim.keymap.set("n", "<leader>gL", function() Snacks.picker.git_log() end, { desc = "Git Log (cwd)" })
  -- vim.keymap.set("n", "<leader>gi", function() Snacks.picker.gh_issue() end, { desc = "GitHub Issues (open)" })
  -- vim.keymap.set("n", "<leader>gI", function() Snacks.picker.gh_issue({ state = "all" }) end, { desc = "GitHub Issues (all)" })
  -- vim.keymap.set("n", "<leader>gp", function() Snacks.picker.gh_pr() end, { desc = "GitHub Pull Requests (open)" })
  -- vim.keymap.set("n", "<leader>gP", function() Snacks.picker.gh_pr({ state = "all" }) end, { desc = "GitHub Pull Requests (all)" })
  vim.keymap.set("n", "<leader>gs", function() Snacks.picker.git_status({ layout = "sidebar" }) end, { desc = "Git Status" })
  vim.keymap.set("n", "<leader>gS", function() Snacks.picker.git_stash() end, { desc = "Git Stash" })
  if vim.fn.executable("lazygit") == 1 then
    vim.keymap.set("n", "<leader>gg", function() Snacks.lazygit({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() }) end, { desc = "Lazygit (Root Dir)" })
    vim.keymap.set("n", "<leader>gG", function() Snacks.lazygit() end, { desc = "Lazygit (cwd)" })
    vim.keymap.set("n", "<M-)>", function() Snacks.lazygit({ cwd = vim.fs.root(0, ".git") or vim.uv.cwd() }) end, { desc = "LazyGit open history", noremap = true })
  end
  -- github
  vim.keymap.set("n", "<leader>grl", gh_pr_review_requested.open, { desc = "GitHub list Pull Requests requiring my review" })
  vim.keymap.set("n", "<leader>grp", open_pr_from_clipboard, { desc = "Open GitHub Pull Request from clipboard" })
  vim.keymap.set("n", "<leader>grr", review_pr, { desc = "Review PR diff" })
  vim.keymap.set("n", "<leader>grx", resume_review_pr, { desc = "Resume review PR diff" })
  -- grep
  vim.keymap.set("n", "<leader>sb", function() Snacks.picker.lines() end, { desc = "Buffer Lines" })
  vim.keymap.set("n", "<leader>sB", function() Snacks.picker.grep_buffers() end, { desc = "Grep Open Buffers" })
  vim.keymap.set("n", "<leader>sp", function() Snacks.picker.lazy() end, { desc = "Search for Plugin Spec" })
  -- search
  vim.keymap.set("n", '<leader>s"', function() Snacks.picker.registers() end, { desc = "Registers" })
  vim.keymap.set("n", '<leader>s/', function() Snacks.picker.search_history() end, { desc = "Search History" })
  vim.keymap.set("n", "<leader>sa", function() Snacks.picker.autocmds() end, { desc = "Autocmds" })
  vim.keymap.set("n", "<leader>sc", function() Snacks.picker.command_history() end, { desc = "Command History" })
  vim.keymap.set("n", "<leader>sC", function() Snacks.picker.commands() end, { desc = "Commands" })
  vim.keymap.set("n", "<leader>sd", function() Snacks.picker.diagnostics() end, { desc = "Diagnostics" })
  vim.keymap.set("n", "<leader>sD", function() Snacks.picker.diagnostics_buffer() end, { desc = "Buffer Diagnostics" })
  vim.keymap.set("n", "<leader>sh", function() Snacks.picker.help() end, { desc = "Help Pages" })
  vim.keymap.set("n", "<leader>sH", function() Snacks.picker.highlights() end, { desc = "Highlights" })
  vim.keymap.set("n", "<leader>si", function() Snacks.picker.icons() end, { desc = "Icons (Ctrl+Alt+;)" })
  vim.keymap.set("i", "<M-C-;>", function() Snacks.picker.icons() end, { desc = "Icons (Ctrl+Alt+;)" })
  vim.keymap.set("n", "<leader>sj", function() Snacks.picker.jumps() end, { desc = "Jumps" })
  vim.keymap.set("n", "<leader>sk", function() Snacks.picker.keymaps() end, { desc = "Keymaps" })
  vim.keymap.set("n", "<leader>sl", function() Snacks.picker.loclist() end, { desc = "Location List" })
  vim.keymap.set("n", "<leader>sM", function() Snacks.picker.man() end, { desc = "Man Pages" })
  vim.keymap.set("n", "<leader>sm", function() Snacks.picker.marks() end, { desc = "Marks" })
  vim.keymap.set("n", "<leader>sR", function() Snacks.picker.resume() end, { desc = "Resume" })
  vim.keymap.set("n", "<leader>sq", function() Snacks.picker.qflist() end, { desc = "Quickfix List" })
  vim.keymap.set("n", "<leader>su", function() Snacks.picker.undo() end, { desc = "Undotree" })

  -- toggle ui
  Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
  Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
  Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
  Snacks.toggle.diagnostics():map("<leader>ud")
  Snacks.toggle.line_number():map("<leader>ul")
  Snacks.toggle.treesitter():map("<leader>uT")
  -- stylua: ignore end

  vim.api.nvim_create_autocmd("User", {
    pattern = "MiniFilesActionRename",
    callback = function(event)
      Snacks.rename.on_rename_file(event.data.from, event.data.to)
    end,
  })

  -- autocmd to save the repo_name and pr_id
  vim.api.nvim_create_autocmd("BufEnter", {
    pattern = "gh://*",
    callback = function(event)
      if vim.api.nvim_get_current_buf() ~= event.buf then
        return
      end
      if vim.api.nvim_win_get_config(0).relative ~= "" then
        return
      end

      sync_review_target_from_buffer_name(vim.api.nvim_buf_get_name(event.buf))
    end,
  })
end

---@type vim.pack.Spec
return
-- 🍿 A collection of QoL plugins for Neovim.
{
  src = "https://github.com/folke/snacks.nvim",
  data = { setup = setup },
}
