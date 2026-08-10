local sequence_parser = require("functions.lang.mermaid.sequence.parser")

describe("mermaid.sequence.parser", function()
  it(
    "GIVEN a sequence diagram with supported participants messages notes and blocks WHEN parsing THEN it keeps the upstream logical structure",
    function()
      local source = table.concat({
        "sequenceDiagram",
        "  participant API as API<br>Gateway",
        "  actor User",
        "  Note over User, API: Request<br>starts",
        "  User->>+API: Start request",
        "  alt cache hit",
        "    API-->>User: Cached result",
        "  else cache miss",
        "    API-xUser: Failure",
        "  end",
        "  Note right of API: Done",
        "  autonumber",
      }, "\n")
      local actual = assert(sequence_parser.parse(source))

      assert.are.same({
        { id = "API", label = "API\nGateway", type = "participant" },
        { id = "User", label = "User", type = "actor" },
      }, actual.actors)
      assert.are.equal(true, actual.actor_ids.API)
      assert.are.equal(true, actual.actor_ids.User)

      assert.are.equal("User", actual.messages[1].from)
      assert.are.equal("API", actual.messages[1].to)
      assert.are.equal("Start request", actual.messages[1].label)
      assert.are.equal("solid", actual.messages[1].line_style)
      assert.are.equal("filled", actual.messages[1].arrow_head)
      assert.are.equal(true, actual.messages[1].activate)
      assert.is_nil(actual.messages[1].deactivate)

      assert.are.equal("API", actual.messages[2].from)
      assert.are.equal("User", actual.messages[2].to)
      assert.are.equal("Cached result", actual.messages[2].label)
      assert.are.equal("dashed", actual.messages[2].line_style)
      assert.are.equal("filled", actual.messages[2].arrow_head)

      assert.are.equal("Failure", actual.messages[3].label)
      assert.are.equal("solid", actual.messages[3].line_style)
      assert.are.equal("filled", actual.messages[3].arrow_head)

      assert.are.same({
        {
          actor_ids = { "User", "API" },
          text = "Request\nstarts",
          position = "over",
          after_index = -1,
        },
        {
          actor_ids = { "API" },
          text = "Done",
          position = "right",
          after_index = 2,
        },
      }, actual.notes)

      assert.are.same({
        {
          type = "alt",
          label = "cache hit",
          start_index = 1,
          end_index = 2,
          dividers = {
            { index = 2, label = "cache miss" },
          },
        },
      }, actual.blocks)
      assert.are.same({ "autonumber" }, actual.warnings)
    end
  )
end)
