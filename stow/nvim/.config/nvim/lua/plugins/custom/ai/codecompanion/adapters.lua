return {
  -- GITHUB COPILOT
  copilot_custom = function()
    return require("codecompanion.adapters").extend("copilot", {
      name = "copilot_custom",
      schema = {
        model = { default = "gpt-4.1" },
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
