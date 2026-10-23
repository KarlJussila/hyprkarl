// Ranks applications for a launcher query. Every term must match the entry's
// name, generic name, keywords, executable, desktop ID, or categories.
// Matches in the name count most, and how often an application was launched
// breaks near-ties.

.import "../../ui/search/TextSearch.js" as TextSearch

function termScore(term, entry) {
  var name = TextSearch.normalize(entry.name)
  var nameWords = TextSearch.words(entry.name)
  if (name.startsWith(term)) return 100
  if (TextSearch.startsAWord(term, nameWords)) return 80
  if (TextSearch.abbreviates(term, nameWords, 0)) return 60
  var otherWords = TextSearch.words([entry.genericName, entry.executable,
    entry.id].concat(entry.keywords || []).join(" "))
  if (TextSearch.startsAWord(term, otherWords)) return 40
  if (name.includes(term)) return 20
  var categoryWords = TextSearch.words((entry.categories || []).join(" "))
  if (TextSearch.startsAWord(term, categoryWords)) return 10
  return 0
}

// launches: desktop entry ID to launch count.
function score(entry, query, terms, launches) {
  var total = 0
  for (var term of terms) {
    var termTotal = termScore(term, entry)
    if (termTotal === 0) return 0
    total += termTotal
  }
  if (TextSearch.normalize(entry.name) === query) total += 50
  return total + Math.min(30, 10 * Math.log2(1 + (launches[entry.id] || 0)))
}

// With an empty query, order "launches" puts the most launched entries first
// and keeps the rest in their order; any other order keeps them all in order.
function rank(entries, query, launches, order) {
  var normalized = TextSearch.normalize(query).trim()
  var terms = TextSearch.terms(query)
  if (terms.length === 0) {
    if (order !== "launches") return entries
    return entries
      .map(function(entry, index) { return { "entry": entry, "index": index } })
      .sort(function(left, right) {
        return (launches[right.entry.id] || 0) - (launches[left.entry.id] || 0)
          || left.index - right.index
      })
      .map(function(result) { return result.entry })
  }
  return entries
    .map(function(entry) {
      return { "entry": entry, "score": score(entry, normalized, terms, launches || {}) }
    })
    .filter(function(result) { return result.score > 0 })
    .sort(function(left, right) {
      return right.score - left.score
        || left.entry.name.localeCompare(right.entry.name)
    })
    .map(function(result) { return result.entry })
}
