import QtQuick
import QtTest
import "../config/quickshell/modules/applications/ApplicationSearch.js" as ApplicationSearch

TestCase {
  name: "ApplicationSearch"

  readonly property var entries: [
    { "id": "chromium", "name": "Chromium", "genericName": "Web Browser",
      "keywords": [], "executable": "chromium" },
    { "id": "libreoffice-draw", "name": "LibreOffice Draw",
      "genericName": "Drawing Program", "keywords": [], "executable": "libreoffice" },
    { "id": "libreoffice-writer", "name": "LibreOffice Writer",
      "genericName": "Word Processor", "keywords": [], "executable": "libreoffice" },
    { "id": "org.gnome.Nautilus", "name": "Files", "genericName": "",
      "keywords": ["folder", "manager"], "executable": "nautilus" },
    { "id": "protontricks", "name": "Protontricks", "genericName": "",
      "keywords": ["Steam", "Proton", "Wine"], "executable": "protontricks" },
    { "id": "steam", "name": "Steam", "genericName": "",
      "keywords": [], "executable": "steam", "categories": ["Game"] },
    { "id": "steamtinkerlaunch", "name": "SteamTinkerLaunch", "genericName": "",
      "keywords": [], "executable": "steamtinkerlaunch" },
    { "id": "thunar", "name": "Thunar File Manager", "genericName": "File Manager",
      "keywords": [], "executable": "thunar" },
    { "id": "eog", "name": "Éye of GNOME", "genericName": "Image Viewer",
      "keywords": [], "executable": "eog" },
    { "id": "bolt", "name": "Bolt", "genericName": "Bolt Launcher",
      "keywords": [], "executable": "flatpak" },
    { "id": "spotify", "name": "Spotify", "genericName": "",
      "keywords": [], "executable": "spotify", "categories": ["Audio", "Music"] }
  ]

  function names(query, launches) {
    return ApplicationSearch.rank(entries, query, launches || {})
      .map(entry => entry.name)
  }

  function test_emptyQueryKeepsOrder() {
    compare(ApplicationSearch.rank(entries, "  ", {}), entries)
  }

  function test_nameBeforeKeyword() {
    compare(names("steam"), ["Steam", "SteamTinkerLaunch", "Protontricks"])
  }

  function test_launchesDoNotLiftKeywordOverName() {
    compare(names("steam", { "protontricks": 500 })[0], "Steam")
  }

  function test_launchesBreakTiesWithinNames() {
    compare(names("libre"), ["LibreOffice Draw", "LibreOffice Writer"])
    compare(names("libre", { "libreoffice-writer": 3 }),
      ["LibreOffice Writer", "LibreOffice Draw"])
  }

  function test_wordStartsAndAbbreviations() {
    compare(names("office"), ["LibreOffice Draw", "LibreOffice Writer"])
    compare(names("lod"), ["LibreOffice Draw"])
    compare(names("lowr"), ["LibreOffice Writer"])
  }

  function test_categories() {
    compare(names("music"), ["Spotify"])
    compare(names("gam"), ["Steam"])
  }

  function test_scatteredLettersDoNotMatch() {
    compare(names("bl"), [])
  }

  function test_everyTermMustMatch() {
    compare(names("libre draw"), ["LibreOffice Draw"])
  }

  function test_secondaryFields() {
    compare(names("nautilus"), ["Files"])
    compare(names("browser"), ["Chromium"])
    compare(names("file"), ["Files", "Thunar File Manager"])
  }

  function test_accentsAreIgnored() {
    compare(names("eye"), ["Éye of GNOME"])
  }
}
