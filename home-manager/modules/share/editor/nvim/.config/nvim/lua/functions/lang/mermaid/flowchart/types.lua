---@class dotfiles.mermaid.flowchart.ConsumeNodeResult
---@field id string The identifier of the consumed node.
---@field remaining string The remaining text after consuming the node.


---@class dotfiles.mermaid.flowchart.ConsumeNodeGroupResult
---@field ids string[] The identifiers of the consumed nodes in the group.
---@field remaining string The remaining text after consuming the node group.


---@class dotfiles.mermaid.flowchart.ConsumeArrowResult
---@field label string|nil The label of the consumed arrow, or nil if no label was present.
---@field style string The style of the consumed arrow ("dotted", "thick", or "solid").
---@field has_arrow_start boolean Indicates whether the arrow has a start marker ("<").
---@field has_arrow_end boolean Indicates whether the arrow has an end marker (">").
---@field remaining string The remaining text after consuming the arrow.


---@class dotfiles.mermaid.flowchart.Graph
---@field direction string The direction of the graph (e.g., "TD", "LR").
---@field nodes table<string, table> A table of nodes
---@field node_order string[] An array of node IDs in the order they were added.@field node_order string[] An array of node identifiers in the order they were added.
---@field edges table[] An array of edges, where each edge is a table containing source, target, label, style, has_arrow_start, and has_arrow_end fields.
---@field subgraphs table[] An array of subgraphs, where each subgraph is a table
---@field class_defs table<string, table> A table of class definitions, where each key is a class name and the value is a table of style properties.
---@field class_assignments table<string, string> A table of class assignments, where each key
---@field node_styles table<string, table> A table of node styles, where each key is a node ID and the value is a table of style properties.
---@field link_styles table A table of link styles, where each key is a link index and the value is a table of style properties.
---@field warnings string[] An array of warning messages encountered during parsing.

