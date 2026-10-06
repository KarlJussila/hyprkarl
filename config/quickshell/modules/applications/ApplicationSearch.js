// Ranks applications for a launcher query. Every term must match the entry's
// name, generic name, keywords, executable, desktop ID, or categories.
// Matches in the name count most, and how often an application was launched
// breaks near-ties.

var separators = /[\s!-\/:-@\[-`{-~]+/

function normalize(text) {
  return String(text || "").normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "").toLowerCase()
}

// "LibreOffice Draw" has the words libre, office, and draw.
function words(text) {
  return String(text || "").replace(/([a-z])([A-Z])/g, "$1 $2")
    .split(separators).map(normalize)
    .filter(function(word) { return word.length > 0 })
}

// Whether the term is made of prefixes of the words in order, such as "lod"
// or "lodr" for LibreOffice Draw.
function abbreviates(term, nameWords, from) {
  if (term.length === 0) return true
  for (var index = from; index < nameWords.length; index++) {
    var word = nameWords[index]
    for (var length = Math.min(word.length, term.length); length > 0; length--) {
      if (word.slice(0, length) === term.slice(0, length)
          && abbreviates(term.slice(length), nameWords, index + 1)) return true
    }
  }
  return false
}

function startsAWord(term, wordList) {
  return wordList.some(function(word) { return word.startsWith(term) })
}

function termScore(term, entry) {
  var name = normalize(entry.name)
  var nameWords = words(entry.name)
  if (name.startsWith(term)) return 100
  if (startsAWord(term, nameWords)) return 80
  if (abbreviates(term, nameWords, 0)) return 60
  var otherWords = words([entry.genericName, entry.executable, entry.id]
    .concat(entry.keywords || []).join(" "))
  if (startsAWord(term, otherWords)) return 40
  if (name.includes(term)) return 20
  if (startsAWord(term, words((entry.categories || []).join(" ")))) return 10
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
  if (normalize(entry.name) === query) total += 50
  return total + Math.min(30, 10 * Math.log2(1 + (launches[entry.id] || 0)))
}

// Entries keep their order when the query is empty.
function rank(entries, query, launches) {
  var normalized = normalize(query).trim()
  var terms = normalized.split(/\s+/)
    .filter(function(term) { return term.length > 0 })
  if (terms.length === 0) return entries
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
