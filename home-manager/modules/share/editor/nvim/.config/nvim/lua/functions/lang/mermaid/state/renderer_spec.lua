local state_renderer = require("functions.lang.mermaid.state.renderer")
local testdata = require("functions.lang.mermaid.testdata")

describe("mermaid.state.renderer", function()
  local upstream_fixtures = {
    "state_basic",
    "state_cjk",
    "state_composite_lr",
    "state_composite_entry_exit",
    "state_composite_lr_note",
    "state_composite_named",
    "state_choice_basic",
    "state_choice_if_positive",
    "state_concurrency_regions",
    "state_fork_join_basic",
    "state_choice_parallel_battery",
  }

  for _, fixture_name in ipairs(upstream_fixtures) do
    it(
      string.format("GIVEN upstream fixture `%s` WHEN rendering THEN output matches the Unicode snapshot", fixture_name),
      function()
        local fixture = testdata.load_golden(fixture_name)

        local actual_lines = assert(state_renderer.render(fixture.mermaid))
        local actual = table.concat(actual_lines, "\n")
        local expected = fixture.expected

        assert.are.equal(testdata.normalize_whitespace(expected), testdata.normalize_whitespace(actual))
      end
    )
  end

  it(
    "GIVEN a simple lifecycle WHEN rendering state pseudostates THEN start and end stay round circles instead of boxed nodes",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  [*] --> Still",
        "  Still --> [*]",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local expected = { "●", "◉" }

      assert.are.same(expected[1], actual[1]:gsub("^%s+", ""))
      assert.are.same(expected[2], actual[#actual]:gsub("^%s+", ""))
    end
  )

  it(
    "GIVEN labelled branching state transitions WHEN rendering THEN the outgoing branch stays connected to the source state",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  direction LR",
        "  [*] --> Placed",
        "  Placed --> Paid : payment received",
        "  Placed --> Cancelled : customer cancels",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local actual_rendered = table.concat(actual, "\n")

      assert.is_truthy(actual_rendered:match("payment received"))
      assert.is_nil(actual_rendered:match("payment─received"))
      assert.is_nil(actual_rendered:match("Placed │        ├"))
    end
  )

  it(
    "GIVEN a multiline state note WHEN rendering THEN it renders the note text instead of appending unsupported warnings",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  [*] --> Paid",
        "  Paid --> [*]",
        "  note right of Paid",
        "    Payment can be card",
        "  end note",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local actual_rendered = table.concat(actual, "\n")

      assert.is_nil(actual_rendered:match("%[unsupported:"))
      assert.is_truthy(actual_rendered:match("Payment can be card"))
      assert.is_truthy(actual_rendered:match("┄"))
      assert.is_truthy(actual_rendered:match("┆"))
    end
  )

  it(
    "GIVEN choice concurrency fork and join syntax WHEN rendering THEN it stops appending unsupported warnings for those constructs",
    function()
      local source = table.concat({
        "stateDiagram",
        "  state route <<choice>>",
        "  state split <<fork>>",
        "  state merge <<join>>",
        "  [*] --> route",
        "  route --> split : yes",
        "  route --> merge : no",
        "  split --> merge",
        "  state Active {",
        "    [*] --> Left",
        "    --",
        "    [*] --> Right",
        "  }",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local actual_rendered = table.concat(actual, "\n")

      assert.is_nil(actual_rendered:match("%[unsupported:"))
      assert.is_truthy(actual_rendered:match("◇") or actual_rendered:match("◆"))
      assert.is_truthy(actual_rendered:match("━") or actual_rendered:match("┃"))
      assert.is_truthy(actual_rendered:match("┄") or actual_rendered:match("┆") or actual_rendered:match("┌"))
    end
  )

  it(
    "GIVEN an edge into and out of a composite state WHEN rendering THEN the external arrows attach to the composite border instead of directly to inner pseudostates",
    function()
      local source = table.concat({
        "stateDiagram-v2",
        "  direction LR",
        "  [*] --> Paid",
        "  Paid --> Fulfilment",
        "  state Fulfilment {",
        "    [*] --> Packing",
        "    Packing --> Shipped",
        "    Shipped --> [*]",
        "  }",
        "  Fulfilment --> Delivered",
        "  Delivered --> [*]",
      }, "\n")

      local actual = assert(state_renderer.render(source))
      local actual_rendered = table.concat(actual, "\n")

      assert.is_nil(actual_rendered:match("●"))
      assert.is_nil(actual_rendered:match("◉──┼"))
      assert.is_truthy(actual_rendered:match("Fulfilment"))
    end
  )
end)
