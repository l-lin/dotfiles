return {
  description = "Add session summary",
  opts = { contains_code = false },
  ---@param chat CodeCompanion.Chat
  callback = function(chat)
    chat:replace_vars_and_tools({ content = "@mcp @files" })
    chat:add_buf_message({
      content = [[Create `llm_sessions/{timestamp}.md` with a complete summary of our session. Include:

- A brief recap of key actions.
- Total cost of the session.
- Efficiency insights.
- Possible process improvements.
- The total number of conversation turns.
- Any other interesting observations or highlights.
      ]],
      role = "user"
    })
  end,
}

