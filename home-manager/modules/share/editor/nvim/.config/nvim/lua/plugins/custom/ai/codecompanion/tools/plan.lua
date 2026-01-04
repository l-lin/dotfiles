--
-- Plan codecompanion tool to behave like claude-code todo.
-- Shamelessly copied and adapted from https://github.com/toupeira/dotfiles/blob/6906be0d5a11a159e3d9aed9ff7f5c9947f85252/vim/codecompanion/strategies/chat/agents/tools/plan.lua
-- Works best with claude-sonnet-4 model.
--

-- Store separate tasks for each chat buffer
local TASKS = {}

local STATES = {
  pending = " ",
  done = "x",
  skipped = "-",
}

return {
  name = "plan",
  opts = {
    -- Ensure the handler function is only called once.
    -- src: https://codecompanion.olimorris.dev/extending/tools.html#use-handlers-once
    use_handlers_once = true
  },
  system_prompt = [[## Plan tool (`plan`)

You have access to an internal todo list where you can keep track of your tasks to achieve a goal. You can add tasks to the todo list, remove them, and mark them as done or skipped. You can also clear the list to remove all items, use this whenever you start working on a new goal.

# Instructions
## MANDATORY TODO WORKFLOW
1. At the START of every new goal: CLEAR the todo list
  - Remove all previous tasks when beginning work on a different objective
  - Confirm in your thinking: "🗂️ Todo list cleared for new goal"
2. Before taking ACTION: CREATE a comprehensive todo list
  - Break down the goal into specific, actionable tasks
  - Present the complete plan to the user before execution
3. During EXECUTION: Update task status accurately
  - Mark tasks as DONE only when actually completed
  - Mark tasks as SKIPPED when bypassed intentionally
  - Remove tasks that become irrelevant

## TASK MANAGEMENT RULES
- Tasks must be specific and actionable
- Only mark tasks as DONE when genuinely completed
- When user says "next" and current task isn't done, CONTINUE current task first
- Todo list updates are automatically displayed to user (don't repeat or mention changes)
- Always prepare todo list before using other tools

## WORKFLOW PRIORITIES
1. PLANNING: Create todo list before execution
2. EXECUTION: Follow task order and complete current task
3. TRACKING: Maintain accurate task status
4. ADAPTATION: Update list when requirements change

## TODO QUALITY RULES
- Tasks = Specific, measurable actions
- Status = Accurate reflection of completion state
- Order = Logical sequence for goal achievement
- Updates = Real-time reflection of progress

<output_format>
- Always create todo list before taking action
- Maintain accurate task completion status
- Focus on current task until genuinely complete
- Present comprehensive plans before execution
- Update todo list to reflect actual progress
- Don't repeat the todo list or mention any changes that you've made
</output_format>]],

  cmds = {
    function(self, args)
      local action = args.action

      TASKS[self.chat.id] = TASKS[self.chat.id] or {}
      local tasks = TASKS[self.chat.id]

      if action == "add" then
        if not args.text then
          return { status = "error", data = "Argument `text` is required" }
        end
        table.insert(tasks, { text = args.text, state = "pending" })
      elseif action == "remove" then
        if not args.index then
          return { status = "error", data = "Argument `index` is required" }
        end
        table.remove(tasks, args.index)
      elseif action == "update" then
        if not args.index then
          return { status = "error", data = "Argument `index` is required" }
        end
        if not STATES[args.state] then
          return { status = "error", data = "Invalid state `" .. args.state .. "`" }
        end
        tasks[args.index].state = args.state
      elseif action == "clear" then
        TASKS[self.chat.id] = nil
      else
        return { status = "error", data = "Invalid action `" .. action .. "`" }
      end

      return { status = "success" }
    end,
  },

  output = {
    success = function(self, agent)
      -- `for_llm` is blank because LLMs always want a tool response
      -- `for_user` is blank because we don't want to add empty lines
      -- to the output, passing an explicit empty string skips that
      agent.chat:add_tool_output(self, "", "")
    end,

    error = function(self, agent, args, stderr, _)
      agent.chat:add_tool_output(
        self,
        string.format(
          "**Plan Tool**: There was an error running the `%s` action:\n%s",
          args.action,
          vim
            .iter(stderr)
            :flatten()
            :map(function(error)
              return "- " .. error
            end)
            :join("\n")
        )
      )
    end,
  },

  handlers = {
    -- only render the todo list once after all tool calls
    on_exit = function(self, agent)
      local tasks = TASKS[agent.chat.id]
      if not tasks or #tasks == 0 then
        return agent.chat:add_tool_output(self, "", "")
      end

      tasks = vim
        .iter(ipairs(tasks))
        :map(function(index, task)
          return string.format("%2d. [%s] %s", index, STATES[task.state], task.text)
        end)
        :join("\n")

      agent.chat:add_tool_output(self, "🗂️ Tasks\n" .. tasks)
    end,
  },

  schema = {
    type = "function",
    ["function"] = {
      name = "plan",
      description = "Manage an internal todo list",
      strict = true,
      parameters = {
        type = "object",
        required = { "action" },
        additionalProperties = false,

        properties = {
          action = {
            type = "string",
            enum = { "add", "remove", "update", "clear" },
            description = "The action to perform",
          },
          text = {
            type = "string",
            description = "The text when adding a new task",
          },
          index = {
            type = "integer",
            description = "The 1-based index of the task when removing or updating existing tasks",
          },
          state = {
            type = "string",
            enum = vim.tbl_keys(STATES),
            description = "The state when updating existing tasks",
          },
        },
      },
    },
  },
}
