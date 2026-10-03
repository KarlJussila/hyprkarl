import QtQml
import Quickshell
import Quickshell.Io
import "../../config"

QtObject {
  id: root

  required property var shellConfig

  property bool requested: false
  property string screenName: ""
  property string kind: ""
  property string title: ""
  property string detail: ""
  property string glyph: ""
  property int value: -1
  property bool muted: false
  property bool showValue: false
  property bool showProgress: false
  readonly property bool media: kind === "media"

  property Timer hideTimer: Timer {
    onTriggered: root.requested = false
  }

  property IpcHandler ipc: IpcHandler {
    target: "osd"

    function volume(value: int, muted: bool): bool {
      root.showLevel("volume", "Volume", "", value, muted)
      return true
    }

    function output(value: int, muted: bool, description: string): bool {
      root.showLevel("output", "Audio Output", description, value, muted)
      return true
    }

    function microphone(muted: bool): bool {
      root.kind = "microphone"
      root.title = "Microphone"
      root.detail = muted ? "Muted" : "Active"
      root.glyph = muted ? "󰍭" : "󰍬"
      root.value = -1
      root.muted = false
      root.showValue = false
      root.showProgress = false
      root.present()
      return true
    }

    function display(value: int): bool {
      root.showLevel("display", "Display Brightness", "", value, false)
      return true
    }

    function keyboard(value: int): bool {
      root.showLevel("keyboard", "Keyboard Brightness", "", value, false)
      return true
    }

    function media(action: string, value: int, title: string, artist: string): bool {
      root.showMedia(action, value, title, artist)
      return true
    }
  }

  function clampLevel(level: int): int {
    return Math.max(0, Math.min(100, level))
  }

  function present(): void {
    screenName = Screens.focusedName()
    requested = screenName.length > 0
    hideTimer.interval = media ? shellConfig.osd.mediaTimeout : shellConfig.osd.timeout
    hideTimer.restart()
  }

  function showLevel(type: string, heading: string, description: string,
      level: int, muted: bool): void {
    const resolved = muted ? 0 : clampLevel(level)
    kind = type
    title = heading
    detail = description
    glyph = type === "display" ? "󰃠" : type === "keyboard" ? "󰌌" : ""
    value = resolved
    root.muted = muted
    showValue = true
    showProgress = true
    present()
  }

  function showMedia(action: string, progress: int, track: string,
      artist: string): void {
    kind = "media"
    title = track
    detail = artist
    glyph = action === "next"
      ? "󰒭"
      : action === "previous"
        ? "󰒮"
        : action === "playing"
          ? "󰐊"
          : "󰏤"
    value = progress < 0 ? -1 : clampLevel(progress)
    root.muted = false
    showValue = false
    showProgress = value >= 0
    present()
  }
}
