-- Use AeroSpace to navigate to each workspace and reload Ghostty
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
