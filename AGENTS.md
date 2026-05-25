# NixOS Configuration Repository

Multi-host NixOS & Darwin configuration managed via Nix flakes, home-manager, sops-nix, and stylix.

## Hosts

| Host | OS | Architecture | Notes |
|------|-----|-------------|-------|
| starship | NixOS | x86_64 | Main desktop (KDE + Mango WC) |
| starshipwsl | NixOS (WSL) | x86_64 | Windows Subsystem for Linux |
| mothership | NixOS | x86_64 | Main desktop (KDE + Mango WC) |
| homebase | NixOS | x86_64 | Server/dashboard |
| homebasewsl | NixOS (WSL) | x86_64 | WSL variant |
| oldboy | NixOS | x86_64 | Headless server |
| filestore | NixOS | aarch64 | Raspberry Pi 4 |
| KQ7DV474L1 | Darwin | aarch64 | macOS |

## AI Agents

When working on this repo, use the **nix-ninja** agent for Nix-related tasks (flake updates, module changes, builds).

## VCS

This repo uses **jujutsu (jj)** for version control.

- The primary bookmark is **`master`** (not `main`).
- Always describe commits before pushing — jj rejects empty/undescribed commits.
- Sync workflow:
  ```
  jj git fetch
  jj log -n 1 --no-graph        # inspect latest commit
  jj describe -m "type: message" # if needed
  jj bookmark set master -r @   # set bookmark
  jj git push
  ```

## Building & Validation

### Prerequisites
- Nix with flakes and nix-command enabled
- Determinate Nix (on macOS)

### Check the flake
```
nix flake check
```

### Build top-level of each host

**NixOS hosts** (requires sudo on target or local rebuild):
```
sudo nixos-rebuild switch --flake .#<hostname>
sudo nixos-rebuild test --flake .#<hostname>
```

Replace `<hostname>` with one of: `starship`, `starshipwsl`, `mothership`, `homebase`, `homebasewsl`, `oldboy`, `filestore`.

**Darwin host** (hosts starting with `K`):
```
darwin-rebuild switch --flake .#KQ7DV474L1
```

**Home manager configs**:
```
home-manager switch --flake .#work
```

**DevShell scripts** (run via `nix develop` or from the flake's `bin/`):
```
check          - Run nix flake check
fmt            - Run nix fmt
switch-<host>  - Switch NixOS config locally
test-<host>    - Test NixOS config locally
push-<host>    - Build and push to cachix
deploy-<host>  - Build locally, push closure, activate on remote host
```

## Formatting

Run `nix fmt` before committing to ensure all files are formatted correctly.

## Key Components

- **flake.nix** — Main flake definition with all host configurations and outputs
- **hosts/** — Per-host NixOS/Darwin configuration
- **common/** — Shared configuration across hosts
- **modules/** — Reusable NixOS and home-manager modules
- **homeManagerModules/** — Home manager configurations
- **secrets.yaml** — Encrypted secrets via sops-nix (age-based)
- **starship.conf** — Starship shell prompt configuration
- **CLAUDE.md** — AI assistant principles (Karpathy coding principles)

## Environment Variables

Key env vars are set via `home.sessionVariables` in the home-manager config:
- `ANTHROPIC_BASE_URL` — LiteLLM endpoint URL
- `ANTHROPIC_API_KEY` — API key (any non-empty string for LiteLLM)

For WSL hosts, `environments.wsl.enable = true` is set with the Windows username.
