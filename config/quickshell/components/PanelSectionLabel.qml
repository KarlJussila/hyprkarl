import QtQuick

Text {
  required property var theme

  color: theme.panelForeground
  opacity: 0.7
  font.family: theme.panelFont
  font.pixelSize: theme.readoutFontSize
  font.capitalization: Font.AllUppercase
  font.letterSpacing: 0.8
}
