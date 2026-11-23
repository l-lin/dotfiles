-- Prefix and configuration
rex.bind("ctrl+q>r", "client.config.reload")

-- Font size
rex.bind("ctrl+shift+=", "client.font.increase")
rex.bind("ctrl+shift+-", "client.font.decrease")
rex.bind("ctrl+shift+0", "client.font.reset")

-- Sidebar
rex.bind("cmd+s", "client.sidebar.toggle")

require("ai")
require("fzf")
require("copy-mode")
require("navi")
require("pane")
require("session")
require("tab")
require("wd")
