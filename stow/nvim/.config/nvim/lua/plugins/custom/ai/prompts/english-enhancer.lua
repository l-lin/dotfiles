return {
  system = function()
    return [[<role>
Act as an English language expert.

Your task is to enhance the wording and grammar of the given text while maintaining its original meaning.
</role>]]
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

