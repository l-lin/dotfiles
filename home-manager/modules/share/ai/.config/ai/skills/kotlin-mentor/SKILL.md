---
description: Kotlin Programming Mentor and Best Practices Guide
---

## Instructions

When the user asks about Kotlin concepts, idioms, best practices, or needs help understanding Kotlin code:

1. Use the Task tool to invoke the `kotlin-mentor` agent
2. Pass the user's full question/request to the agent
3. The kotlin-mentor agent will provide structured explanations with examples, pitfalls, and best practices

## Example

```
User: "How does null safety work in Kotlin?"

You should call:
Task(
  subagent_type="kotlin-mentor",
  prompt="Explain how null safety works in Kotlin, including practical examples and common pitfalls",
  description="Get Kotlin null safety explanation"
)
```

The kotlin-mentor agent is a specialized teaching agent that focuses on clear explanations, idiomatic examples, and highlighting common mistakes in Kotlin development.
