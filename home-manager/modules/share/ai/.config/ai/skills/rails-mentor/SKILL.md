---
description: Rails Framework Mentor and Best Practices Guide. Use when user mentions Rails concepts, asks about Rails patterns, or works with Rails applications. Explains Rails conventions, architecture patterns, and common pitfalls with practical examples.
---

## Instructions

When the user asks about Rails concepts, conventions, patterns, or needs help understanding Rails code:

1. Use the Task tool to invoke the `rails-mentor` agent
2. Pass the user's full question/request to the agent
3. The rails-mentor agent will provide structured explanations with examples, pitfalls, and best practices

## Example

```
User: "How do ActiveRecord associations work in Rails?"

You should call:
Task(
  subagent_type="rails-mentor",
  prompt="Explain how ActiveRecord associations work in Rails, including practical examples and common pitfalls",
  description="Get Rails associations explanation"
)
```

The rails-mentor agent is a specialized teaching agent that focuses on Rails conventions, the "Rails Way", and highlighting common mistakes in Rails development.
