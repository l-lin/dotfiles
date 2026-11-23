---Yank the selected text/line and unselect immediately, without exiting copy mode.
local function yank_and_unselect()
	rex.client.queue("pane.copy")
	-- Different modes ensure a selection exists before the final toggle clears it.
	rex.client.queue("pane.copy_mode.select", { mode = "char" })
	rex.client.queue("pane.copy_mode.select", { mode = "line" })
	rex.client.queue("pane.copy_mode.select", { mode = "line" })
end

rex.action({
	name = "copy_and_unselect",
	title = "Copy and clear selection",
	run = yank_and_unselect,
})
rex.bind("ctrl+q>b", "pane.copy_mode.enter")
rex.bind("copy/y", "copy_and_unselect")
rex.bind("ctrl+shift+c", "pane.copy")
rex.bind("ctrl+shift+v", "pane.paste")
