return {
  -- #######################
  -- override default config
  -- #######################
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {
      prompts = {
        EnhanceGrammar = {
          prompt = "Modify the following text to improve grammar and spelling, just output the final text in English without additional quotes around it.",
        },
        EnhanceWording = {
          prompt = "Modify the following text to use better wording, just output the final text without additional quotes around it.",
        },
        MakeConcise = {
          prompt = "Modify the following text to make it as simple and concise as possible, just output the final text without additional quotes around it.",
        },
        SuggestBetterNaming = {
          prompt = "Take all variable and function names, and provide only a list with suggestions with improved naming.",
        },
      },
    },
  },
}
