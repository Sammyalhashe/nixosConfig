{
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./zellij.nix
    ./nushell.nix
    ./aider.nix
    ./tmux.nix
    ./yazi.nix
    ./picoclaw.nix
  ];

  home.packages = with pkgs; [
    btop
    podman
    ripgrep
    fzf
    jq
    python3
    rsync
  ];

  programs.aider.enable = true;

  home.file.".picoclaw/workspace/skills/aider-bootstrap/SKILL.md".text = ''
---
name: aider-bootstrap
description: Bootstrap new software projects using Aider. Automatically handles directory creation and git initialization required by Aider.
---

# Aider Project Bootstrapper

Use this skill when the user wants to create, scaffold, or bootstrap a new project using Aider.

## Workflow

1.  **Create Directory**: Ensure the target directory exists.
    ```bash
    mkdir -p <target_directory>
    ```

2.  **Safety Check**: Verify the target directory is NOT the root filesystem.
    *   Target must NOT be `/`.
    *   Target must NOT be `/home/username` (unless explicitly requested, but prefer subdirs).

3.  **Git Initialization**: Aider requires a git repository to function.
    *   Check if git is initialized: `cd <target_directory> && git status`
    *   If not, initialize it: `cd <target_directory> && git init`

4.  **Run Aider**: Invoke aider with the prompt.
    ```bash
    cd <target_directory> && aider --no-auto-commits --message "<prompt>"
    ```

## Example

**User:** "Make a python calculator in `py-calc`"

**Agent Action:**
1.  `mkdir -p py-calc`
2.  `cd py-calc && git init`
3.  `cd py-calc && aider --message "Build a python calculator..."`
  '';

  programs.starship.enable = true;
  programs.git = {
    enable = true;
    settings = {
      user.name = "Sammy Al Hashemi";
      user.email = "sammy@salh.xyz";
    };
  };

  # Disable Stylix targets that might pull in graphical dependencies on headless Pi

  home.stateVersion = "23.11";
}