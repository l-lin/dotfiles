local parser = require("functions.lang.mermaid.parser")
local flowchart_parser = require("functions.lang.mermaid.flowchart.parser")

describe("mermaid.parser.parse_mermaid", function()
  it("GIVEN a flowchart with upstream-supported metadata WHEN parsing THEN it keeps graph structure and style metadata", function()
    local lines = parser.preprocess_source(table.concat({
      "flowchart TD",
      "  classDef hot fill:#f96,stroke:#333",
      "  A[Start]:::hot -- Yes --> B{Check}",
      "  subgraph api [API<br>Layer]",
      "    direction LR",
      "    B --> C[(Store)]",
      "  end",
      "  style C fill:#0f0",
      "  linkStyle 0 stroke:#ff0000,stroke-width:2px",
    }, "\n"))
    local actual = assert(flowchart_parser.parse(lines))

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
end)

