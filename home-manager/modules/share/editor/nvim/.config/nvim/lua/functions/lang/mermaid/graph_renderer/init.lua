local normalize = require("functions.lang.mermaid.graph_renderer.normalize")
local layout = require("functions.lang.mermaid.graph_renderer.layout")
local draw = require("functions.lang.mermaid.graph_renderer.draw")

---Shared Mermaid graph renderer.
---
---Pipeline:
---1. normalize parser output into renderer-friendly graph data
---2. compute layout/routing/bounds in explicit stage state
---3. draw the prepared layout without making new layout decisions
---@param parsed dotfiles.mermaid.graph_renderer.ParsedGraph the parsed graph data from the Mermaid parser
---@return string[] the rendered graph as an array of strings, each string representing a line of the rendered graph
local function render_graph(parsed)
  local normalized = normalize.from_parsed(parsed)
  local prepared_layout = layout.prepare_layout(normalized)
  return draw.render(prepared_layout)
end

local M = {}
M.render_graph = render_graph
return M
