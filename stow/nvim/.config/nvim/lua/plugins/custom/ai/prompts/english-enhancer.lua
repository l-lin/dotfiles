return {
  kind = "role",
  tools = "",
  system = function()
    return [[<role>
Act as an English language expert.
</role>
<instruction>
Your task is to enhance the wording and grammar of the given text while maintaining its original meaning.
Improve the clarity and consistency of the user's given text.
</instruction>]]
  end,
  user = function(text)
    return string.format(
      [[Please improve the following text:

```
%s
```
]],
      text
    )
  end,
}

