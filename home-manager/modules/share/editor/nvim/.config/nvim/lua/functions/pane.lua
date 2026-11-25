local M = {}

local function launch(command)
  local ok, err = pcall(
    vim.system,
    command,
    { text = true },
    vim.schedule_wrap(function(result)
      if result.code ~= 0 then
        local message = vim.trim(result.stderr or "")
        if message == "" then
          message = "Cannot open a pane. Exit code: " .. result.code
        end
        vim.notify(message, vim.log.levels.ERROR)
      end
    end)
  )
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

local function run_in_tmux(args, cwd)
  local command = { "tmux", "split-window", "-v", "-l", "20", "-c", cwd }
  local target = vim.env.TMUX_PANE
  if target and target ~= "" then
    vim.list_extend(command, { "-t", target })
  end
  launch(vim.list_extend(command, args))
end

local function run_in_rex(args, cwd, session, block)
  local rex = "rex"
  if vim.fn.executable(rex) == 0 and vim.env.REX_BIN_DIR and vim.env.REX_BIN_DIR ~= "" then
    rex = vim.fs.joinpath(vim.env.REX_BIN_DIR, rex)
  end
  local command = { rex, "split", "-s", session, "-b", block, "--split=below", "--ratio", "30", "--focus=false" }
  vim.list_extend(command, { "-c", cwd, "--" })
  launch(vim.list_extend(command, args))
end

---Run a Bash command in a new pane below. Return a function that repeats it in the same directory.
---@param command string
---@param interactive? boolean
---@return fun()
function M.run(command, interactive)
  local cwd = vim.fn.getcwd()
  local script = command
    .. [=[

printf '\nPress q to exit...\n'
while IFS= read -rn 1 key; do
  if [[ "$key" == q ]]; then break; fi
done
]=]
  local args = { "bash", interactive and "-ic" or "-c", script }

  local function run()
    local session, block = vim.env.REX_SESSION, vim.env.REX_BLOCK
    if vim.env.TMUX and vim.env.TMUX ~= "" then
      run_in_tmux(args, cwd)
    elseif session and session ~= "" and block and block ~= "" then
      run_in_rex(args, cwd, session, block)
    else
      vim.notify("Cannot open a pane. Run Neovim inside tmux or Rex.", vim.log.levels.ERROR)
    end
  end
  run()
  return run
end

---@param last_run? fun()
function M.rerun(last_run)
  if last_run then
    last_run()
  else
    vim.notify("No previous command to re-run.", vim.log.levels.WARN)
  end
end

return M
