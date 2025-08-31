---@class dotfiles.kotlin.KotlinExecutionConfig

---Execute all tests with maven on a new tmux pane below.
local function execute_all_tests_with_maven()
  local filename = vim.fn.expand('%:t')
  if string.match(filename, "%.kt$") then
    local tests = string.gsub(filename, "%.kt$", "")
    local command_to_run = "./mvnw test -q -Dsurefire.failIfNoSpecifiedTests=false -Dtest=" .. tests

    local success_log = 'echo -e \\"\\e[1;30;42m SUCCESS \\e[0m\\"'

    -- `-l 20` specifies the size of the tmux pane, in this case 20 rows
    vim.cmd(
      "silent !tmux split-window -v -l 20 '"
        .. 'bash -i -c "'
        .. 'echo \\"' .. command_to_run .. '\\"'
        .. ' && ' .. command_to_run
        .. ' && ' .. success_log
        .. "; echo; echo Press q to exit...; while true; do read -n 1 key; if [[ \\$key == \"q\" ]]; then exit; fi; done\"'"
    )
  else
    vim.notify("Not a Kotlin file.", vim.log.levels.WARN)
  end
end

local M = {}
M.execute_all_tests_with_maven = execute_all_tests_with_maven
return M
