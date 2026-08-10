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
      assert.are.equal("API", actual.messages[1].activate_actor)
      assert.is_nil(actual.messages[1].deactivate)
      assert.is_nil(actual.messages[1].deactivate_actor)

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
      assert.are.same({
        { type = "note", note_index = 1 },
        { type = "message", message_index = 1 },
        { type = "block_start", block = actual.blocks[1] },
        { type = "message", message_index = 2 },
        { type = "block_divider", block = actual.blocks[1], divider = actual.blocks[1].dividers[1] },
        { type = "message", message_index = 3 },
        { type = "block_end", block = actual.blocks[1] },
        { type = "note", note_index = 2 },
      }, actual.events)
      assert.are.same({ "autonumber" }, actual.warnings)
    end
  )

  it(
    "GIVEN explicit activation lines and inline deactivation WHEN parsing THEN activation ownership and event order match Mermaid semantics",
    function()
      local source = table.concat({
        "sequenceDiagram",
        "  participant Client",
        "  participant API",
        "  Client->>+API: Start",
        "  activate API",
        "  API-->>-Client: Done",
        "  deactivate API",
      }, "\n")
      local actual = assert(sequence_parser.parse(source))

      assert.are.equal("API", actual.messages[1].activate_actor)
      assert.are.equal(true, actual.messages[1].activate)
      assert.is_nil(actual.messages[1].deactivate_actor)

      assert.are.equal("API", actual.messages[2].deactivate_actor)
      assert.are.equal(true, actual.messages[2].deactivate)
      assert.is_nil(actual.messages[2].activate_actor)

      assert.are.same({
        { type = "message", message_index = 1 },
        { type = "activation", action = "activate", actor_id = "API" },
        { type = "message", message_index = 2 },
        { type = "activation", action = "deactivate", actor_id = "API" },
      }, actual.events)
      assert.are.same({}, actual.warnings)
    end
  )
end)
