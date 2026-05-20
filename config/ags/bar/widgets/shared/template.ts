export function substituteTokens(
  template: string,
  substitutions: Record<string, string | undefined>,
): string {
  const rendered = Object.entries(substitutions).reduce(
    (result, [token, value]) => result.replaceAll(`{${token}}`, value ?? ""),
    template,
  )

  return rendered
    .split("\n")
    .map((line) => line.replace(/\s+/g, " ").trim())
    .join("\n")
    .trim()
}
