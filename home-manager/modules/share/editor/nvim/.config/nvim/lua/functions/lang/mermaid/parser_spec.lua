dofile((debug.getinfo(1, "S").source:sub(2):match("^(.*)/[^/]+$")) .. "/spec_helper.lua")
if type(describe) ~= "function" then
  require("busted.runner")()
end

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
  it("GIVEN supported headers WHEN detecting the diagram kind THEN it recognizes only the previewed Mermaid families", function()
    assert.are.equal("flowchart", parser.diagram_kind("graph LR\nA --> B"))
    assert.are.equal("flowchart", parser.diagram_kind("flowchart TD\nA --> B"))
    assert.are.equal("sequence", parser.diagram_kind("sequenceDiagram\nA->>B: hi"))
    assert.are.equal("state", parser.diagram_kind("stateDiagram-v2\nA --> B"))
    assert.are.equal(nil, parser.diagram_kind("classDiagram\nA <|-- B"))
  end)
end)

describe("mermaid.parser.parse_mermaid", function()
  it("GIVEN a flowchart with upstream-supported metadata WHEN parsing THEN it keeps graph structure and style metadata", function()
    local actual = assert(parser.parse_mermaid(table.concat({
      "flowchart TD",
      "  classDef hot fill:#f96,stroke:#333",
      "  A[Start]:::hot -- Yes --> B{Check}",
      "  subgraph api [API<br>Layer]",
      "    direction LR",
      "    B --> C[(Store)]",
      "  end",
      "  style C fill:#0f0",
      "  linkStyle 0 stroke:#ff0000,stroke-width:2px",
    }, "\n")))

    assert.are.equal("TD", actual.direction)
    assert.are.equal("Start", actual.nodes.A.label)
    assert.are.equal("rectangle", actual.nodes.A.shape)
    assert.are.equal("Check", actual.nodes.B.label)
    assert.are.equal("diamond", actual.nodes.B.shape)
    assert.are.equal("Store", actual.nodes.C.label)
    assert.are.equal("cylinder", actual.nodes.C.shape)
    assert.are.equal("hot", actual.class_assignments.A)
    assert.are.equal("#f96", actual.class_defs.hot.fill)
    assert.are.equal("#333", actual.class_defs.hot.stroke)
    assert.are.equal("#0f0", actual.node_styles.C.fill)
    assert.are.equal("#ff0000", actual.link_styles[0].stroke)
    assert.are.equal("2px", actual.link_styles[0]["stroke-width"])
    assert.are.equal(1, #actual.subgraphs)
    assert.are.equal("api", actual.subgraphs[1].id)
    assert.are.equal("API\nLayer", actual.subgraphs[1].label)
    assert.are.equal("LR", actual.subgraphs[1].direction)
    assert.are.same({ "C" }, actual.subgraphs[1].node_ids)
    assert.are.equal("Yes", actual.edges[1].label)
    assert.are.equal("solid", actual.edges[1].style)
    assert.are.equal(false, actual.edges[1].has_arrow_start)
    assert.are.equal(true, actual.edges[1].has_arrow_end)
    assert.are.same({}, actual.warnings)
  end)

  it("GIVEN a state diagram with aliases composites and CJK names WHEN parsing THEN it mirrors the upstream logical model", function()
    local actual = assert(parser.parse_mermaid(table.concat({
      "stateDiagram-v2",
      "  direction LR",
      "  state \"Waiting for input\" as waiting",
      "  [*] --> waiting",
      "  waiting --> 空闲 : idle",
      "  空闲 --> 处理中 : 提交",
      "  state \"Active Processing\" as AP {",
      "    direction TD",
      "    parse --> done",
      "  }",
      "  处理中 --> AP",
      "  AP --> 完成",
      "  完成 --> [*]",
      "  linkStyle default stroke:#888",
    }, "\n")))

    assert.are.equal("LR", actual.direction)
    assert.are.equal("Waiting for input", actual.nodes.waiting.label)
    assert.are.equal("rounded", actual.nodes.waiting.shape)
    assert.are.equal("空闲", actual.nodes["空闲"].label)
    assert.are.equal("处理中", actual.nodes["处理中"].label)
    assert.are.equal("完成", actual.nodes["完成"].label)
    assert.are.equal("state-start", actual.nodes._start.shape)
    assert.are.equal("state-end", actual.nodes._end.shape)
    assert.are.equal("#888", actual.link_styles.default.stroke)
    assert.are.equal(1, #actual.subgraphs)
    assert.are.equal("AP", actual.subgraphs[1].id)
    assert.are.equal("Active Processing", actual.subgraphs[1].label)
    assert.are.equal("TD", actual.subgraphs[1].direction)
    assert.are.same({ "parse", "done" }, actual.subgraphs[1].node_ids)
    assert.are.equal("idle", actual.edges[2].label)
    assert.are.equal("提交", actual.edges[3].label)
    assert.are.same({}, actual.warnings)
  end)
end)
