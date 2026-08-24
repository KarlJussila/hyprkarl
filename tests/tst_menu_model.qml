import QtQuick
import QtTest
import "../config/quickshell/features/menu/MenuModel.js" as MenuModel

TestCase {
  name: "MenuModel"

  readonly property var entries: ({
    "main.install": {
      "parent": "main",
      "order": 10,
      "label": "Install",
      "action": { "type": "menu", "menu": "install" }
    },
    "main.docker-guide": {
      "parent": "main",
      "order": 15,
      "label": "Docker Guide",
      "action": { "type": "command", "command": "show-docker-guide" }
    },
    "main.disabled": {
      "parent": "main",
      "order": 20,
      "label": "Unavailable",
      "disabled": true,
      "action": { "type": "command", "command": "false" }
    },
    "main.hidden": {
      "parent": "main",
      "order": 30,
      "label": "Hidden",
      "enabled": false,
      "action": { "type": "command", "command": "false" }
    },
    "install.docker": {
      "parent": "install",
      "order": 10,
      "label": "Docker",
      "searchText": "container service",
      "action": { "type": "command", "command": "install-docker" }
    },
    "install.disabled": {
      "parent": "install",
      "order": 20,
      "label": "Installed Tool",
      "disabled": true,
      "action": { "type": "command", "command": "false" }
    },
    "install.cycle": {
      "parent": "install",
      "order": 30,
      "label": "Main Again",
      "action": { "type": "menu", "menu": "main" }
    }
  })

  function test_plainMenuKeepsDisabledRows() {
    const rows = MenuModel.entriesFor(entries, "main", "", [], "")
    compare(rows.length, 3)
    compare(rows[0].id, "main.install")
    compare(rows[1].id, "main.docker-guide")
    compare(rows[2].id, "main.disabled")
    verify(rows[2].disabled)
  }

  function test_searchWalksDescendants() {
    const rows = MenuModel.entriesFor(entries, "main", "", [], "container")
    compare(rows.length, 1)
    compare(rows[0].id, "install.docker")
    compare(rows[0].searchDetail, "Install")
    compare(rows[0].searchDepth, 1)
  }

  function test_searchSeparatesCurrentAndDeeperMatches() {
    const rows = MenuModel.entriesFor(entries, "main", "", [], "docker")
    compare(rows.length, 2)
    compare(rows[0].id, "main.docker-guide")
    compare(rows[0].searchSection, "current")
    compare(rows[1].id, "install.docker")
    compare(rows[1].searchSection, "descendant")
  }

  function test_searchOmitsDisabledRows() {
    const rows = MenuModel.entriesFor(entries, "main", "", [], "tool")
    compare(rows.length, 0)
  }

  function test_searchIncludesLoadedCurrentProviderRows() {
    const dynamic = [{
      "id": "dynamic.one",
      "label": "External Project",
      "action": { "type": "command", "command": "open-project" }
    }]
    const rows = MenuModel.entriesFor(entries, "main", "main", dynamic, "extproj")
    compare(rows.length, 1)
    compare(rows[0].id, "dynamic.one")
  }

  function test_cyclesDoNotRepeatMenus() {
    const rows = MenuModel.entriesFor(entries, "main", "", [], "main")
    compare(rows.filter(row => row.id === "install.cycle").length, 1)
  }
}
