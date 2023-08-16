local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  -- find files
  local find_files_cmd =
  "<cmd>Telescope find_files find_command=rg,--no-ignore,--hidden,--glob=!.git/,--glob=!target/,--glob=!node_modules/,--glob=!.terraform/,--files prompt_prefix=🔍<CR>"
  map("n", "<C-g>", find_files_cmd, bufopts, "Find file (Ctrl+g)")
  map("n", "<leader>fa", "<cmd>Telescope live_grep<CR>", bufopts, "Find pattern in all files (Alt+f)")
  map("n", "<M-f>", "<cmd>Telescope live_grep<CR>", bufopts, "Find pattern in all files (Alt+f)")

  map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", bufopts, "Find file in buffer (Ctrl+e)")
  map("n", "<C-e>", "<cmd>Telescope buffers<CR>", bufopts, "Find file in buffer (Ctrl+e)")

  -- history
  map("n", "<leader>f/", "<cmd>Telescope search_history<CR>", bufopts, "Find in search history")

  -- misc
  map("n", "<leader>f:", "<cmd>Telescope commands<CR>", bufopts, "Find nvim command")
  map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", bufopts, "Find help tags")
  map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", bufopts, "Find nvim keymap")
  map("n", "<leader>fo", "<cmd>Telescope vim_options<CR>", bufopts, "Find vim option")
  map("n", "<leader>fs", "<cmd>Telescope luasnip<CR>", bufopts, "Find snippet")
  local find_project_cmd = "<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full' }<CR>"
  map("n", "<leader>fp", find_project_cmd, bufopts, "Find project")
  map("n", "<leader>fy", "<cmd>Telescope yank_history<CR>", bufopts, "Find in yank history")

  -- text
  map("n", "<leader>fti", "<cmd>Telescope current_buffer_fuzzy_find<CR>", bufopts, "Find string in current buffer")
  map("n", "<leader>ftg", "<cmd>Telescope grep_string<CR>", bufopts, "Find string in path")
  map("n", "<leader>fts", "<cmd>Telescope spell_suggest<CR>", bufopts, "Spelling suggestions for current word")

  -- code
  map("n", "<leader>cd", "<cmd>Telescope lsp_definitions<CR>", bufopts, "Goto definition (Ctrl+b)")
  map("n", "<C-b>", "<cmd>Telescope lsp_definitions<CR>", bufopts, "Goto definition (Ctrl+b)")
  -- map("n", "<leader>cD", "<cmd>Telescope diagnostics<CR>", bufopts, "Diagnostic" )
  map("n", "<M-6>", "<cmd>Telescope diagnostics<CR>", bufopts, "Diagnostic (Alt+6)")
  map("n", "<leader>ci", "<cmd>Telescope lsp_implementations<CR>", bufopts, "Goto implementation")
  map("n", "<M-C-B>", "<cmd>Telescope lsp_implementations<CR>", bufopts, "Goto implementation (Ctrl+Alt+b)")
  -- map("n", "<leader>ct", "<cmd>Telescope lsp_type_definitions<CR>", bufopts, "Goto type definition")
  map("n", "<leader>cR", "<cmd>lua require'telescope'.extensions.refactoring.refactors()<CR>", bufopts, "Refactor")
  map("n", "<leader>cu", "<cmd>Telescope lsp_references<CR>", bufopts, "Goto LSP reference (Ctrl+Alt+7)")
  map("n", "<M-&>", "<cmd>Telescope lsp_references<CR>", bufopts, "Goto LSP reference (Ctrl+Alt+7)")
  map("n", "<leader>cv", "<cmd>Telescope treesitter<CR>", bufopts, "Treesitter symbol")
  map("n", "<F36>", "<cmd>Telescope treesitter default_text=function<CR>", bufopts, "Find function (Ctrl+F12)")
  -- map("n", "<leader>cT", "<cmd>Telescope tags<CR>", bufopts, "Find tag" )
  -- map("n", "<leader>fj", "<cmd>Telescope jumplist<CR>", bufopts, "Telescope in jumplist" )
  -- map("n", "<leader>fq", "<cmd>Telescope quickfix<CR>", bufopts, "Telescope in quickfix list" )
  -- map("n", "<leader>f"", "<cmd>Telescope registers<CR>", bufopts, "Telescope in registers" )
  -- map("n", "<leader>f<", "<cmd>Telescope lsp_incoming_calls<CR>", bufopts, "Telescope lsp who am I calling" )
  -- map("n", "<leader>f>", "<cmd>Telescope lsp_outgoing_calls<CR>", bufopts, "Telescope lsp who is calling me" )
  -- map("n", "<leader>f$", "<cmd>Telescope lsp_document_symbols<CR>", bufopts, "Telescope in document functions, variables, expressions..." )
  -- map("n", "<leader>f^", "<cmd>Telescope lsp_workspace_symbols<CR>", bufopts, "Telescope in workspace functions, variables, expressions..." )

  -- git
  map("n", "<leader>fgb", "<cmd>Telescope git_branches<CR>", bufopts, "Telescope in branches")
  map("n", "<leader>fgc", "<cmd>Telescope git_commits<CR>", bufopts, "Telescope in commits")
  map("n", "<leader>fgC", "<cmd>Telescope git_bcommits<CR>", bufopts, "Telescope current buffer commit history")
  map("n", "<leader>fgf", "<cmd>Telescope git_files<CR>", bufopts, "Telescope git files")
  map("n", "<leader>fgs", "<cmd>Telescope git_status<CR>", bufopts, "Telescope modified git files")
  map("n", "<leader>fgt", "<cmd>Telescope git_stash<CR>", bufopts, "Telescope git stash")

  -- DAP
  map("n", "<leader>dc", "<cmd>Telescope dap configurations<CR>", bufopts, "Telescope DAP configurations")
end

M.project_base_directories = function()
  local homepath = os.getenv("HOME")
  local telescope_project_base_dirs = {}
  local possible_base_dirs = {
    homepath .. "/work",
    homepath .. "/perso",
  }

  for _, dirname in ipairs(possible_base_dirs) do
    if vim.fn.isdirectory(dirname) ~= 0 then
      table.insert(telescope_project_base_dirs, dirname)
    end
  end
end

M.load_extension = function()
  require("telescope").load_extension("ui-select")
  require("telescope").load_extension("luasnip")
  require("telescope").load_extension("project")
  require("telescope").load_extension("yank_history")
  require("telescope").load_extension("dap")
end

M.setup = function()
  local config = {
    defaults = {
      file_ignore_patterns = {
        "venv/.*",
      },
      layout_strategy = "flex",
      layout_config = {
        prompt_position = "bottom",
        width = 0.9
      },
      path_display = {
        "truncate",
      },
      sorting_strategy = "descending",
      dynamic_preview_title = true,
    },
    extensions = {
      ["ui-select"] = {
        require("telescope.themes").get_cursor {}
      },
      file_browser = {},
      project = {
        base_dirs = {
          M.project_base_directories()
        },
        order_by = "asc",
        sync_with_nvim_tree = true
      }
    }
  }

  require("telescope").setup(config)

  M.load_extension()
  M.attach_keymaps()
end

return M
