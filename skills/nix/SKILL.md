---
name: nix
description: Expert guidance for managing this NixOS configuration repository. Use this skill when modifying system configurations, home-manager settings, or LLM services.
---

# NixOS Configuration Management

## Core Mandates
- **Host Awareness**: Identify the target host before applying changes. Common hosts: `mothership`, `filestore`, `oldboy`, `homebase`.
- **Atomic Changes**: Keep configuration changes focused and verified.
- **Service Continuity**: After modifying LLM configurations, always verify the status of `litellm` and `llama-cpp-reasoning`.

## Workflow

### 1. Configuration Deployment
Use the built-in helper scripts when possible:
- **Switch Mothership**: `nix develop --command switch-mothership`
- **Switch Filestore**: `nix develop --command switch-filestore`
- **Manual Rebuild**: `sudo nixos-rebuild switch --flake .#<host>`

### 2. Secret Management (SOPS)
- **Edit Secrets**: `sops secrets.yaml`
- **Add New Secret**: Add to `secrets.yaml`, then reference in Nix using `config.sops.secrets.<name>.path`.
- **Note**: Ensure `SOPS_AGE_KEY_FILE` is set or you have access to the relevant SSH keys.

### 3. LLM Service Maintenance
- **Restart LiteLLM**: `sudo systemctl restart litellm`
- **Restart Reasoning Engine**: `sudo systemctl restart llama-cpp-reasoning`
- **Check Logs**: `journalctl -u litellm -f` or `journalctl -u llama-cpp-reasoning -f`

### 4. Repository Maintenance
- **Formatting**: `nix fmt` or `nix develop --command fmt`
- **Update Flake**: `nix flake update`
- **Check Integrity**: `nix flake check`

## Common Paths
- **Host Configs**: `hosts/<host>/configuration.nix`
- **LLM Services**: `nixosModules/llm-services/`
- **Home Manager**: `homeManagerModules/`
- **Shared Config**: `common/`
