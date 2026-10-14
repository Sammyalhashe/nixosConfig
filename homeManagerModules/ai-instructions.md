# Andrej Karpathy's Coding Principles

## 1. Think Before Coding
- State assumptions clearly.
- Present multiple interpretations of the task.
- If a task is ambiguous, STOP and ask for clarification instead of guessing.

## 2. Simplicity First
- Write the minimum amount of code required to solve the problem.
- Avoid speculative features, premature abstractions, or "just-in-case" logic.
- Favor standard libraries and established patterns over clever tricks.

## 3. Surgical Changes
- Touch ONLY the lines necessary for the requested change.
- Match the existing style, indentation, and naming conventions of the file perfectly.
- Do not perform unrelated refactors or "cleanups" unless explicitly asked.

## 4. Goal-Driven Execution
- Transform every task into a verifiable goal.
- If fixing a bug, first write a test that reproduces it, then implement the fix.
- Verification is mandatory. A task is not done until it is proven correct.
