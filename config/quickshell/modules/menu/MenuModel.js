.import "../../ui/search/TextSearch.js" as TextSearch

function orderedEntries(entries, menuId) {
  var result = []
  for (var entryId of Object.keys(entries || {})) {
    var entry = entries[entryId]
    if (entry.parent === menuId && !entry.hidden) {
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

// How well one search term matches an entry: the start of the label, the
// start of a word in it, an abbreviation of its words, the start of a word
// in its searchText, or anywhere in the label. 0 when it does not match.
function termScore(term, entry) {
  var label = TextSearch.normalize(entry.label)
  var labelWords = TextSearch.words(entry.label)
  if (label.startsWith(term)) return 100
  if (TextSearch.startsAWord(term, labelWords)) return 80
  if (TextSearch.abbreviates(term, labelWords, 0)) return 60
  if (TextSearch.startsAWord(term, TextSearch.words(entry.searchText))) return 40
  if (label.includes(term)) return 20
  return 0
}

// Every term must match; 0 when one does not.
function score(entry, terms) {
  var total = 0
  for (var term of terms) {
    var termTotal = termScore(term, entry)
    if (termTotal === 0) return 0
    total += termTotal
  }
  return total
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

  var terms = TextSearch.terms(query)
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
      var rowScore = row.disabled === true ? 0 : score(row, terms)
      if (rowScore > 0) {
        result.push({ "entry": decorate(row, path, location.depth),
          "score": rowScore, "index": result.length })
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

  // Matches in the current menu come first, then the best matches; ties keep
  // menu order.
  var ranked = result.sort(function(left, right) {
    return (left.entry.searchDepth > 0) - (right.entry.searchDepth > 0)
      || right.score - left.score
      || left.index - right.index
  }).map(function(match) { return match.entry })

  var hasCurrent = ranked.some(function(entry) { return entry.searchDepth === 0 })
  if (hasCurrent) {
    for (var entry of ranked) {
      if (entry.searchDepth > 0) entry.searchSection = "descendant"
    }
  }
  return ranked
}
