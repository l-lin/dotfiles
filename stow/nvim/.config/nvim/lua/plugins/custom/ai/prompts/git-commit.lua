return {
  kind = "action",
  tools = "@cmd_runner",
  system = function()
    return string.format([[<role>
You are an expert at following the Conventional Commit specification.
</role>
<instructions>
The commit scope should contain the ticket id that can be extracted from the git branch name '%s'.
<example>
Examples of getting the ticket id from the branch name:

- P3C-123/do_some_stuff => P3C-123
- P3C-123-do_some_stuff  => P3C-123
- P3C-123_do_some_stuff => P3C-123
- feat/P3C-123/do_some_stuff => P3C-123
</example>

After generating commit message, ask the user to validate or to update the message.
Then stage diffs and commit them.
</instructions>
  ]], vim.fn.system("git rev-parse --abbrev-ref HEAD"))
  end,
  user = function()
    return string.format(
      [[Given the git diff listed below, please generate a commit message for me:

```diff
%s
```
]],
      vim.fn.system("git diff --no-ext-diff --staged")
    )
  end,
}
