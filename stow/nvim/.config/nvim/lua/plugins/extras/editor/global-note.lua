local get_project_name = function()
  local result = vim
    .system({
      "git",
      "rev-parse",
      "--show-toplevel",
    }, {
      text = true,
    })
    :wait()

  if result.stderr ~= "" then
    vim.notify(result.stderr, vim.log.levels.WARN)
    return nil
  end

  local project_directory = result.stdout:gsub("\n", "")

  local project_name = vim.fs.basename(project_directory)
  if project_name == nil then
    vim.notify("Unable to get the project name", vim.log.levels.WARN)
    return nil
  end

  return project_name
end

local get_target_directory = function()
  return os.getenv("HOME") .. "/perso/project-notes"
end

local open_file_under_cursor = function(window_id)
  local word = vim.fn.expand("<cfile>")
  -- Check if the word is a valid file path
  if vim.fn.filereadable(word) == 1 then
    -- Close the floating window, so we won't open the file in the floating window.
    vim.api.nvim_win_close(window_id, true)
    -- Open the file in the current buffer
    vim.cmd("edit " .. word)
  else
    -- If not a valid file, fallback to default gf behavior
    vim.cmd("normal! gf")
  end
end

local post_open = function(buffer_id, window_id)
  -- Add keymap on this buffer to press q to close the note.
  vim.keymap.set("n", "q", function()
    vim.api.nvim_win_close(window_id, true)
  end, { buffer = buffer_id })

  -- Remap gf to open the file under cursor in the current buffer, not
  -- in the floating window.
  vim.keymap.set("n", "gf", function()
    open_file_under_cursor(window_id)
  end, { buffer = buffer_id })
end

return {
  --  Opens global note in a float window
  {
    "backdround/global-note.nvim",
    cmd = { "GlobalNote", "ProjectNote" },
    opts = {
      filename = "global.md",
      directory = get_target_directory(),
      command_name = "GlobalNote",
      post_open = post_open,
      additional_presets = {
        project_local = {
          command_name = "ProjectNote",
          title = get_project_name(),
          directory = get_target_directory,
          filename = function()
            return get_project_name() .. ".md"
          end,
          post_open = post_open,
        },
      },
    },
    keys = {
      { "<leader>cn", "<cmd>ProjectNote<cr>", noremap = true, silent = true, desc = "Open project notes" },
      { "<leader>cN", "<cmd>GlobalNote<cr>", noremap = true, silent = true, desc = "Open global notes" },
    },
  },
}
