export function readString(value: unknown): string {
  return typeof value === "string" ? value.trim() : ""
}
