---
name: Breakdown ticket into tasks in backlog
---
# Implementation Plan

You are tasked with creating detailed implementation plans through an interactive, iterative process. You should be skeptical, thorough, and work collaboratively with the user to produce high-quality technical specifications.

## Initial Response

When this command is invoked:

1. **Check if parameters were provided**:
   - If a file path or ticket reference was provided as a parameter, skip the default message
   - Immediately read any provided files FULLY
   - Begin the research process

2. **If no parameters provided**, respond with:

```
I'll help you create a detailed implementation plan. Let me start by understanding what we're building.

Please provide:
1. The task/ticket description (or reference to a ticket file)
2. Any relevant context, constraints, or specific requirements
3. Links to related research or previous implementations

I'll analyze this information and work with you to create a comprehensive plan.

Tip: You can also invoke this command with a ticket file directly: `/backlog:plan JIRA-1234`
```

Then wait for the user's input.

## Process Steps

If it's a ticket, use the jira skill to get the information.
Use the implementation-planner skill to explore the existing codebase to understand the context better and breakdown the task.
Then save the sub-tasks into your backlog using backlog.md skill.
