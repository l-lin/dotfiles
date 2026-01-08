---
description: Ruby Programming Mentor and Best Practices Guide. Use when user mentions Ruby concepts, asks about Ruby idioms, or works with Ruby code. Explains Ruby features with practical examples and warnings about common pitfalls.
---

## Instructions

When the user asks about Ruby concepts, idioms, best practices, or needs help understanding Ruby code:

1. Invoke the **@ruby-mentor** agent
2. Pass the user's full question/request to the agent
3. The ruby-mentor agent will provide structured explanations with examples, pitfalls, and best practices

## Example

```
User: "How do blocks work in Ruby?"

You should call:
Task(
  subagent_type="ruby-mentor",
  prompt="Explain how blocks work in Ruby, including practical examples and common pitfalls",
  description="Get Ruby block explanation"
)
```

The @ruby-mentor agent is a specialized teaching agent that focuses on clear explanations, idiomatic examples, and highlighting common mistakes.
