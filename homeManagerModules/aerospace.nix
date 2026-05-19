{ ... }:
{
  xdg.configFile."aerospace/aerospace.toml".text = ''
    after-startup-command = []
    start-at-login = true
    on-focused-monitor-changed = ['move-mouse monitor-lazy-center']

    [mode.main.binding]
    # focus windows (cross monitor boundaries)
    cmd-h = 'focus --boundaries all-monitors-outer-frame left'
    cmd-j = 'focus --boundaries all-monitors-outer-frame down'
    cmd-k = 'focus --boundaries all-monitors-outer-frame up'
    cmd-l = 'focus --boundaries all-monitors-outer-frame right'

    # move windows
    alt-shift-h = 'move left'
    alt-shift-j = 'move down'
    alt-shift-k = 'move up'
    alt-shift-l = 'move right'

    # move window to monitor
    cmd-shift-h = 'move-node-to-monitor --wrap-around prev'
    cmd-shift-j = 'move-node-to-monitor --wrap-around down'
    cmd-shift-k = 'move-node-to-monitor --wrap-around up'
    cmd-shift-l = 'move-node-to-monitor --wrap-around next'

    # layout
    alt-slash = 'layout tiles horizontal vertical'
    alt-comma = 'layout accordion horizontal vertical'

    # resize
    alt-minus = 'resize smart -50'
    alt-equal = 'resize smart +50'

    # workspaces
    alt-1 = 'workspace 1'
    alt-2 = 'workspace 2'
    alt-3 = 'workspace 3'
    alt-4 = 'workspace 4'
    alt-5 = 'workspace 5'
    alt-6 = 'workspace 6'
    alt-7 = 'workspace 7'
    alt-8 = 'workspace 8'
    alt-9 = 'workspace 9'

    # move window to workspace
    alt-shift-1 = 'move-node-to-workspace 1'
    alt-shift-2 = 'move-node-to-workspace 2'
    alt-shift-3 = 'move-node-to-workspace 3'
    alt-shift-4 = 'move-node-to-workspace 4'
    alt-shift-5 = 'move-node-to-workspace 5'
    alt-shift-6 = 'move-node-to-workspace 6'
    alt-shift-7 = 'move-node-to-workspace 7'
    alt-shift-8 = 'move-node-to-workspace 8'
    alt-shift-9 = 'move-node-to-workspace 9'

    # named workspaces
    alt-b = 'workspace Bloomberg'
    alt-shift-b = 'move-node-to-workspace Bloomberg'
    alt-shift-i = 'workspace Bloomberg-IB'
    alt-shift-c = 'workspace Coding'
    alt-shift-w = 'workspace Browser'

    alt-backtick = 'workspace-back-and-forth'
    alt-shift-tab = 'move-workspace-to-monitor --wrap-around next'

    [[on-window-detected]]
    if.app-name-regex-substring = 'Citrix'
    if.window-title-regex-substring = 'IB'
    run = ['layout floating', 'move-node-to-workspace Bloomberg-IB']

    [[on-window-detected]]
    if.app-name-regex-substring = 'Citrix'
    run = ['layout floating', 'move-node-to-workspace Bloomberg']

    [[on-window-detected]]
    if.app-name-regex-substring = 'Ghostty'
    run = 'move-node-to-workspace Coding'

    [[on-window-detected]]
    if.app-name-regex-substring = 'Firefox'
    run = 'move-node-to-workspace Browser'

    [workspace-to-monitor-force-assignment]
    Coding = 1
    Browser = 2
    Bloomberg = 'built-in'
    Bloomberg-IB = 'built-in'
  '';
}
