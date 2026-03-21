---
name: file-cat-fallback
description: Strategy for accessing files discovered in logs, errors, or configuration that reside outside the current working directory.
---

# File Cat Fallback

This skill provides a strategy for accessing files discovered in logs, errors, or configuration that reside outside the current working directory.

## Instructions

- If a file path is identified (especially absolute paths like `/nix/store/...` or `/etc/...`) and it is not in the current working directory, **use `cat` first** via `run_shell_command` to inspect it.
- Do not default to searching for the file or using `read_file` if a clear absolute path is already known; `cat` is faster and less prone to path resolution issues for system/store files.
- Use this when troubleshooting startup failures, Nix build issues, or configuration mismatches where absolute paths are frequently present in error output.
