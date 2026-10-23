// Word matching shared by the launcher and menu searches.

var separators = /[\s!-\/:-@\[-`{-~]+/

// Both caches hold every label searched: a search normalizes and splits the
// same labels on every keystroke.
var normalCache = ({})
var wordCache = ({})

function normalize(text) {
  var key = String(text || "")
  if (!(key in normalCache)) {
    normalCache[key] = key.normalize("NFD")
      .replace(/[\u0300-\u036f]/g, "").toLowerCase()
  }
  return normalCache[key]
}

// "LibreOffice Draw" has the words libre, office, and draw.
function words(text) {
  var key = String(text || "")
  if (!(key in wordCache)) {
    wordCache[key] = key.replace(/([a-z])([A-Z])/g, "$1 $2")
      .split(separators).map(normalize)
      .filter(function(word) { return word.length > 0 })
  }
  return wordCache[key]
}

// Whether the term is made of prefixes of the words in order, such as "lod"
// or "lodr" for LibreOffice Draw.
function abbreviates(term, textWords, from) {
  if (term.length === 0) return true
  for (var index = from; index < textWords.length; index++) {
    var word = textWords[index]
    if (word[0] !== term[0]) continue
    for (var length = Math.min(word.length, term.length); length > 0; length--) {
      if (word.slice(0, length) === term.slice(0, length)
          && abbreviates(term.slice(length), textWords, index + 1)) return true
    }
  }
  return false
}

function startsAWord(term, wordList) {
  return wordList.some(function(word) { return word.startsWith(term) })
}

function terms(query) {
  return normalize(query).trim().split(/\s+/)
    .filter(function(term) { return term.length > 0 })
}
