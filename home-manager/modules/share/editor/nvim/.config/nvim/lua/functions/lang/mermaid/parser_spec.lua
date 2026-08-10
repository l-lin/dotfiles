local parser = require("functions.lang.mermaid.parser")

describe("mermaid.parser.find_mermaid_blocks", function()
  it("GIVEN strict mermaid fences WHEN finding blocks THEN only exact ```mermaid fences are returned", function()
    local markdown_lines = {
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

describe("mermaid.parser.diagram_kind", function()
  it(
    "GIVEN supported headers WHEN detecting the diagram kind THEN it recognizes only the previewed Mermaid families",
    function()
      assert.are.equal("flowchart", parser.diagram_kind("graph LR\nA --> B"))
      assert.are.equal("flowchart", parser.diagram_kind("flowchart TD\nA --> B"))
      assert.are.equal("sequence", parser.diagram_kind("sequenceDiagram\nA->>B: hi"))
      assert.are.equal("state", parser.diagram_kind("stateDiagram-v2\nA --> B"))
      assert.are.equal(nil, parser.diagram_kind("classDiagram\nA <|-- B"))
    end
  )
end)
