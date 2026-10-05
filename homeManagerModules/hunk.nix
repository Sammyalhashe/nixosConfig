# hunk (terminal diff viewer), themed from stylix when it is enabled, and used
# as jj's pager. Without stylix, hunk's "terminal" theme follows the terminal's
# own palette instead.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  stylix = config.stylix.enable or false;
  colors = config.lib.stylix.colors;
  c = colors.withHashtag;

  # Blend `pct`% of base16 color `fg` into `bg`, for tinted diff backgrounds.
  rgb =
    name:
    map (ch: lib.toInt colors."${name}-rgb-${ch}") [
      "r"
      "g"
      "b"
    ];
  hex2 = n: lib.fixedWidthString 2 "0" (lib.toLower (lib.toHexString n));
  mix =
    fg: bg: pct:
    "#"
    + lib.concatMapStrings hex2 (
      lib.zipListsWith (f: b: (f * pct + b * (100 - pct)) / 100) (rgb fg) (rgb bg)
    );

  stylixTheme = {
    base = if config.stylix.polarity == "light" then "github-light-default" else "github-dark-default";
    label = "Stylix";
    background = c.base00;
    panel = c.base01;
    panelAlt = c.base02;
    border = c.base02;
    accent = c.base0D;
    accentMuted = mix "base0D" "base00" 35;
    text = c.base05;
    muted = c.base04;
    addedBg = mix "base0B" "base00" 15;
    removedBg = mix "base08" "base00" 15;
    movedAddedBg = mix "base0C" "base00" 15;
    movedRemovedBg = mix "base0E" "base00" 15;
    contextBg = c.base00;
    addedContentBg = mix "base0B" "base00" 30;
    removedContentBg = mix "base08" "base00" 30;
    contextContentBg = c.base01;
    addedSignColor = c.base0B;
    removedSignColor = c.base08;
    lineNumberBg = c.base00;
    lineNumberFg = c.base03;
    selectedHunk = c.base02;
    badgeAdded = c.base0B;
    badgeRemoved = c.base08;
    badgeNeutral = c.base04;
    fileNew = c.base0B;
    fileDeleted = c.base08;
    fileRenamed = c.base0E;
    fileModified = c.base0A;
    fileUntracked = c.base0C;
    noteBorder = c.base0E;
    noteBackground = c.base01;
    noteTitleBackground = c.base0E;
    noteTitleText = c.base00;
    # base16 styling guidelines, except variables stay base05 so they don't
    # read as removed lines.
    syntax_scopes = {
      "comment" = c.base03;
      "punctuation.definition.comment" = c.base03;
      "keyword" = c.base0E;
      "storage" = c.base0E;
      "keyword.operator" = c.base0C;
      "string" = c.base0B;
      "string.regexp" = c.base0C;
      "constant.character.escape" = c.base0C;
      "constant.numeric" = c.base09;
      "constant.language" = c.base09;
      "entity.name.function" = c.base0D;
      "support.function" = c.base0D;
      "entity.name.type" = c.base0A;
      "entity.name.class" = c.base0A;
      "support.type" = c.base0A;
      "entity.name.tag" = c.base08;
      "entity.other.attribute-name" = c.base09;
      "variable" = c.base05;
    };
  };

  settings = {
    theme = if stylix then "stylix" else "terminal";
    mode = "auto";
    line_numbers = true;
    wrap_lines = false;
    hunk_headers = true;
    menu_bar = true;
    agent_notes = false;
    copy_decorations = false;
    cursor_line = "row";
  }
  // lib.optionalAttrs stylix { themes.stylix = stylixTheme; };

  configFile = (pkgs.formats.toml { }).generate "hunk-config.toml" settings;
in
{
  home.packages = [ pkgs.hunk ];

  programs.jujutsu.settings.ui = {
    pager = [
      "hunk"
      "pager"
    ];
    diff-formatter = ":git";
  };

  # Copied rather than symlinked: hunk saves view preferences back to
  # config.toml, so it must stay writable. Each switch resets it.
  home.activation.setupHunkConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p $HOME/.config/hunk
    $DRY_RUN_CMD cp -f ${configFile} $HOME/.config/hunk/config.toml
    $DRY_RUN_CMD chmod +w $HOME/.config/hunk/config.toml
  '';
}
