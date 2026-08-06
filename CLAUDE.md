<!-- MASTERINDEX:START -->
## MasterIndex coordination

For portfolio-wide, cross-repository, cross-app, cross-machine, periodic, or operational work, read these files in order:

1. `~/masterindex/current/index.json`
2. `~/masterindex/tasks/index.json`
3. `~/masterindex/current/handoffs/index.json`

Use `entities[].id` as canonical target keys. Apply active handoff directives addressed to the target entity or `all-entities`. The task registry requires a verification every six hours and an observed-fact refresh every day. When facts change, update `current/index.json` before `current/inventory.md`; record gaps and ambiguities explicitly.

This delimited block is managed by MasterIndex. Preserve all instructions outside it.
<!-- MASTERINDEX:END -->
