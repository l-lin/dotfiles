-- Prefix and configuration
rex.bind("ctrl+q>r", "client.config.reload")

-- Sessions
rex.bind("ctrl+q>shift+9", "session.previous") -- ko
rex.bind("ctrl+q>shift+0", "session.next") -- ko
rex.bind("ctrl+q>shift+l", "session.back") -- ko
rex.bind("ctrl+q>ctrl+shift+6", "session.back") -- ko
rex.bind("ctrl+q>shift+4", "session.rename") -- c-$

-- Tabs
rex.bind("ctrl+q>c", "client.tab.new")
rex.bind("ctrl+q>n", "client.tab.next")
rex.bind("ctrl+q>p", "client.tab.previous")
rex.bind("ctrl+q>l", "client.tab.back.in_session") -- KO
rex.bind("ctrl+q>,", "client.tab.rename")
rex.bind("ctrl+q>1", "client.tab.goto", { index = 1 })
rex.bind("ctrl+q>2", "client.tab.goto", { index = 2 })
rex.bind("ctrl+q>3", "client.tab.goto", { index = 3 })
rex.bind("ctrl+q>4", "client.tab.goto", { index = 4 })
rex.bind("ctrl+q>5", "client.tab.goto", { index = 5 })
rex.bind("ctrl+q>6", "client.tab.goto", { index = 6 })
rex.bind("ctrl+q>7", "client.tab.goto", { index = 7 })
rex.bind("ctrl+q>8", "client.tab.goto", { index = 8 })
rex.bind("ctrl+q>9", "client.tab.goto", { index = 9 })

-- Pane layout
rex.bind("ctrl+q>v", "pane.split", { direction = "right" })
rex.bind("ctrl+q>s", "pane.split", { direction = "down" })
rex.bind("ctrl+q>shift+5", "pane.split", { direction = "right" })
rex.bind("ctrl+q>shift+'", "pane.split", { direction = "down" })
rex.bind("ctrl+q>shift+1", "pane.move_to_new_tab")
rex.bind("ctrl+q>x", "pane.close")
rex.bind("ctrl+q>z", "pane.zoom")
rex.bind("ctrl+q>ctrl+left", "pane.resize", { direction = "left" })
rex.bind("ctrl+q>ctrl+down", "pane.resize", { direction = "down" })
rex.bind("ctrl+q>ctrl+up", "pane.resize", { direction = "up" })
rex.bind("ctrl+q>ctrl+right", "pane.resize", { direction = "right" })
rex.bind("ctrl+q>shift+[", "pane.move.left")
rex.bind("ctrl+q>shift+]", "pane.move.right")
rex.bind("ctrl+q>alt+1", "pane.balance")

-- Pane focus
rex.bind("ctrl+q>left", "pane.focus.left")
rex.bind("ctrl+q>down", "pane.focus.down")
rex.bind("ctrl+q>up", "pane.focus.up")
rex.bind("ctrl+q>right", "pane.focus.right")
rex.bind("ctrl+q>o", "pane.focus_next")
rex.bind("ctrl+q>;", "pane.focus_back.in_tab") -- ko
rex.bind("ctrl+alt+h", "pane.focus.left")
rex.bind("ctrl+alt+j", "pane.focus.down")
rex.bind("ctrl+alt+k", "pane.focus.up")
rex.bind("ctrl+alt+l", "pane.focus.right")
-- requires to enable `Go to Anything` from `Settings > Developer > Experimental Feature > New Quick Switcher`
rex.bind("ctrl+q>ctrl+g", "pane.go_to")

-- Copy mode and clipboard
rex.bind("ctrl+q>b", "pane.copy_mode.enter")
rex.action({
    name = "copy_and_unselect",
    title = "Copy and clear selection",
    run = function()
        rex.client.queue("pane.copy")
        -- Different modes ensure a selection exists before the final toggle clears it.
        rex.client.queue("pane.copy_mode.select", { mode = "char" })
        rex.client.queue("pane.copy_mode.select", { mode = "line" })
        rex.client.queue("pane.copy_mode.select", { mode = "line" })
    end,
})
rex.bind("copy/y", "copy_and_unselect")
rex.bind("ctrl+shift+c", "pane.copy")
rex.bind("ctrl+shift+v", "pane.paste")

-- Font size
rex.bind("ctrl+shift+=", "client.font.increase")
rex.bind("ctrl+shift+-", "client.font.decrease")
rex.bind("ctrl+shift+0", "client.font.reset")

-- Sidebar
rex.bind("cmd+s", "client.sidebar.toggle")


require("ai")
require("fzf")
require("wd")
