local gitlab = require("gitlab")

---Lazy start the Gitlab Golang server.
---Useful to start the Gitlab Golang server only when calling executing one of the defined keymaps.
---See https://github.com/harrisoncramer/gitlab.nvim/issues/67 for more information.
local function start_gitlab_server_if_not_running(callback)
  if not require("gitlab.state").go_server_running then
    gitlab.setup({
      popup = { -- The popup for comment creation, editing, and replying
        perform_action = "<C-s>", -- Once in normal mode, does action (like saving comment or editing description, etc)
      },
      discussion_tree = { -- The discussion tree that holds all comments
        toggle_node = "<cr>", -- Opens or closes the discussion
        position = "bottom", -- "top", "right", "bottom" or "left"
        size = "40%", -- Size of split
        resolved = "", -- Symbol to show next to resolved discussions
        unresolved = "", -- Symbol to show next to unresolved discussions
      },
      create_mr = {
        target = "develop",
      },
    })
  end
  callback()
end

local M = {}

M.approve = function() start_gitlab_server_if_not_running(gitlab.approve) end
M.create_comment = function() start_gitlab_server_if_not_running(gitlab.create_comment) end
M.create_comment_suggestion = function() start_gitlab_server_if_not_running(gitlab.create_comment_suggestion) end
M.create_multiline_comment = function() start_gitlab_server_if_not_running(gitlab.create_multiline_comment) end
M.create_note = function() start_gitlab_server_if_not_running(gitlab.create_note) end
M.create_mr = function() start_gitlab_server_if_not_running(gitlab.create_mr) end
M.toggle_discussions = function() start_gitlab_server_if_not_running(gitlab.toggle_discussions) end
M.open_in_browser = function() start_gitlab_server_if_not_running(gitlab.open_in_browser) end
M.pipeline = function() start_gitlab_server_if_not_running(gitlab.pipeline) end
M.review = function() start_gitlab_server_if_not_running(gitlab.review) end
M.revoke = function() start_gitlab_server_if_not_running(gitlab.revoke) end
M.summary = function() start_gitlab_server_if_not_running(gitlab.summary) end

return M
