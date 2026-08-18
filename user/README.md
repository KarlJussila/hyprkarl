# User Configuration

This namespace is reserved for configuration owned by the person using this
Hyprkarl checkout. Upstream may document files here, but does not add personal
configuration or change an existing user's files.

The Quickshell prototype uses `shell.json` here when it exists; otherwise it
uses `defaults/shell.json`. A minimal override looks like:

```json
{
  "version": 1,
  "bar": {
    "edge": "bottom"
  }
}
```

Objects merge recursively, arrays replace completely, and layout changes use
explicit widget-ID operations. See
[`docs/shell-configuration.md`](../docs/shell-configuration.md) for the schema
and update contract.
