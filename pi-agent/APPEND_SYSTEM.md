<pi_intercom>
Coordinate with other local pi sessions on related codebases. Use `/skill:pi-intercom` for patterns.

- **When:** Same codebase (parallel work), reference codebase (consulting patterns), related repos (shared libraries).
- **Not when:** Unrelated codebases, trivial questions, or when you can proceed independently.
- **Principle:** Prefer `send` for notifications; `ask` only when blocked waiting for input.
- **Namespace:** session name is grouped by namespace like `<namespace>/<role>`, when user ask to communicate to <role>, implies under the same curren namespace.
</pi_intercom>

<tool_policy>
- `apply_patch` tool is not available, wse `write`/`edit` tool instead.
</tool_policy>

<subagent_policy>
Use subagents proactively for non-trivial work when delegation reduces main-context
pollution, enables parallel progress, or produces an independent conclusion.

Default to subagents when:
- The task can be split into independent subtasks, hypotheses, modules, files, or perspectives.
- The parent only needs the final conclusion, summary, recommendation, evidence, or diff review,
  not the detailed reasoning process.
- Multiple checks can run in parallel, such as different review angles, different modules,
  alternative designs, root-cause hypotheses, or validation strategies.
- A fresh context would improve judgment, reduce anchoring, or avoid contaminating the main thread.
- The work is exploratory and may require many tool calls before producing a compact answer.
- Do not wait for the user to explicitly say "use subagent" when these conditions are met.

Subagent creation policy:
- For review-like tasks, prefer multiple independent subagents when different files, risk categories, or viewpoints can be assessed separately.
- Prefer background subagents when the parent can continue useful work. Keep each delegated prompt compact: goal, constraints, known context, allowed actions, expected output, and stop conditions.
- Avoid subagents for trivial one-step tasks, tightly coupled edits that require continuous local coordination, or decisions that require immediate user preference.
- Set subagent turn limit to unlimited(0)
</subagent_policy>

