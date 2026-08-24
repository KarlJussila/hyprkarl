function fuzzyMatch(text, pattern) {
  var patternIndex = 0
  for (var textIndex = 0;
      textIndex < text.length && patternIndex < pattern.length;
      textIndex++) {
    if (text[textIndex] === pattern[patternIndex]) patternIndex++
  }
  return patternIndex === pattern.length
}

function orderedEntries(entries, menuId) {
  var result = []
  for (var entryId of Object.keys(entries || {})) {
    var entry = entries[entryId]
    if (entry.parent === menuId && entry.enabled !== false) {
      result.push(Object.assign({ "id": entryId }, entry))
    }
  }
  result.sort(function(left, right) {
    return left.order === right.order
      ? left.id.localeCompare(right.id)
      : left.order - right.order
  })
  return result
}

function matches(entry, terms) {
  var text = [entry.searchText || "", entry.label]
    .join(" ").toLowerCase()
  return terms.every(function(term) { return fuzzyMatch(text, term) })
}

function decorate(entry, path, depth) {
  return Object.assign({
    "searchDepth": depth,
    "searchDetail": path,
    "searchSection": "current"
  }, entry)
}

function entriesFor(entries, currentMenu, dynamicMenuId, dynamicEntries, query) {
  var direct = orderedEntries(entries, currentMenu)
  if (dynamicMenuId === currentMenu) {
    direct = direct.concat(dynamicEntries || [])
  }

  var terms = String(query || "").trim().toLowerCase()
    .split(/\s+/).filter(function(term) { return term.length > 0 })
  if (terms.length === 0) {
    return direct.map(function(entry) { return decorate(entry, "", 0) })
  }

  var result = []
  var queue = [{ "menu": currentMenu, "path": [], "depth": 0 }]
  var visited = ({})

  while (queue.length > 0) {
    var location = queue.shift()
    if (visited[location.menu]) continue
    visited[location.menu] = true

    var rows = orderedEntries(entries, location.menu)
    if (location.menu === currentMenu && dynamicMenuId === currentMenu) {
      rows = rows.concat(dynamicEntries || [])
    }

    var path = location.path.join(" › ")
    for (var row of rows) {
      if (row.disabled !== true && matches(row, terms)) {
        result.push(decorate(row, path, location.depth))
      }
      if (row.action?.type === "menu" && !visited[row.action.menu]) {
        queue.push({
          "menu": row.action.menu,
          "path": location.path.concat([row.label]),
          "depth": location.depth + 1
        })
      }
    }
  }

  var hasCurrent = result.some(function(entry) { return entry.searchDepth === 0 })
  if (hasCurrent) {
    for (var entry of result) {
      if (entry.searchDepth > 0) entry.searchSection = "descendant"
    }
  }
  return result
}
