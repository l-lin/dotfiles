local parser = require("functions.lang.mermaid.parser")
local state_parser = require("functions.lang.mermaid.state.parser")

describe("mermaid.state.parser", function()
  it("GIVEN an invalid state diagram WHEN parsing THEN it returns an error", function()
    local actual, err = state_parser.parse({})

    assert.is_nil(actual)
    assert.are.equal("Invalid state diagram: missing 'stateDiagram' or 'stateDiagram-v2' header", err)
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
      assert.are.same({}, actual.notes)
      assert.are.same({}, actual.warnings)
    end
  )

  it(
    "GIVEN a multiline state note WHEN parsing THEN it records the note instead of treating it as unsupported syntax",
    function()
      local lines = parser.preprocess_source(table.concat({
        "stateDiagram-v2",
        "  [*] --> Paid",
        "  Paid --> [*]",
        "  note right of Paid",
        "    Payment can be card,",
        "    wallet, or bank transfer",
        "  end note",
      }, "\n"))
      local actual, err = assert(state_parser.parse(lines))
      local expected = {
        {
          position = "right",
          state_id = "Paid",
          text = "Payment can be card,\nwallet, or bank transfer",
        },
      }

      assert.is_nil(err)
      assert.are.same(expected, actual.notes)
      assert.are.same({}, actual.warnings)
    end
  )

  it(
    "GIVEN stateDiagram pseudostates WHEN parsing THEN it records choice fork and join nodes without unsupported warnings",
    function()
      local lines = parser.preprocess_source(table.concat({
        "stateDiagram",
        "  state route <<choice>>",
        "  state split <<fork>>",
        "  state merge <<join>>",
        "  [*] --> route",
        "  route --> split",
        "  split --> merge",
        "  merge --> [*]",
      }, "\n"))
      local actual, err = assert(state_parser.parse(lines))

      assert.is_nil(err)
      assert.are.equal("state-choice", actual.nodes.route.shape)
      assert.are.equal("", actual.nodes.route.label)
      assert.are.equal("state-fork", actual.nodes.split.shape)
      assert.are.equal("", actual.nodes.split.label)
      assert.are.equal("state-join", actual.nodes.merge.shape)
      assert.are.equal("", actual.nodes.merge.label)
      assert.are.same({}, actual.warnings)
    end
  )

  it(
    "GIVEN a composite state with concurrent regions WHEN parsing THEN it records explicit region children in source order",
    function()
      local lines = parser.preprocess_source(table.concat({
        "stateDiagram",
        "  state Active {",
        "    direction LR",
        "    [*] --> Playing",
        "    Playing --> Paused : pause",
        "    Paused --> Playing : play",
        "    --",
        "    [*] --> ScreenOn",
        "    ScreenOn --> ScreenDimmed : idle 30s",
        "    ScreenDimmed --> ScreenOn : touch",
        "  }",
      }, "\n"))
      local actual, err = assert(state_parser.parse(lines))
      local expected_regions = {
        {
          kind = "region",
          node_ids = { "_start", "Playing", "Paused" },
          direction = nil,
        },
        {
          kind = "region",
          node_ids = { "_start2", "ScreenOn", "ScreenDimmed" },
          direction = nil,
        },
      }

      assert.is_nil(err)
      assert.are.equal("LR", actual.subgraphs[1].direction)
      assert.are.same({}, actual.subgraphs[1].node_ids)
      assert.are.same(expected_regions[1].kind, actual.subgraphs[1].children[1].kind)
      assert.are.same(expected_regions[1].node_ids, actual.subgraphs[1].children[1].node_ids)
      assert.are.same(expected_regions[1].direction, actual.subgraphs[1].children[1].direction)
      assert.are.same(expected_regions[2].kind, actual.subgraphs[1].children[2].kind)
      assert.are.same(expected_regions[2].node_ids, actual.subgraphs[1].children[2].node_ids)
      assert.are.same(expected_regions[2].direction, actual.subgraphs[1].children[2].direction)
      assert.are.same({}, actual.warnings)
    end
  )
end)
