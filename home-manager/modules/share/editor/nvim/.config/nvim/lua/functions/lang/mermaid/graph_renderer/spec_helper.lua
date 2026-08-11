if type(describe) ~= "function" then
  local spec_path = debug.getinfo(1, "S").source:sub(2)
  local lua_root = spec_path:match("^(.*)/functions/")
  local busted_lua_root = "/opt/homebrew/opt/busted/libexec/share/lua/5.5"
  local busted_c_root = "/opt/homebrew/opt/busted/libexec/lib/lua/5.5"

  package.path = table.concat({
    lua_root .. "/?.lua",
    lua_root .. "/?/init.lua",
    busted_lua_root .. "/?.lua",
    busted_lua_root .. "/?/init.lua",
    package.path,
  }, ";")

  package.cpath = table.concat({
    busted_c_root .. "/?.so",
    package.cpath,
  }, ";")

  require("busted.runner")()
end

local geometry = require("functions.lang.mermaid.graph_renderer.geometry")

local M = {}

function M.given_parsed_node(id, label, shape)
  return {
    id = id,
    label = label,
    shape = shape,
  }
end

function M.given_parsed_subgraph(id, label, kind, node_ids, children, direction)
  local actual = {}
  for _, node_id in ipairs(node_ids) do
    actual[node_id] = true
  end

  return {
    id = id,
    label = label,
    kind = kind,
    active_region = nil,
    node_ids = node_ids,
    node_id_set = actual,
    children = children or {},
    direction = direction,
  }
end

function M.given_simple_parsed_graph(direction)
  return {
    direction = direction or "TD",
    nodes = {
      A = M.given_parsed_node("A", "A", "rectangle"),
      B = M.given_parsed_node("B", "B", "rectangle"),
    },
    node_order = { "A", "B" },
    edges = {
      {
        source = "A",
        target = "B",
        label = "go",
        style = "solid",
        has_arrow_start = false,
        has_arrow_end = true,
      },
    },
    subgraphs = {},
    notes = {},
    class_defs = {},
    class_assignments = {},
    node_styles = {},
    link_styles = {},
    warnings = {},
  }
end

function M.given_empty_parsed_graph(direction)
  return {
    direction = direction,
    nodes = {},
    node_order = {},
    edges = {},
    subgraphs = {},
    notes = {},
    class_defs = {},
    class_assignments = {},
    node_styles = {},
    link_styles = {},
    warnings = {},
  }
end

function M.given_layout_config(graph_direction)
  return {
    padding_x = 5,
    padding_y = 5,
    box_border_padding = 1,
    graph_direction = graph_direction or "TD",
  }
end

function M.given_layout_node(name, label, shape, grid_coord, config)
  local actual = {
    name = name,
    display_label = label,
    shape = shape,
    index = 1,
    layout_direction = nil,
    dimensions = nil,
    grid_coord = grid_coord,
    drawing_coord = nil,
  }

  actual.dimensions = geometry.measure_node(actual, config)
  return actual
end

function M.given_layout_edge(from, to, text)
  return {
    from = from,
    to = to,
    text = text == nil and "go" or text,
    style = "solid",
    has_arrow_start = false,
    has_arrow_end = true,
    source_composite_id = nil,
    target_composite_id = nil,
    path = {},
    draw_path = nil,
    label_line = {},
    start_dir = geometry.Directions.middle,
    end_dir = geometry.Directions.middle,
    has_branch_label = nil,
    bundle = nil,
    path_to_junction = nil,
    start_attachment_override = nil,
    end_attachment_override = nil,
  }
end

function M.given_grid(nodes)
  local actual = {}

  for _, node in ipairs(nodes) do
    for dx = 0, 2 do
      for dy = 0, 2 do
        actual[geometry.grid_key({ x = node.grid_coord.x + dx, y = node.grid_coord.y + dy })] = node
      end
    end
  end

  return actual
end

function M.given_layout_graph(nodes, edges, graph_direction)
  local actual_graph_direction = graph_direction or "TD"

  return {
    nodes = nodes,
    edges = edges,
    subgraphs = {},
    subgraph_by_id = {},
    innermost_subgraph_by_node = {},
    notes = {},
    grid = M.given_grid(nodes),
    column_width = {},
    row_height = {},
    config = M.given_layout_config(actual_graph_direction),
    offset_x = 0,
    offset_y = 0,
    bundles = {},
    parsed_direction = actual_graph_direction,
    canvas_max_x = 0,
    canvas_max_y = 0,
  }
end

function M.given_route_graph()
  local actual_config = M.given_layout_config()
  local actual_from = M.given_layout_node("A", "A", "rectangle", { x = 0, y = 0 }, actual_config)
  local actual_to = M.given_layout_node("B", "B", "rectangle", { x = 0, y = 4 }, actual_config)

  return M.given_layout_graph({ actual_from, actual_to }, { M.given_layout_edge(actual_from, actual_to, "go") }, "TD")
end

return M
