# Shell Style

Hyprkarl shell scripts should be written for the actual target environment:
single-user CachyOS with Hyprland.

This is the style Hyprkarl uses and recommends. It is not a requirement for
how you manage your own system outside this repo.

## Basic Structure

- Use `#!/bin/bash` for executable scripts.
- Prefer small files with a short purpose comment and a usage comment when the
  script takes arguments.
- Keep constants uppercase when they are true script-level configuration.
- Keep one clear path through the script: parse input, guard assumptions, run
  the action.

## Error Handling

- Do not add Bash strict mode.
- Prefer explicit guard clauses and explicit return-code checks.
- Print short, direct failure messages close to the failing command.

## Readability Rules

- Keep scripts simple, modular, and logically flat when possible.
- Prefer explicit, readable code over clever shorthands.
- Keep script-specific logic local unless extracting it makes the script easier
  to read.
- Minimize heredocs and similar inline template constructions when a real
  template file would be clearer.
- Add comments when the logic has to be dense or a constraint is not obvious.
