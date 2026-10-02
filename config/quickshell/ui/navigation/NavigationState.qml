pragma Singleton

import QtQuick

QtObject {
  property Item currentItem: null
  property string currentSection: ""
  property bool keyboardActive: false

  function select(item: Item, keyboard: bool, section: string): void {
    currentItem = item
    currentSection = item ? section : ""
    keyboardActive = keyboard
  }

  function useKeyboard(item: Item, reason: int, section: string): void {
    select(item, true, section)
    item?.forceActiveFocus(reason)
  }

  function usePointer(item: Item, section: string): void {
    select(item, false, section)
    item?.forceActiveFocus(Qt.MouseFocusReason)
  }

  function clear(): void {
    select(null, false, "")
  }
}
