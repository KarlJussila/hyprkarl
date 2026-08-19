import QtQuick

Text {
  required property var theme

  color: theme.foreground
  opacity: 0.7
  font.family: theme.uiFontFamily
  font.pixelSize: theme.readoutFontSize
  font.capitalization: Font.AllUppercase
  font.letterSpacing: 0.8
}
