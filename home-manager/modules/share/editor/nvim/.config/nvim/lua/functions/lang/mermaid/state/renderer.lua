local graph_renderer = require("functions.lang.mermaid.graph_renderer")
local parser = require("functions.lang.mermaid.parser")
local state_parser = require("functions.lang.mermaid.state.parser")

---Renders a Mermaid state diagram source into a list of lines representing
---the rendered output.
---@param source string the Mermaid state diagram source code
---@return string[]|nil a list of lines representing the rendered output, or nil if an error occurred
---@return string|nil an error message if an error occurred, or nil if successful
local function render(source)
  if parser.diagram_kind(source) ~= "state" then
    return nil, "unsupported diagram kind"
  end

  local lines = parser.preprocess_source(source)
  if #lines == 0 then
    return nil, "Empty mermaid diagram"
  end

  local graph, parse_error = state_parser.parse(lines)
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
