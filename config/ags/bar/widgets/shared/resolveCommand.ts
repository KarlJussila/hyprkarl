import { execAsync } from "ags/process"

export function resolveCommand(
  cmd: string | undefined,
  fallback: (() => void) | undefined,
  tokens: Record<string, (() => void) | undefined> = {},
): (() => void) | undefined {
  if (cmd === undefined) return fallback
  if (cmd === "") return undefined
  const match = cmd.match(/^\{([\w-]+)\}$/)
  if (match) {
    const tokenName = match[1]
    if (!(tokenName in tokens)) {
      console.error(`[bar] Unknown command token "${cmd}"`)
      return undefined
    }
    const handler = tokens[tokenName]
    if (!handler) {
      console.error(`[bar] Command token "${cmd}" is not available with current widget config`)
      return undefined
    }
    return handler
  }
  return () => { execAsync(cmd).catch(() => {}) }
}
