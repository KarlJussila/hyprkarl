pragma Singleton

import QtQml
import Quickshell.Services.Polkit
import "../../config"

QtObject {
  id: root

  property string screenName: ""
  readonly property var flow: agent.flow
  readonly property bool requested: agent.isActive

  property PolkitAgent agent: PolkitAgent {

    onAuthenticationRequestStarted: {
      root.screenName = Screens.focusedName()
      console.info(`Polkit authentication requested on ${root.screenName}`)
    }

    onIsRegisteredChanged:
      console.info(`Polkit agent registered: ${isRegistered}`)
  }
}
