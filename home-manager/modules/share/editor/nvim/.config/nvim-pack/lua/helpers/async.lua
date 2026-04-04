--
-- Asynchronous calls.
-- src: https://phelipetls.github.io/posts/async-make-in-nvim-with-lua/
--

---Count the number of errors in the quickfix list.
---@return integer Number of errors in the quickfix list.
local function get_nb_errors()
  local qflist = vim.fn.getqflist()
  local error_count = 0
  for _, item in ipairs(qflist) do
    if item.valid == 1 then
      error_count = error_count + 1
    end
  end
  return error_count
end

---Run the make program asynchronously and populate the quickfix list.
local function make()
  local lines = { "" }
  local winnr = vim.fn.win_getid()
  local bufnr = vim.api.nvim_win_get_buf(winnr)

  local makeprg = vim.api.nvim_get_option_value("makeprg", { buf = bufnr, scope = "local" })
  if not makeprg then
    return
  end

  local cmd = vim.fn.expandcmd(makeprg)

  ---Handle job events.
  ---@param _ number Job ID (not used).
  ---@param data string[]|nil Data from stdout or stderr.
  ---@param event string Event type: "stdout", "stderr", or "exit".
  local function on_event(_, data, event)
    if event == "stdout" or event == "stderr" then
      if data then
        vim.list_extend(lines, data)
      end
    end

    if event == "exit" then
      local errorformat = vim.api.nvim_get_option_value("errorformat", { buf = bufnr, scope = "local" })
      vim.fn.setqflist({}, " ", {
        title = cmd,
        lines = lines,
        efm = errorformat,
      })
      vim.api.nvim_command("doautocmd QuickFixCmdPost")

      local error_count = get_nb_errors()
      if error_count == 0 then
        vim.notify(" Build completed successfully", vim.log.levels.INFO, { title = "Make" })
      else
        vim.notify(
          string.format(" Build failed with %d error(s)", error_count),
          vim.log.levels.ERROR,
          { title = "Make" }
        )
      end
    end
  end

  vim.fn.jobstart(cmd, {
    on_stderr = on_event,
    on_stdout = on_event,
    on_exit = on_event,
    stdout_buffered = true,
    stderr_buffered = true,
  })
end

local M = {}
M.make = make
return M
