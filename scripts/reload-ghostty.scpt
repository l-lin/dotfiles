-- Use AeroSpace to navigate to each workspace and reload Ghostty
-- Use this HACK until Ghostty 1.2.0 is installed.
-- src: https://github.com/ghostty-org/ghostty/discussions/3643#discussioncomment-13899379
set workspaces to {1, 2, 3, 4, 8, 9, 0}

repeat with ws in workspaces
    do shell script "aerospace workspace " & ws

    -- Focus on Ghostty window in this workspace
    do shell script "aerospace focus --app-bundle-id com.mitchellh.ghostty 2>/dev/null || true"

    -- Send reload command
    tell application "System Events"
        keystroke "," using {command down, shift down}
    end tell
end repeat

do shell script "aerospace workspace 1"
