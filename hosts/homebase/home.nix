{ config, lib, pkgs, ... }:
{
  imports = [
    ../../homeManagerModules/desktop-base.nix
    ../../homeManagerModules
  ];

  home.packages =
    with pkgs;
    [
        bambu-studio
        goose-cli
        goose-desktop
        # Goose against the public mesh client on localhost:9337. Peers see the
        # prompts, and tool calls need approval because their models are untrusted.
        (writeShellScriptBin "goose-mesh" ''
          export GOOSE_PROVIDER=openai
          export OPENAI_HOST=http://localhost:9337
          export OPENAI_BASE_PATH=v1/chat/completions
          export OPENAI_API_KEY=mesh
          export GOOSE_MODEL="''${GOOSE_MODEL:-unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_M}"
          export GOOSE_MODE=approve
          exec ${goose-cli}/bin/goose "$@"
        '')
    ];

  # The waybar unit starts in any Hyprland session, including Ryoku's, which
  # brings its own bar.
  programs.waybar.systemd.enable = lib.mkForce false;

  # Ryoku composes ~/.config/starship.toml from its prompt layouts and theme
  # and rewrites it at login; home-manager writing it too blocked activation.
  # starship and jj-starship stay installed; only the file is Ryoku's.
  xdg.configFile."starship.toml".enable = lib.mkForce false;

  # Match the XDG_DATA_HOME/XDG_CACHE_HOME set in configuration.nix.
  xdg.dataHome = "${config.home.homeDirectory}/var/lib";
  xdg.cacheHome = "${config.home.homeDirectory}/var/cache";
}
