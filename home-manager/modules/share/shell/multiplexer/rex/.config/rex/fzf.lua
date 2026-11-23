local terminal = "com.superlogical.terminal"

local command = [=[
emulate -L zsh
setopt no_aliases
[[ -n "$REX_BIN_DIR" ]] && export PATH="$REX_BIN_DIR:$PATH"
# Rex clears zoom when focus moves to the picker.
trap 'rex focus -s "$1" "$2" >/dev/null; [[ -n "$3" ]] && rex zoom -s "$1" "$3" --on >/dev/null' EXIT

(( $+functions[__refresh_fzf_default_opts] )) && __refresh_fzf_default_opts
local selected item input="" ret
selected=$(FZF_DEFAULT_COMMAND="${FZF_CTRL_T_COMMAND:-fd --type f --hidden --exclude .git}" \
    FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS-} ${FZF_CTRL_T_OPTS-}" \
    fzf --no-tmux --height=100% --scheme=path --bind=ctrl-z:ignore --multi --print0)
ret=$?
# Cancellation must close the layer without sending input.
(( ret == 1 || ret == 130 )) && exit 0
(( ret == 0 )) || exit "$ret"

# NUL separators preserve spaces and shell quoting prevents command execution.
selected="${selected%$'\0'}"
for item in "${(@0)selected}"; do
    input+="${(q)item} "
done
[[ -n "$input" ]] && rex send -s "$1" -b "$2" -- "$input"
]=]

local function open_fzf(ctx)
    local description, err = rex.session.describe_block({
        session_id = ctx.session_id,
        block_id = ctx.block_id,
    })
    if not description then
        error(err, 0)
    end
    -- Let fzf receive Ctrl-G instead of opening another picker.
    if description.block.label == "fzf" then
        return false
    end

    local process
    process, err = rex.block.call(terminal, "process", { block_id = ctx.block_id })
    if not process then
        error(err, 0)
    end
    local name = process.foreground and process.foreground.name
    if name == "nvim" or name == "vim" then
        return false
    end
    local cwd = process.foreground and process.foreground.cwd
        or process.ancestors and process.ancestors[1] and process.ancestors[1].cwd
        or process.child and process.child.cwd
        or process.home

    local view
    view, err = rex.session.view({ session_id = ctx.session_id })
    if not view then
        error(err, 0)
    end
    local zoomed_block_id = ""
    for _, window in ipairs(view.windows or {}) do
        if window.window_id == description.block.window_id then
            zoomed_block_id = window.zoomed_block_id or ""
            break
        end
    end

    local result
    result, err = rex.session.new_layer({
        session_id = ctx.session_id,
        window_id = description.block.window_id,
        bounds = { 0.05, 0.05, 0.9, 0.9 },
        focus = true,
        layout = rex.layout.block({
            flavor = "com.superlogical.terminal.shell",
            label = "fzf",
            options = {
                cwd = cwd,
                shell = "none",
                command = { "zsh", "-ic", command, "rex-fzf", ctx.session_id, ctx.block_id, zoomed_block_id },
            },
        }),
    })
    if not result then
        error(err, 0)
    end
    return result
end

rex.action({
    name = "open_fzf",
    title = "Find Files",
    run = open_fzf,
})
rex.bind("ctrl+g", function(ctx)
    -- Full-screen programs must receive their own key bindings.
    local modes = rex.block.call(terminal, "modes", { block_id = ctx.block_id })
    if not modes or modes.screen == "alternate" then
        return false
    end
    return open_fzf(ctx) ~= false
end)
