local M = {}

M.attach_keymaps = function()
  local map = require("mapper").map
  local bufopts = { noremap = true, silent = true }

  -- find files
  local find_files_cmd =
  "<cmd>Telescope find_files find_command=rg,--no-ignore,--hidden,--glob=!.git/,--glob=!target/,--glob=!node_modules/,--glob=!.terraform/,--files prompt_prefix=🔍<cr>"
  map("n", "<C-g>", find_files_cmd, bufopts, "Find file (Ctrl+g)")
  map("n", "<leader>fa", "<cmd>Telescope live_grep<cr>", bufopts, "Find pattern in all files (Alt+f)")
  map("n", "<M-f>", "<cmd>Telescope live_grep<cr>", bufopts, "Find pattern in all files (Alt+f)")

  map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", bufopts, "Find file in buffer (Ctrl+e)")
  map("n", "<C-e>", "<cmd>Telescope buffers<cr>", bufopts, "Find file in buffer (Ctrl+e)")

  -- history
  map("n", "<leader>f/", "<cmd>Telescope search_history<cr>", bufopts, "Find in search history")

  -- misc
  map("n", "<leader>f:", "<cmd>Telescope commands<cr>", bufopts, "Find nvim command")
  map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", bufopts, "Find help tags")
  map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", bufopts, "Find nvim keymap")
  map("n", "<leader>fo", "<cmd>Telescope vim_options<cr>", bufopts, "Find vim option")
  map("n", "<leader>fs", "<cmd>Telescope luasnip<cr>", bufopts, "Find snippet")
  local find_project_cmd = "<cmd>lua require'telescope'.extensions.project.project{ display_type = 'full' }<cr>"
  map("n", "<leader>fp", find_project_cmd, bufopts, "Find project")
  map("n", "<leader>fy", "<cmd>Telescope yank_history<cr>", bufopts, "Find in yank history")

  -- text
  map("n", "<leader>fti", "<cmd>Telescope current_buffer_fuzzy_find<cr>", bufopts, "Find string in current buffer")
  map("n", "<leader>ftg", "<cmd>Telescope grep_string<cr>", bufopts, "Find string in path")
  map("n", "<leader>fts", "<cmd>Telescope spell_suggest<cr>", bufopts, "Spelling suggestions for current word")

  -- code
  map("n", "<leader>cd", "<cmd>Telescope lsp_definitions<cr>", bufopts, "Goto definition (Ctrl+b)")
  map("n", "<C-b>", "<cmd>Telescope lsp_definitions<cr>", bufopts, "Goto definition (Ctrl+b)")
  -- map("n", "<leader>cD", "<cmd>Telescope diagnostics<cr>", bufopts, "Diagnostic" )
  map("n", "<M-6>", "<cmd>Telescope diagnostics<cr>", bufopts, "Diagnostic (Alt+6)")
  map("n", "<leader>ci", "<cmd>Telescope lsp_implementations<cr>", bufopts, "Goto implementation")
  map("n", "<M-C-B>", "<cmd>Telescope lsp_implementations<cr>", bufopts, "Goto implementation (Ctrl+Alt+b)")
  -- map("n", "<leader>ct", "<cmd>Telescope lsp_type_definitions<cr>", bufopts, "Goto type definition")
  map("n", "<leader>cR", "<cmd>lua require'telescope'.extensions.refactoring.refactors()<cr>", bufopts, "Refactor")
  map("n", "<leader>cu", "<cmd>Telescope lsp_references<cr>", bufopts, "Goto LSP reference (Ctrl+Alt+7)")
  map("n", "<M-&>", "<cmd>Telescope lsp_references<cr>", bufopts, "Goto LSP reference (Ctrl+Alt+7)")
  map("n", "<leader>cv", "<cmd>Telescope treesitter<cr>", bufopts, "Treesitter symbol")
  map("n", "<F36>", "<cmd>Telescope treesitter default_text=function<cr>", bufopts, "Find function (Ctrl+F12)")
  -- map("n", "<leader>cT", "<cmd>Telescope tags<cr>", bufopts, "Find tag" )
  -- map("n", "<leader>fj", "<cmd>Telescope jumplist<cr>", bufopts, "Telescope in jumplist" )
  -- map("n", "<leader>fq", "<cmd>Telescope quickfix<cr>", bufopts, "Telescope in quickfix list" )
  -- map("n", "<leader>f"", "<cmd>Telescope registers<cr>", bufopts, "Telescope in registers" )
  -- map("n", "<leader>f<", "<cmd>Telescope lsp_incoming_calls<cr>", bufopts, "Telescope lsp who am I calling" )
  -- map("n", "<leader>f>", "<cmd>Telescope lsp_outgoing_calls<cr>", bufopts, "Telescope lsp who is calling me" )
  -- map("n", "<leader>f$", "<cmd>Telescope lsp_document_symbols<cr>", bufopts, "Telescope in document functions, variables, expressions..." )
  -- map("n", "<leader>f^", "<cmd>Telescope lsp_workspace_symbols<cr>", bufopts, "Telescope in workspace functions, variables, expressions..." )

  -- git
  map("n", "<leader>fgb", "<cmd>Telescope git_branches<cr>", bufopts, "Telescope in branches")
  map("n", "<leader>fgc", "<cmd>Telescope git_commits<cr>", bufopts, "Telescope in commits")
  map("n", "<leader>fgC", "<cmd>Telescope git_bcommits<cr>", bufopts, "Telescope current buffer commit history")
  map("n", "<leader>fgf", "<cmd>Telescope git_files<cr>", bufopts, "Telescope git files")
  map("n", "<leader>fgs", "<cmd>Telescope git_status<cr>", bufopts, "Telescope modified git files")
  map("n", "<leader>fgt", "<cmd>Telescope git_stash<cr>", bufopts, "Telescope git stash")

  -- DAP
  map("n", "<leader>dc", "<cmd>Telescope dap configurations<cr>", bufopts, "Telescope DAP configurations")
end

M.project_base_directories = function()
  local homepath = os.getenv("HOME")
  local telescope_project_base_dirs = {}
  local possible_base_dirs = {
    homepath .. "/work",
    homepath .. "/perso",
    homepath .. "/perso/dotfiles/nvim/.config/nvim"
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
