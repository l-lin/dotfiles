dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

local parser = require("functions.lang.mermaid.parser")

describe("mermaid.parser.find_mermaid_blocks", function()
  local function given_markdown_lines()
    return {
      "```mermaid",
      "flowchart TD",
      "A --> B",
      "```",
      "",
      "```mermaid title=ignored",
      "flowchart TD",
      "B --> C",
      "```",
    }
  end

  it("GIVEN strict mermaid fences WHEN finding blocks THEN only exact ```mermaid fences are returned", function()
    local markdown_lines = given_markdown_lines()

    local actual = parser.find_mermaid_blocks(markdown_lines)
    local expected = {
      {
        start_row = 0,
        end_row = 3,
        indent = "",
        source = "flowchart TD\nA --> B",
        source_lines = { "flowchart TD", "A --> B" },
      },
    }

    assert.are.same(expected, actual)
  end)
end)
