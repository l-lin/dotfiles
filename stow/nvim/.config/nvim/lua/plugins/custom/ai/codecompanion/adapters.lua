return {
  -- GITHUB COPILOT
  copilot = function()
    return require("codecompanion.adapters").extend("copilot", {
      name = "copilot_custom",
      schema = {
        model = { default = "claude-sonnet-4" },
        temperature = { default = 0 },
        max_tokens = { default = 200000 },
      },
    })
  end,
  -- OLLAMA
  codellama = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "codellama",
      schema = {
        model = { default = "codellama:7b-instruct-q2_K" },
      },
    })
  end,
}
