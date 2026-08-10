local graph_builder = require("functions.lang.mermaid.state.graph_builder")

local function given_graph(overrides)
  local actual = {
    nodes = {},
    node_order = {},
  }

  if overrides then
    for key, value in pairs(overrides) do
      actual[key] = value
    end
  end

  return actual
end

local function given_subgraph(overrides)
  local actual = {
    id = "group",
    label = "Group",
    node_ids = {},
    node_id_set = {},
    children = {},
  }

  if overrides then
    for key, value in pairs(overrides) do
      actual[key] = value
    end
  end

  return actual
end

describe("mermaid.state.graph_builder", function()
  it("GIVEN no current subgraph WHEN adding a node id to the current subgraph THEN it does nothing", function()
    local actual = {}

    graph_builder.add_node_to_current_subgraph(actual, "parse")

    local expected = {}
    assert.are.same(expected, actual)
  end)

  it("GIVEN a current subgraph WHEN adding a new node id THEN it records the id and membership set", function()
    local actual = { given_subgraph() }

    graph_builder.add_node_to_current_subgraph(actual, "parse")

    local expected = {
      given_subgraph({
        node_ids = { "parse" },
        node_id_set = { parse = true },
      }),
    }
    assert.are.same(expected, actual)
  end)

  it(
    "GIVEN a subgraph whose list already contains the node WHEN adding the same node id THEN it repairs the set without duplicating the list",
    function()
      local actual = {
        given_subgraph({
          node_ids = { "parse" },
        }),
      }

      graph_builder.add_node_to_current_subgraph(actual, "parse")

      local expected = {
        given_subgraph({
          node_ids = { "parse" },
          node_id_set = { parse = true },
        }),
      }
      assert.are.same(expected, actual)
    end
  )

  it(
    "GIVEN nested subgraphs WHEN adding a node id to the current subgraph THEN only the top subgraph is updated",
    function()
      local actual = {
        given_subgraph({ id = "outer", label = "Outer" }),
        given_subgraph({ id = "inner", label = "Inner" }),
      }

      graph_builder.add_node_to_current_subgraph(actual, "parse")

      local expected = {
        given_subgraph({ id = "outer", label = "Outer" }),
        given_subgraph({
          id = "inner",
          label = "Inner",
          node_ids = { "parse" },
          node_id_set = { parse = true },
        }),
      }
      assert.are.same(expected, actual)
    end
  )

  it("GIVEN a graph without the target node WHEN removing by id THEN it leaves the graph unchanged", function()
    local actual = given_graph({
      nodes = {
        done = { id = "done" },
      },
      node_order = { "done" },
    })

    graph_builder.remove_node_by_id(actual, "parse")

    local expected = given_graph({
      nodes = {
        done = { id = "done" },
      },
      node_order = { "done" },
    })
    assert.are.same(expected, actual)
  end)

  it("GIVEN duplicate order entries WHEN removing by id THEN it removes the node and every order entry", function()
    local actual = given_graph({
      nodes = {
        parse = { id = "parse" },
        done = { id = "done" },
      },
      node_order = { "parse", "done", "parse" },
    })

    graph_builder.remove_node_by_id(actual, "parse")

    local expected = given_graph({
      nodes = {
        done = { id = "done" },
      },
      node_order = { "done" },
    })
    assert.are.same(expected, actual)
  end)

  it(
    "GIVEN a new node and a current subgraph WHEN adding the node THEN it appends the node once and tracks it",
    function()
      local actual_graph = given_graph()
      local actual_subgraph_stack = { given_subgraph() }

      graph_builder.add_node(actual_graph, actual_subgraph_stack, {
        id = "parse",
        label = "Parse",
        shape = "rounded",
      })

      local expected_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Parse",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local expected_subgraph_stack = {
        given_subgraph({
          node_ids = { "parse" },
          node_id_set = { parse = true },
        }),
      }

      assert.are.same(expected_graph, actual_graph)
      assert.are.same(expected_subgraph_stack, actual_subgraph_stack)
    end
  )

  it("GIVEN a new node and no current subgraph WHEN adding the node THEN it only updates the graph", function()
    local actual_graph = given_graph()
    local actual_subgraph_stack = {}

    graph_builder.add_node(actual_graph, actual_subgraph_stack, {
      id = "parse",
      label = "Parse",
      shape = "rounded",
    })

    local expected_graph = given_graph({
      nodes = {
        parse = {
          id = "parse",
          label = "Parse",
          shape = "rounded",
        },
      },
      node_order = { "parse" },
    })
    local expected_subgraph_stack = {}

    assert.are.same(expected_graph, actual_graph)
    assert.are.same(expected_subgraph_stack, actual_subgraph_stack)
  end)

  it(
    "GIVEN an existing node WHEN adding the node again THEN it preserves the first definition and still tracks the current subgraph",
    function()
      local actual_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Original",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local actual_subgraph_stack = { given_subgraph() }

      graph_builder.add_node(actual_graph, actual_subgraph_stack, {
        id = "parse",
        label = "Replacement",
        shape = "diamond",
      })

      local expected_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Original",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local expected_subgraph_stack = {
        given_subgraph({
          node_ids = { "parse" },
          node_id_set = { parse = true },
        }),
      }

      assert.are.same(expected_graph, actual_graph)
      assert.are.same(expected_subgraph_stack, actual_subgraph_stack)
    end
  )

  it("GIVEN a missing node WHEN ensuring the node THEN it creates the default rounded node and tracks it", function()
    local actual_graph = given_graph()
    local actual_subgraph_stack = { given_subgraph() }

    graph_builder.ensure_node(actual_graph, actual_subgraph_stack, "parse")

    local expected_graph = given_graph({
      nodes = {
        parse = {
          id = "parse",
          label = "parse",
          shape = "rounded",
        },
      },
      node_order = { "parse" },
    })
    local expected_subgraph_stack = {
      given_subgraph({
        node_ids = { "parse" },
        node_id_set = { parse = true },
      }),
    }

    assert.are.same(expected_graph, actual_graph)
    assert.are.same(expected_subgraph_stack, actual_subgraph_stack)
  end)

  it(
    "GIVEN an existing node and a current subgraph WHEN ensuring the node THEN it tracks the node exactly once",
    function()
      local actual_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Parse",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local actual_subgraph_stack = {
        given_subgraph({
          node_ids = { "parse" },
        }),
      }

      graph_builder.ensure_node(actual_graph, actual_subgraph_stack, "parse")

      local expected_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Parse",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local expected_subgraph_stack = {
        given_subgraph({
          node_ids = { "parse" },
          node_id_set = { parse = true },
        }),
      }

      assert.are.same(expected_graph, actual_graph)
      assert.are.same(expected_subgraph_stack, actual_subgraph_stack)
    end
  )

  it(
    "GIVEN an existing node and no current subgraph WHEN ensuring the node THEN it keeps the graph unchanged",
    function()
      local actual_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Parse",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local actual_subgraph_stack = {}

      graph_builder.ensure_node(actual_graph, actual_subgraph_stack, "parse")

      local expected_graph = given_graph({
        nodes = {
          parse = {
            id = "parse",
            label = "Parse",
            shape = "rounded",
          },
        },
        node_order = { "parse" },
      })
      local expected_subgraph_stack = {}

      assert.are.same(expected_graph, actual_graph)
      assert.are.same(expected_subgraph_stack, actual_subgraph_stack)
    end
  )
end)
