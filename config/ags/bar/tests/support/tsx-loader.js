// ESM loader hook for the Node test runner.
//
// Handles three problems that prevent the test suite from loading:
//   1. ags/* and gi:// modules don't exist in Node — redirect to agsMock.js
//   2. .tsx files contain JSX syntax that Node's type-stripper can't handle
//   3. Some source files use extension-less relative imports (resolved by AGS's
//      bundler at build time, but not by Node's ESM resolver)

import { registerHooks, stripTypeScriptTypes } from "node:module"
import { readFileSync, existsSync } from "node:fs"
import { fileURLToPath, pathToFileURL } from "node:url"
import path from "node:path"
import { createRequire } from "node:module"

const require = createRequire(import.meta.url)
const MOCK_URL = pathToFileURL(
  path.resolve(path.dirname(fileURLToPath(import.meta.url)), "agsMock.js"),
).href

registerHooks({
  resolve(specifier, context, nextResolve) {
    // Redirect all AGS/GI modules to the mock
    if (
      specifier.startsWith("gi://") ||
      specifier.startsWith("ags/") ||
      specifier === "ags" ||
      specifier === "gnim"
    ) {
      return { shortCircuit: true, url: MOCK_URL }
    }

    // Resolve extension-less relative imports by trying .ts then .tsx
    if (specifier.startsWith(".") && context.parentURL) {
      const hasExt = /\.[a-z]+$/i.test(specifier)
      if (!hasExt) {
        const parentDir = path.dirname(fileURLToPath(context.parentURL))
        for (const ext of [".ts", ".tsx"]) {
          const candidate = path.resolve(parentDir, specifier + ext)
          if (existsSync(candidate)) {
            return { shortCircuit: true, url: pathToFileURL(candidate).href }
          }
        }
      }
    }

    return nextResolve(specifier, context)
  },

  load(url, context, nextLoad) {
    if (!url.endsWith(".tsx")) return nextLoad(url, context)

    const filePath = fileURLToPath(url)
    const source = readFileSync(filePath, "utf-8")
    const basename = path.basename(filePath)

    // Widget spec files (spec.tsx) and widgetSpec.tsx need to load fully so
    // their resolve() functions work in tests. Strip JSX from render: bodies.
    // All other .tsx files are view components — tests never call render(), so
    // stub them out entirely.
    let processed
    if (basename === "spec.tsx" || basename === "widgetSpec.tsx" || basename === "createPollingMonitorWidgetSpec.tsx") {
      processed = stripRenderJsx(source)
    } else {
      processed = "export default null"
    }

    try {
      const js = stripTypeScriptTypes(processed)
      return { shortCircuit: true, format: "module", source: js }
    } catch {
      return { shortCircuit: true, format: "module", source: "export default null" }
    }
  },
})

// Replace `render: (args) => (\n  <JSX.../>\n)` with `render: (args) => (null)`.
// Widget spec render functions always use this exact format — multi-line JSX
// wrapped in parentheses with no nested () in attribute values.
function stripRenderJsx(source) {
  return source.replace(/=>\s*\(\s*\n[\s\S]*?\n\s*\)/g, "=> (null)")
}
