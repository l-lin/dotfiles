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
  deepseek_r1 = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "deepseek",
      schema = {
        model = { default = "deepseek-r1:7b" },
      },
    })
  end,
  gemma3 = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "gemma3",
      schema = {
        model = { default = "gemma3:4b" },
      },
    })
  end,
  phi3 = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "phi3",
      schema = {
        model = { default = "phi3:3.8b-mini-4k-instruct-q4_0" },
      },
    })
  end,
  phi3_5 = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "phi3_5",
      schema = {
        model = { default = "phi3.5:3.8b-mini-instruct-q4_0" },
      },
    })
  end,
  qwen2_5 = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "qwen2_5",
      schema = {
        model = { default = "qwen2.5:7b" },
      },
    })
  end,
  qwen2_5_coder = function()
    return require("codecompanion.adapters").extend("ollama", {
      name = "qwen2_5_coder",
      schema = {
        model = { default = "qwen2.5-coder:7b" },
      },
    })
  end,
}
