# Debugging with the Internal OpenClaw Agent

This guide describes how to interact with the internal OpenClaw agent to debug system services, configuration, or file issues. These instructions are intended for developers and AI agents (Copilot, Aider, etc.).

## Core Workflow

The internal agent has access to system context and tools. To leverage it for debugging:

1.  **Interface**: Use the `openclaw agent` CLI command.
2.  **Session Management**: Use a consistent session ID (e.g., `agent:main:telegram:DEBUG`) to maintain conversation history.
3.  **Context Injection**: The internal agent cannot "see" your current shell output. You must explicitly pass logs, config files, and errors into the `--message` argument.

## CLI Commands

### 1. Start/Target a Session
Use a `telegram` channel context to ensure standard agent behavior.

```bash
openclaw agent --session-id agent:main:telegram:DEBUG --message "Starting debug session."
```

### 2. Set the Model (Optional)
If you need specific capabilities (e.g., larger context window), switch the model alias first.

```bash
openclaw agent --session-id agent:main:telegram:DEBUG --message "/model gemini-2.5-pro"
```

### 3. Send Context & Questions
Pass command output using command substitution `$()`.

**Example: Debugging a Service**
```bash
openclaw agent --session-id agent:main:telegram:DEBUG --message "Service 'coinbase-trader' is failing. Here are the logs: $(journalctl -u coinbase-trader.service -n 50 --no-pager). Please analyze."
```

**Example: Checking a Config File**
```bash
openclaw agent --session-id agent:main:telegram:DEBUG --message "Checking config content: $(cat /path/to/config). Is this syntax correct?"
```

### 4. Read the Response
The agent's reply is printed to the gateway logs.

```bash
openclaw logs | tail -n 50
```

## Tips for AI Agents (Aider/Copilot)

*   **Always capture output**: When running `openclaw agent`, the immediate output is just an acknowledgment. The *actual* answer appears in the logs.
*   **Chain commands**: To get the answer in one go, chain the send and read commands:
    ```bash
    openclaw agent ... --message "..." && openclaw logs | tail -n 50
    ```
*   **Permissions**: The internal agent runs as the `openclaw` service user (or configured user). It may have different permissions than your shell.
