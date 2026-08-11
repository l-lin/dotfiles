---@meta

---@alias dotfiles.mermaid.graph_renderer.GraphDirection "LR"|"TD"
---@alias dotfiles.mermaid.graph_renderer.LineStyle "solid"|"dotted"|"thick"
---@alias dotfiles.mermaid.graph_renderer.NotePosition "left"|"right"
---@alias dotfiles.mermaid.graph_renderer.BundleType "fan-in"|"fan-out"
---@alias dotfiles.mermaid.graph_renderer.DirectionId
---| "up"
---| "down"
---| "left"
---| "right"
---| "upper_right"
---| "upper_left"
---| "lower_right"
---| "lower_left"
---| "middle"
---@alias dotfiles.mermaid.graph_renderer.NodeShape
---| "rectangle"
---| "rounded"
---| "circle"
---| "doublecircle"
---| "diamond"
---| "hexagon"
---| "stadium"
---| "subroutine"
---| "cylinder"
---| "asymmetric"
---| "trapezoid"
---| "trapezoid-alt"
---| "state-start"
---| "state-end"
---| "state-choice"
---| "state-fork"
---| "state-join"
---| string
---@alias dotfiles.mermaid.graph_renderer.ParsedGraph dotfiles.mermaid.flowchart.Graph|dotfiles.mermaid.state.Graph
---@alias dotfiles.mermaid.graph_renderer.GridPath dotfiles.mermaid.graph_renderer.GridCoord[]
---@alias dotfiles.mermaid.graph_renderer.DrawingPath dotfiles.mermaid.graph_renderer.DrawingCoord[]
---@alias dotfiles.mermaid.graph_renderer.DrawingLine dotfiles.mermaid.graph_renderer.DrawingCoord[]
---@alias dotfiles.mermaid.Canvas table<integer, table<integer, string>>

---@class dotfiles.mermaid.graph_renderer.Direction
---@field id dotfiles.mermaid.graph_renderer.DirectionId the direction identifier
---@field x integer the x-axis offset for the direction
---@field y integer the y-axis offset for the direction

---@class dotfiles.mermaid.graph_renderer.GridCoord
---@field x integer the x-axis grid coordinate, where (0, 0) is the top-left corner of the graph layout.
---@field y integer the y-axis grid coordinate, where (0, 0) is the top-left corner of the graph layout.

---@class dotfiles.mermaid.graph_renderer.DrawingCoord
---@field x integer the x-axis drawing coordinate, where (0, 0) is the top-left corner of the graph layout.
---@field y integer the y-axis drawing coordinate, where (0, 0) is the top-left corner of the graph layout.

---A positioned text fragment for multi-line edge labels.
---@class dotfiles.mermaid.graph_renderer.LabelPoint : dotfiles.mermaid.graph_renderer.DrawingCoord
---@field text string the label line to draw at this coordinate.

---@class dotfiles.mermaid.graph_renderer.RendererConfig
---@field padding_x integer the horizontal padding between nodes and edges in the rendered graph.
---@field padding_y integer the vertical padding between nodes and edges in the rendered graph.
---@field box_border_padding integer the padding between the node content and the box border in the rendered graph.
---@field graph_direction dotfiles.mermaid.graph_renderer.GraphDirection the overall direction of the graph layout, either "LR" (left-to-right) or "TD" (top-to-bottom).

---@class dotfiles.mermaid.graph_renderer.NodeDimensions
---@field width integer Character width of the rendered node box, not the zero-based canvas max-x.
---@field height integer Character height of the rendered node box, not the zero-based canvas max-y.
---@field grid_columns integer[] Width budget for the node's left/middle/right grid cells.
---@field grid_rows integer[] Height budget for the node's top/middle/bottom grid cells.

---@class dotfiles.mermaid.graph_renderer.CornerGlyphs
---@field tl string the top-left corner glyph for the node box
---@field tr string the top-right corner glyph for the node box
---@field bl string the bottom-left corner glyph for the node box
---@field br string the bottom-right corner glyph for the node box

---@class dotfiles.mermaid.graph_renderer.LineGlyphs
---@field h string the horizontal line glyph for the node box
---@field v string the vertical line glyph for the node box

---@class dotfiles.mermaid.graph_renderer.NormalizedNode
---@field name string Stable renderer identifier. Matches the parser node id.
---@field display_label string Human-facing label already normalized by the parser.
---@field shape dotfiles.mermaid.graph_renderer.NodeShape
---@field index integer Definition order from the parser.

---@class dotfiles.mermaid.graph_renderer.NormalizedSubgraph
---@field id string the subgraph's unique identifier
---@field name string the subgraph's label
---@field kind string|nil the kind of subgraph (e.g., "subgraph", "cluster")
---@field parent dotfiles.mermaid.graph_renderer.NormalizedSubgraph|nil the parent subgraph, or nil if this is a top-level subgraph
---@field children dotfiles.mermaid.graph_renderer.NormalizedSubgraph[] the child subgraphs of this subgraph
---@field nodes dotfiles.mermaid.graph_renderer.NormalizedNode[] the nodes contained within this subgraph
---@field direction dotfiles.mermaid.graph_renderer.GraphDirection|nil the direction of the subgraph (e.g., "LR", "TD"), or nil if it inherits the graph's direction
---@field depth integer the depth of the subgraph in the hierarchy, where 0 is a top-level subgraph

---@class dotfiles.mermaid.graph_renderer.NormalizedEdge
---@field from dotfiles.mermaid.graph_renderer.NormalizedNode the source node of the edge
---@field to dotfiles.mermaid.graph_renderer.NormalizedNode the target node of the edge
---@field text string the label text of the edge, if any
---@field style dotfiles.mermaid.graph_renderer.LineStyle the style of the edge line (e.g., "solid", "dotted", "thick")
---@field has_arrow_start boolean true if the edge has an arrowhead at the start (source) node, false otherwise
---@field has_arrow_end boolean true if the edge has an arrowhead at the end (target) node, false otherwise
---@field source_composite_id string|nil Original composite source id when an external edge was remapped to an inner anchor node.
---@field target_composite_id string|nil Original composite target id when an external edge was remapped to an inner anchor node.

---@class dotfiles.mermaid.graph_renderer.NormalizedNote
---@field node dotfiles.mermaid.graph_renderer.NormalizedNode the node to which the note is attached
---@field position dotfiles.mermaid.graph_renderer.NotePosition the position of the note relative to the node ("left" or "right")
---@field text string the text content of the note

---@class dotfiles.mermaid.graph_renderer.NormalizedGraph
---@field nodes dotfiles.mermaid.graph_renderer.NormalizedNode[] the list of normalized nodes in the graph
---@field edges dotfiles.mermaid.graph_renderer.NormalizedEdge[] the list of normalized edges in the graph
---@field subgraphs dotfiles.mermaid.graph_renderer.NormalizedSubgraph[] the list of normalized subgraphs in the graph
---@field subgraph_by_id table<string, dotfiles.mermaid.graph_renderer.NormalizedSubgraph> the mapping of subgraph IDs to their corresponding normalized subgraph objects
---@field innermost_subgraph_by_node table<dotfiles.mermaid.graph_renderer.NormalizedNode, dotfiles.mermaid.graph_renderer.NormalizedSubgraph> the mapping of normalized nodes to their innermost containing subgraph
---@field notes dotfiles.mermaid.graph_renderer.NormalizedNote[] the list of normalized notes in the graph
---@field config dotfiles.mermaid.graph_renderer.RendererConfig the configuration settings for the graph renderer
---@field parsed_direction string the parsed direction of the graph, either "LR" or "TD"

---@class dotfiles.mermaid.graph_renderer.LayoutNode : dotfiles.mermaid.graph_renderer.NormalizedNode
---@field layout_direction dotfiles.mermaid.graph_renderer.GraphDirection|nil the layout direction of the node, either "LR" or "TD", or nil if it inherits the graph's direction
---@field dimensions dotfiles.mermaid.graph_renderer.NodeDimensions|nil the dimensions of the node, including width, height, and grid cell sizes
---@field grid_coord dotfiles.mermaid.graph_renderer.GridCoord|nil the grid coordinate of the node in the layout, where (0, 0) is the top-left corner of the graph layout
---@field drawing_coord dotfiles.mermaid.graph_renderer.DrawingCoord|nil the drawing coordinate of the node in the rendered graph, where (0, 0) is the top-left corner of the graph layout

---@class dotfiles.mermaid.graph_renderer.LayoutSubgraph
---@field id string the subgraph's unique identifier
---@field name string the subgraph's label
---@field kind string|nil the kind of subgraph (e.g., "subgraph", "cluster")
---@field parent dotfiles.mermaid.graph_renderer.LayoutSubgraph|nil the parent subgraph, or nil if this is a top-level subgraph
---@field children dotfiles.mermaid.graph_renderer.LayoutSubgraph[] the child subgraphs of this subgraph
---@field nodes dotfiles.mermaid.graph_renderer.LayoutNode[] the nodes contained within this subgraph
---@field direction dotfiles.mermaid.graph_renderer.GraphDirection|nil the direction of the subgraph (e.g., "LR", "TD"), or nil if it inherits the graph's direction
---@field depth integer the depth of the subgraph in the hierarchy, where 0 is a top-level subgraph
---@field min_x integer the minimum x-coordinate of the subgraph's bounding box in the layout
---@field min_y integer the minimum y-coordinate of the subgraph's bounding box in the layout
---@field max_x integer the maximum x-coordinate of the subgraph's bounding box in the layout
---@field max_y integer the maximum y-coordinate of the subgraph's bounding box in the layout

---@class dotfiles.mermaid.graph_renderer.EdgeBundle
---@field type dotfiles.mermaid.graph_renderer.BundleType the type of edge bundle, either "fan-in" or "fan-out"
---@field edges dotfiles.mermaid.graph_renderer.LayoutEdge[] the list of edges included in the bundle
---@field shared_node dotfiles.mermaid.graph_renderer.LayoutNode the shared node where the bundled edges converge or diverge
---@field other_nodes dotfiles.mermaid.graph_renderer.LayoutNode[] the list of other nodes connected to the shared node in the bundle
---@field junction_point dotfiles.mermaid.graph_renderer.GridCoord|nil the grid coordinate of the junction point where the bundled edges meet, or nil if not applicable
---@field shared_path dotfiles.mermaid.graph_renderer.GridPath the shared path of the bundled edges, represented as a sequence of grid coordinates
---@field junction_dir dotfiles.mermaid.graph_renderer.Direction the direction of the junction point in the bundle, indicating how the edges connect to the shared node
---@field shared_node_dir dotfiles.mermaid.graph_renderer.Direction the direction of the shared node in the bundle, indicating how the edges connect to the other nodes

---@class dotfiles.mermaid.graph_renderer.LayoutEdge : dotfiles.mermaid.graph_renderer.NormalizedEdge
---@field from dotfiles.mermaid.graph_renderer.LayoutNode the source node of the edge
---@field to dotfiles.mermaid.graph_renderer.LayoutNode the target node of the edge
---@field path dotfiles.mermaid.graph_renderer.GridPath the path of the edge in the layout, represented as a sequence of grid coordinates
---@field draw_path dotfiles.mermaid.graph_renderer.GridPath|nil the path of the edge for drawing purposes, represented as a sequence of grid coordinates, or nil if not applicable
---@field label_line dotfiles.mermaid.graph_renderer.GridPath the path of the edge label in the layout, represented as a sequence of grid coordinates
---@field start_dir dotfiles.mermaid.graph_renderer.Direction the direction of the edge at the start node, indicating how the edge connects to the source node
---@field end_dir dotfiles.mermaid.graph_renderer.Direction the direction of the edge at the end node, indicating how the edge connects to the target node
---@field has_branch_label boolean|nil true if the edge has a branch label, false if it does not, or nil if not applicable
---@field bundle dotfiles.mermaid.graph_renderer.EdgeBundle|nil the edge bundle that this edge belongs to, or nil if the edge is not part of a bundle
---@field path_to_junction dotfiles.mermaid.graph_renderer.GridPath|nil the path from the edge's start node to the junction point in the bundle, represented as a sequence of grid coordinates, or nil if not applicable
---@field start_attachment_override dotfiles.mermaid.graph_renderer.DrawingCoord|nil the drawing coordinate to override the start attachment point of the edge, or nil if not applicable
---@field end_attachment_override dotfiles.mermaid.graph_renderer.DrawingCoord|nil the drawing coordinate to override the end attachment point of the edge, or nil if not applicable

---@class dotfiles.mermaid.graph_renderer.LayoutNote : dotfiles.mermaid.graph_renderer.NormalizedNote
---@field node dotfiles.mermaid.graph_renderer.LayoutNode the node to which the note is attached
---@field width integer|nil the width of the note in characters, or nil if not applicable
---@field height integer|nil the height of the note in characters, or nil if not applicable
---@field offset dotfiles.mermaid.graph_renderer.DrawingCoord|nil the offset of the note relative to the node in drawing coordinates, or nil if not applicable

---@class dotfiles.mermaid.graph_renderer.LayoutGraph
---@field nodes dotfiles.mermaid.graph_renderer.LayoutNode[] the list of layout nodes in the graph
---@field edges dotfiles.mermaid.graph_renderer.LayoutEdge[] the list of layout edges in the graph
---@field subgraphs dotfiles.mermaid.graph_renderer.LayoutSubgraph[] the list of layout subgraphs in the graph
---@field subgraph_by_id table<string, dotfiles.mermaid.graph_renderer.LayoutSubgraph> the mapping of subgraph IDs to their corresponding layout subgraph objects
---@field innermost_subgraph_by_node table<dotfiles.mermaid.graph_renderer.LayoutNode, dotfiles.mermaid.graph_renderer.LayoutSubgraph> the mapping of layout nodes to their innermost containing subgraph
---@field notes dotfiles.mermaid.graph_renderer.LayoutNote[] the list of layout notes in the graph
---@field grid table<string, dotfiles.mermaid.graph_renderer.LayoutNode> the grid mapping of layout coordinates to layout nodes, where the key is a string representation of the grid coordinate (e.g., "x,y") and the value is the corresponding layout node
---@field column_width table<integer, integer> the mapping of column indices to their respective widths in characters, where the key is the column index and the value is the width of that column
---@field row_height table<integer, integer> the mapping of row indices to their respective heights in characters, where the key is the row index and the value is the height of that row
---@field config dotfiles.mermaid.graph_renderer.RendererConfig the configuration settings for the graph renderer
---@field offset_x integer the x-axis offset for the entire graph layout, used to adjust the position of all nodes and edges in the rendered output
---@field offset_y integer the y-axis offset for the entire graph layout, used to adjust the position of all nodes and edges in the rendered output
---@field bundles dotfiles.mermaid.graph_renderer.EdgeBundle[] the list of edge bundles in the graph, where each bundle groups edges that share a common junction point
---@field parsed_direction string the parsed direction of the graph, either "LR" or "TD"
---@field canvas_max_x integer the maximum x-coordinate of the canvas in characters, representing the width of the rendered graph
---@field canvas_max_y integer the maximum y-coordinate of the canvas in characters, representing the height of the rendered graph

---@class dotfiles.mermaid.graph_renderer.HeapItem
---@field coord dotfiles.mermaid.graph_renderer.GridCoord the grid coordinate of the item in the heap
---@field priority integer the priority value of the item, used for ordering in the heap
