local graph_renderer = require("functions.lang.mermaid.graph_renderer")
local parser = require("functions.lang.mermaid.parser")

local function render(source)
  if parser.diagram_kind(source) ~= "flowchart" then
    return nil, "unsupported diagram kind"
  end

  -- TODO: move parse_mermaid here
  local graph, parse_error = parser.parse_mermaid(source)
  if not graph then
    return nil, parse_error
  end

  local lines = graph_renderer.render_graph(graph)
  parser.append_unsupported_lines(lines, graph.warnings)
  return lines
end

local M = {}
M.render = render
return M
