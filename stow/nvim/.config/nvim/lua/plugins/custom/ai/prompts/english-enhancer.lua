return {
  kind = "role",
  tools = "",
  system = function()
    local path = os.getenv("XDG_CONFIG_HOME") .. "/ai/commands/english-enhancer.md"
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
  end,
  user = function(text)
    return string.format(
      [[Improve the following text:

```
%s
```
]],
      text
    )
  end,
}

