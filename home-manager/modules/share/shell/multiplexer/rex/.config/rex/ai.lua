local terminal = "com.superlogical.terminal"

---Opens a new agent pane or window, using the current process's working directory.
---@param ctx rex.action_context
---@param args { placement: "horizontal" | "vertical" | "window", agent: "claude" | "pi" }
---@return rex.layout.block
local function open_agent(ctx, args)
	local process, err = rex.block.call(terminal, "process", { block_id = ctx.block_id })
	if not process then
		error(err, 0)
	end

	local cwd = process.foreground and process.foreground.cwd
		or process.ancestors and process.ancestors[1] and process.ancestors[1].cwd
		or process.home
	local agent = args.agent
	local command = agent == "claude" and "exec /opt/homebrew/bin/claude" or 'exec "$HOME/.local/share/mise/shims/pi"'

	local layout = rex.layout.block({
		flavor = "com.superlogical.terminal.shell",
		options = { cwd = cwd, shell = "none", command = { "zsh", "-ic", command } },
	})

	local result
	if args.placement == "window" then
		result, err = rex.session.new_window({
			session_id = ctx.session_id,
			window_label = agent,
			layout = layout,
			focus = true,
		})
	else
		result, err = rex.session.new_split({
			session_id = ctx.session_id,
			anchor_id = ctx.block_id,
			-- Keep the original focus until the app moves it to the adjacent pane.
			direction = args.placement,
			side = "after",
			layout = layout,
			focus = false,
		})
	end
	if not result then
		error(err, 0)
	end
	if args.placement == "window" then
		rex.client.queue("session.select", { session_id = ctx.session_id, window_id = result.window_id })
	else
		rex.client.queue("pane.focus", {
			direction = args.placement == "horizontal" and "right" or "down",
			wrap = false,
		})
	end
	return result
end

-- Agent panes use the focused process directory, including inside an agent.
rex.action({
	name = "open_agent",
	title = "Open AI Agent...",
	args = {
		type = "object",
		properties = {
			placement = { type = "string", enum = { "horizontal", "vertical", "window" } },
			agent = { type = "string", enum = { "claude", "pi" } },
		},
		required = { "placement", "agent" },
		additionalProperties = false,
	},
	run = open_agent,
})

rex.bind("ctrl+q>shift+v>c", "open_agent", { placement = "horizontal", agent = "claude" })
rex.bind("ctrl+q>shift+v>p", "open_agent", { placement = "horizontal", agent = "pi" })
rex.bind("ctrl+q>shift+s>c", "open_agent", { placement = "vertical", agent = "claude" })
rex.bind("ctrl+q>shift+s>p", "open_agent", { placement = "vertical", agent = "pi" })
rex.bind("ctrl+q>shift+c>c", "open_agent", { placement = "window", agent = "claude" })
rex.bind("ctrl+q>shift+c>p", "open_agent", { placement = "window", agent = "pi" })
