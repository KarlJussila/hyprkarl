import QtQuick

Text {
  required property var theme

  color: theme.text
  opacity: 0.7
  font.family: theme.fontUi
  font.pixelSize: theme.readoutFontSize
  font.capitalization: Font.AllUppercase
  font.letterSpacing: 0.8
}
