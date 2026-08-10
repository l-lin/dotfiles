local graph_renderer = require("functions.lang.mermaid.graph_renderer")
local parser = require("functions.lang.mermaid.parser")
local flowchart_parser = require("functions.lang.mermaid.flowchart.parser")

local function render(source)
  if parser.diagram_kind(source) ~= "flowchart" then
    return nil, "unsupported diagram kind"
  end

  local lines = parser.preprocess_source(source)
  if #lines == 0 then
    return nil, "Empty mermaid diagram"
  end

  local graph, parse_error = flowchart_parser.parse(lines)
  if not graph then
    return nil, parse_error
  end

  lines = graph_renderer.render_graph(graph)
  parser.append_unsupported_lines(lines, graph.warnings)
  return lines
end

local M = {}
M.render = render
return M
