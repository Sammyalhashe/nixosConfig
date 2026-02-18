---
name: openclaw-agent-interact
description: Interact with the internal OpenClaw agent for debugging system services, configuration, or file issues. Use this to leverage the internal agent's context and capabilities.
---

# OpenClaw Agent Interaction

This skill guides you through interacting with the internal OpenClaw agent to debug issues, verify configurations, or perform system checks.

## Workflow

1.  **Start/Target a Session**: Use a consistent session ID to maintain context.
2.  **Set Model Alias (Optional)**: If you need a specific model (e.g., Google Gemini), set the alias.
3.  **Send Message with Context**: Pass all relevant information (logs, file contents, config) in the message body.
4.  **Retrieve Response**: Check the logs to see the agent's reply.

## Commands

### 1. Send Message

Use the `openclaw agent` command.

**Syntax:**
```bash
openclaw agent --session-id <session_id> --message "<your_message>"
```

**Example (Debug Session):**
```bash
openclaw agent --session-id agent:main:telegram:DEBUG --message "Here are the logs: $(journalctl -u my-service -n 20). Why is it failing?"
```

**Example (Setting Model):**
To ensure you are talking to a specific model (e.g., Gemini), send a model command first or as part of the session setup.
```bash
openclaw agent --session-id agent:main:telegram:DEBUG --message "/model gemini-2.5-pro"
```

### 2. Retrieve Response

The agent's output is logged to the OpenClaw logs. Use `tail` to read the most recent entries.

**Command:**
```bash
openclaw logs | tail -n 50
```

## Best Practices

-   **Context is King**: The internal agent cannot see your shell output unless you pass it explicitly. Use command substitution (e.g., `$(cat file.txt)`) or copy-paste logs into the `--message` string.
-   **Session IDs**: Using `agent:main:telegram:<NAME>` allows you to simulate a Telegram user. This is useful for testing channel-specific logic.
-   **Model Aliases**: If the default model is not what you need (e.g., you need Gemini for its larger context window or specific reasoning capabilities), use the `/model` command.