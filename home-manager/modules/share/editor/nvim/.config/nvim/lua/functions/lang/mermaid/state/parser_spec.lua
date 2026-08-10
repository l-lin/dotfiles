local parser = require("functions.lang.mermaid.parser")
local state_parser = require("functions.lang.mermaid.state.parser")

describe("mermaid.state.parser", function()
  it("GIVEN an invalid state diagram WHEN parsing THEN it returns an error", function()
    local actual, err = state_parser.parse({})

    assert.is_nil(actual)
    assert.are.equal("Invalid state diagram: missing 'stateDiagram-v2' header", err)
  end)

  it(
    "GIVEN a state diagram with aliases composites and CJK names WHEN parsing THEN it mirrors the upstream logical model",
    function()
      local lines = parser.preprocess_source(table.concat({
        "stateDiagram-v2",
        "  direction LR",
        '  state "Waiting for input" as waiting',
        "  [*] --> waiting",
        "  waiting --> 空闲 : idle",
        "  空闲 --> 处理中 : 提交",
        '  state "Active Processing" as AP {',
        "    direction TD",
        "    parse --> done",
        "  }",
        "  处理中 --> AP",
        "  AP --> 完成",
        "  完成 --> [*]",
        "  linkStyle default stroke:#888",
      }, "\n"))
      local actual, err = assert(state_parser.parse(lines))

      assert.is_nil(err)
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
    end
  )
end)
