pragma Singleton
pragma ComponentBehavior: Bound

import QtQml
import QtQml.Models

QtObject {
  id: root

  property var definitions: []
  property string definitionSignature: "[]"
  property var results: ({})
  readonly property var missingResult: ({
    "ready": false,
    "visible": false,
    "text": "",
    "icon": "",
    "tooltip": "",
    "state": "normal"
  })

  function resultFor(id): var {
    return results[id] ?? missingResult
  }

  function configure(nextDefinitions): void {
    const signature = JSON.stringify(nextDefinitions)
    if (signature === definitionSignature) return

    definitionSignature = signature
    results = ({})
    definitions = nextDefinitions
  }

  function publish(id, result): void {
    const next = Object.assign({}, results)
    next[id] = result
    results = next
  }

  property Instantiator providers: Instantiator {
    model: root.definitions

    delegate: CommandProvider {
      required property var modelData
      config: modelData
      onResultChanged: root.publish(config.id, result)
    }
  }
}
